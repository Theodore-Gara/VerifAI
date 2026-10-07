const pool = require('../db/pool');
const { positiveIntegerParam, requiredString } = require('../middleware/validate');
const { getAssistantReply } = require('../services/nvidiaAssistant');

const MAX_MESSAGES = 8;
const MAX_MESSAGE_LENGTH = 1200;

async function sendMessage(req, res, next) {
  try {
    const taskId = positiveIntegerParam(req.body.task_id, 'task_id');
    const messages = validateMessages(req.body.messages);

    if (!process.env.NVIDIA_API_KEY) {
      return res.status(503).json({ error: 'Learning Assistant is not configured.', request_id: req.requestId });
    }

    const userResult = await pool.query(
      'SELECT id, industry_track_id FROM users WHERE firebase_uid = $1',
      [req.firebaseUser.uid]
    );
    if (!userResult.rows.length) {
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }

    const user = userResult.rows[0];
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
      [taskId, user.industry_track_id]
    );
    if (!taskResult.rows.length) {
      return res.status(404).json({ error: 'Task not found for your selected track.', request_id: req.requestId });
    }

    const task = {
      ...taskResult.rows[0],
      trackName: taskResult.rows[0].track_name,
    };
    if (!task.title || !task.scenario) {
      return res.status(422).json({ error: 'Assistant context is not available for this task yet.', request_id: req.requestId });
    }

    const reply = await getAssistantReply({ task, messages });
    return res.status(200).json({ reply, request_id: req.requestId });
  } catch (err) {
    if (err.status === 400) {
      return res.status(400).json({ error: err.message, request_id: req.requestId });
    }
    if (err.status === 502 || err.status === 503 || err.status === 504) {
      return res.status(err.status).json({ error: err.message, request_id: req.requestId });
    }
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

module.exports = { sendMessage, validateMessages };
