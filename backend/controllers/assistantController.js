const pool = require('../db/pool');
const { positiveIntegerParam, requiredString } = require('../middleware/validate');
const {
  getAssistantReply,
  streamAssistantReply,
  getGeneralReply,
  streamGeneralReply,
} = require('../services/nvidiaAssistant');
const { handleAiError } = require('../middleware/aiError');
const { openStream, sendEvent, endStream } = require('../middleware/sse');

const MAX_MESSAGES = 8;
const MAX_MESSAGE_LENGTH = 1200;

// Get or create a session for user+task, return session_id and existing messages.
// One upsert rather than SELECT-then-INSERT: two simultaneous first messages
// (double tap, client retry) used to race on UNIQUE (user_id, task_id) and
// surface as a 500.
async function getOrCreateSession(userId, taskId) {
  const session = await pool.query(
    `INSERT INTO assistant_sessions (user_id, task_id)
     VALUES ($1, $2)
     ON CONFLICT (user_id, task_id) DO UPDATE SET last_active_at = now()
     RETURNING id`,
    [userId, taskId],
  );
  const sessionId = session.rows[0].id;
  const messages = await pool.query(
    `SELECT role, content FROM assistant_messages WHERE session_id = $1 ORDER BY created_at`,
    [sessionId],
  );
  return { sessionId, history: messages.rows };
}

// Persist a user+assistant turn
async function persistTurn(sessionId, userId, userContent, assistantContent) {
  await pool.query(
    `INSERT INTO assistant_messages (session_id, user_id, role, content) VALUES ($1, $2, 'user', $3)`,
    [sessionId, userId, userContent],
  );
  await pool.query(
    `INSERT INTO assistant_messages (session_id, user_id, role, content) VALUES ($1, $2, 'assistant', $3)`,
    [sessionId, userId, assistantContent],
  );
  await pool.query(
    `UPDATE assistant_sessions SET last_active_at = now(), message_count = message_count + 2 WHERE id = $1`,
    [sessionId],
  );
}

// POST /api/assistant/chat
// task_id is required for task-scoped assistant with history
async function sendMessage(req, res, next) {
  try {
    const messages = validateMessages(req.body.messages);

    const hasTaskId = req.body.task_id !== undefined && req.body.task_id !== null;
    const taskId = hasTaskId ? positiveIntegerParam(req.body.task_id, 'task_id') : null;

    if (!process.env.NVIDIA_API_KEY) {
      return res.status(503).json({ error: 'Learning Assistant is not configured.', request_id: req.requestId });
    }

    const userResult = await pool.query(
      `SELECT u.id, u.industry_track_id, t.name AS track_name
       FROM users u
       LEFT JOIN industry_tracks t ON t.id = u.industry_track_id
       WHERE u.firebase_uid = $1`,
      [req.firebaseUser.uid],
    );
    if (!userResult.rows.length) {
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }
    const user = userResult.rows[0];

    let task = null;
    let sessionId = null;
    let history = [];

    if (hasTaskId) {
      if (!user.industry_track_id) {
        return res.status(400).json({ error: 'Select an industry track before using the assistant.', request_id: req.requestId });
      }

      const taskResult = await pool.query(
        `SELECT t.feature, it.name AS track_name,
                COALESCE(v.title, j.title, r.title) AS title,
                COALESCE(v.scenario, j.scenario, r.scenario) AS scenario
         FROM tasks t
         JOIN industry_tracks it ON it.id = t.track_id
         LEFT JOIN verification_tasks v ON v.task_id = t.id
         LEFT JOIN judgement_tasks j ON j.task_id = t.id
         LEFT JOIN risk_governance_tasks r ON r.task_id = t.id
         WHERE t.id = $1 AND t.track_id = $2`,
        [taskId, user.industry_track_id],
      );
      if (!taskResult.rows.length) {
        return res.status(404).json({ error: 'Task not found for your selected track.', request_id: req.requestId });
      }

      task = { ...taskResult.rows[0], trackName: taskResult.rows[0].track_name };
      if (!task.title || !task.scenario) {
        return res.status(422).json({ error: 'Assistant context is not available for this task yet.', request_id: req.requestId });
      }

      // Get or create session and load history
      const session = await getOrCreateSession(user.id, taskId);
      sessionId = session.sessionId;
      history = session.history.map((m) => ({ role: m.role, content: m.content }));
    }

    const wantsStream = req.query.stream === '1' || req.body.stream === true;

    // Prepend history to the incoming messages (client sends latest turn(s))
    const fullMessages = [...history, ...messages];

    if (!wantsStream) {
      const reply = task
        ? await getAssistantReply({ task, messages: fullMessages })
        : await getGeneralReply({ trackName: user.track_name, messages: fullMessages });
      if (sessionId) await persistTurn(sessionId, user.id, messages[messages.length - 1].content, reply);
      return res.status(200).json({ reply, session_id: sessionId, request_id: req.requestId });
    }

    const signal = openStream(res);
    let fullReply = '';
    try {
      const stream = task
        ? streamAssistantReply({ task, messages: fullMessages, signal })
        : streamGeneralReply({ trackName: user.track_name, messages: fullMessages, signal });
      for await (const chunk of stream) {
        if (chunk.delta) {
          fullReply += chunk.delta;
          sendEvent(res, { delta: chunk.delta });
        }
      }
      endStream(res);
    } catch (error) {
      if (!signal.aborted) {
        sendEvent(res, { error: error.message });
        endStream(res);
      }
    }
    if (sessionId && fullReply) await persistTurn(sessionId, user.id, messages[messages.length - 1].content, fullReply);
    return undefined;
  } catch (err) {
    return handleAiError(err, req, res, next);
  }
}

// GET /api/assistant/sessions/:taskId — load chat history for a task
async function getSession(req, res, next) {
  try {
    const userResult = await pool.query(
      `SELECT id FROM users WHERE firebase_uid = $1`,
      [req.firebaseUser.uid],
    );
    if (!userResult.rows.length) {
      return res.status(404).json({ error: 'User not found.', request_id: req.requestId });
    }
    const userId = userResult.rows[0].id;
    const taskId = positiveIntegerParam(req.params.taskId, 'task_id');

    const session = await pool.query(
      `SELECT id, started_at, last_active_at, message_count FROM assistant_sessions WHERE user_id = $1 AND task_id = $2`,
      [userId, taskId],
    );
    if (!session.rows.length) {
      return res.status(200).json({ session: null, messages: [], request_id: req.requestId });
    }
    const sessionId = session.rows[0].id;
    const messages = await pool.query(
      `SELECT id, role, content, created_at FROM assistant_messages WHERE session_id = $1 ORDER BY created_at`,
      [sessionId],
    );
    return res.status(200).json({ session: session.rows[0], messages: messages.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

function validateMessages(value) {
  if (!Array.isArray(value) || value.length === 0 || value.length > MAX_MESSAGES) {
    const error = new Error(`messages must contain 1 to ${MAX_MESSAGES} messages.`);
    error.status = 400;
    throw error;
  }

  const messages = value.map((message) => {
    if (!message || !['user', 'assistant'].includes(message.role)) {
      const error = new Error('Message role must be user or assistant.');
      error.status = 400;
      throw error;
    }
    return {
      role: message.role,
      content: requiredString(message.content, 'message', MAX_MESSAGE_LENGTH),
    };
  });

  if (messages.at(-1).role !== 'user') {
    const error = new Error('The latest message must be from the user.');
    error.status = 400;
    throw error;
  }
  return messages;
}

module.exports = { sendMessage, getSession, validateMessages, MAX_MESSAGES, MAX_MESSAGE_LENGTH };
