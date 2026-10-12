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

// POST /api/assistant/chat
// task_id is optional: with it the assistant is scoped to that task; without
// it this is a general (track-aware) assistant. Pass ?stream=1 (or body.stream)
// for an SSE reply.
async function sendMessage(req, res, next) {
  try {
    const messages = validateMessages(req.body.messages);

    if (!process.env.NVIDIA_API_KEY) {
      return res.status(503).json({ error: 'Learning Assistant is not configured.', request_id: req.requestId });
    }

    const hasTaskId = req.body.task_id !== undefined && req.body.task_id !== null;

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
    if (hasTaskId) {
      const taskId = positiveIntegerParam(req.body.task_id, 'task_id');
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
    }

    const wantsStream = req.query.stream === '1' || req.body.stream === true;

    if (!wantsStream) {
      const reply = task
        ? await getAssistantReply({ task, messages })
        : await getGeneralReply({ trackName: user.track_name, messages });
      return res.status(200).json({ reply, request_id: req.requestId });
    }

    openStream(res);
    try {
      const stream = task
        ? streamAssistantReply({ task, messages })
        : streamGeneralReply({ trackName: user.track_name, messages });
      for await (const chunk of stream) {
        if (chunk.delta) sendEvent(res, { delta: chunk.delta });
      }
      endStream(res);
    } catch (error) {
      sendEvent(res, { error: error.message });
      endStream(res);
    }
    return undefined;
  } catch (err) {
    return handleAiError(err, req, res, next);
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

module.exports = { sendMessage, validateMessages, MAX_MESSAGES, MAX_MESSAGE_LENGTH };
