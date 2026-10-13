const pool = require('../db/pool');
const { positiveIntegerParam, clampInt } = require('../middleware/validate');
const { getVeraReply, streamVeraReply, extractMemories } = require('../services/nvidiaAssistant');
const { buildUserContext, describeContext, buildTips, buildAppKnowledge, buildAttemptAnswers } = require('../services/veraContext');
const { MEMORY_KINDS } = require('../services/llm/prompts');
const { handleAiError } = require('../middleware/aiError');
const { openStream, sendEvent, endStream } = require('../middleware/sse');

const MAX_MESSAGES = 20;
const MAX_MESSAGE_LENGTH = 2000;
const CONTEXTS = new Set(['assistant', 'coach', 'lab', 'verification', 'general']);

async function requireUser(res, req) {
  const result = await pool.query(
    `SELECT id, industry_track_id, display_name FROM users WHERE firebase_uid = $1`,
    [req.firebaseUser.uid],
  );
  if (!result.rows.length) {
    res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    return null;
  }
  return result.rows[0];
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
    const content = typeof message.content === 'string' ? message.content.trim() : '';
    if (!content || content.length > MAX_MESSAGE_LENGTH) {
      const error = new Error(`Each message must be 1 to ${MAX_MESSAGE_LENGTH} characters.`);
      error.status = 400;
      throw error;
    }
    return { role: message.role, content };
  });
  if (messages.at(-1).role !== 'user') {
    const error = new Error('The latest message must be from the user.');
    error.status = 400;
    throw error;
  }
  return messages;
}

async function storeMemories(executor, userId, items) {
  for (const item of items) {
    await executor.query(
      `INSERT INTO vera_memories (user_id, kind, content, source)
       VALUES ($1, $2, $3, 'chat')
       ON CONFLICT (user_id, kind, content) DO UPDATE SET updated_at = now()`,
      [userId, item.kind, item.content],
    );
  }
}

// Loads the profile, memories, app knowledge and attempt answers Vera needs.
async function loadVeraInputs(user) {
  const context = await buildUserContext(pool, user.id);
  const memResult = await pool.query(
    `SELECT kind, content FROM vera_memories WHERE user_id = $1 ORDER BY updated_at DESC LIMIT 15`,
    [user.id],
  );
  const [appKnowledge, attemptAnswers] = await Promise.all([
    buildAppKnowledge(pool, user.id, user.industry_track_id),
    buildAttemptAnswers(pool, user.id),
  ]);
  return {
    context,
    contextText: describeContext(context),
    memories: memResult.rows.map((m) => `${m.kind}: ${m.content}`),
    appKnowledge,
    attemptAnswers,
  };
}

async function persistAssistantTurn(user, sessionId, userMessage, reply, contextText) {
  await pool.query(
    `INSERT INTO vera_messages (session_id, user_id, role, content) VALUES ($1, $2, 'assistant', $3)`,
    [sessionId, user.id, reply],
  );
  await pool.query(
    `UPDATE vera_sessions SET last_active_at = now(), message_count = message_count + 2 WHERE id = $1`,
    [sessionId],
  );
  const extracted = await extractMemories({ userName: user.display_name, contextText, userMessage, assistantReply: reply });
  if (extracted.length) await storeMemories(pool, user.id, extracted);
}

// POST /api/vera/chat  { session_id?, messages, context? }
async function chat(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const messages = validateMessages(req.body.messages);
    if (!process.env.NVIDIA_API_KEY) {
      return res.status(503).json({ error: 'Vera is not configured.', request_id: req.requestId });
    }

    const contextName = CONTEXTS.has(req.body.context) ? req.body.context : 'assistant';
    const lastUser = messages[messages.length - 1];

    let sessionId = null;
    if (req.body.session_id !== undefined && req.body.session_id !== null) {
      const id = positiveIntegerParam(req.body.session_id, 'session_id');
      const existing = await pool.query(`SELECT id FROM vera_sessions WHERE id = $1 AND user_id = $2`, [id, user.id]);
      if (!existing.rows.length) {
        return res.status(404).json({ error: 'Session not found.', request_id: req.requestId });
      }
      sessionId = id;
    } else {
      const created = await pool.query(
        `INSERT INTO vera_sessions (user_id, context, title) VALUES ($1, $2, $3) RETURNING id`,
        [user.id, contextName, lastUser.content.slice(0, 80)],
      );
      sessionId = created.rows[0].id;
    }

    // Only the newest user turn is persisted; the client sends the running history.
    await pool.query(
      `INSERT INTO vera_messages (session_id, user_id, role, content) VALUES ($1, $2, 'user', $3)`,
      [sessionId, user.id, lastUser.content],
    );

    const { contextText, memories, appKnowledge, attemptAnswers } = await loadVeraInputs(user);
    const wantsStream = req.query.stream === '1' || req.body.stream === true;

    if (!wantsStream) {
      const reply = await getVeraReply({
        userName: user.display_name,
        contextText,
        memories,
        contextName,
        appKnowledge,
        attemptAnswers,
        messages,
      });
      await persistAssistantTurn(user, sessionId, lastUser.content, reply, contextText);
      return res.status(200).json({ session_id: sessionId, reply, request_id: req.requestId });
    }

    openStream(res);
    let full = '';
    try {
      for await (const chunk of streamVeraReply({
        userName: user.display_name,
        contextText,
        memories,
        contextName,
        appKnowledge,
        attemptAnswers,
        messages,
      })) {
        if (chunk.delta) {
          full += chunk.delta;
          sendEvent(res, { delta: chunk.delta });
        }
      }
      endStream(res);
    } catch (error) {
      sendEvent(res, { error: error.message });
      endStream(res);
    }
    if (full) await persistAssistantTurn(user, sessionId, lastUser.content, full, contextText);
    return undefined;
  } catch (err) {
    return handleAiError(err, req, res, next);
  }
}

// GET /api/vera/sessions
async function listSessions(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;
    const result = await pool.query(
      `SELECT id, context, title, started_at, last_active_at, message_count
       FROM vera_sessions WHERE user_id = $1 ORDER BY last_active_at DESC LIMIT 30`,
      [user.id],
    );
    return res.status(200).json({ sessions: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/vera/sessions/:id
async function getSession(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;
    const id = positiveIntegerParam(req.params.id, 'session id');
    const session = await pool.query(
      `SELECT id, context, title, started_at, last_active_at, message_count FROM vera_sessions WHERE id = $1 AND user_id = $2`,
      [id, user.id],
    );
    if (!session.rows.length) {
      return res.status(404).json({ error: 'Session not found.', request_id: req.requestId });
    }
    const messages = await pool.query(
      `SELECT id, role, content, created_at FROM vera_messages WHERE session_id = $1 ORDER BY created_at, id`,
      [id],
    );
    return res.status(200).json({ session: session.rows[0], messages: messages.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/vera/memory
async function listMemory(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;
    const result = await pool.query(
      `SELECT id, kind, content, source, created_at, updated_at FROM vera_memories WHERE user_id = $1 ORDER BY updated_at DESC LIMIT 100`,
      [user.id],
    );
    return res.status(200).json({ memories: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// POST /api/vera/memory  { kind, content }
async function addMemory(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;
    const kind = String(req.body.kind || '').toLowerCase().trim();
    if (!MEMORY_KINDS.includes(kind)) {
      return res.status(400).json({ error: `kind must be one of ${MEMORY_KINDS.join(', ')}.`, request_id: req.requestId });
    }
    const content = typeof req.body.content === 'string' ? req.body.content.trim() : '';
    if (!content || content.length > 300) {
      return res.status(400).json({ error: 'content must be 1 to 300 characters.', request_id: req.requestId });
    }
    const result = await pool.query(
      `INSERT INTO vera_memories (user_id, kind, content, source)
       VALUES ($1, $2, $3, 'user')
       ON CONFLICT (user_id, kind, content) DO UPDATE SET updated_at = now()
       RETURNING id, kind, content, source, created_at, updated_at`,
      [user.id, kind, content],
    );
    return res.status(201).json({ memory: result.rows[0], request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// DELETE /api/vera/memory/:id
async function deleteMemory(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;
    const id = positiveIntegerParam(req.params.id, 'memory id');
    const result = await pool.query(`DELETE FROM vera_memories WHERE id = $1 AND user_id = $2 RETURNING id`, [id, user.id]);
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Memory not found.', request_id: req.requestId });
    }
    return res.status(200).json({ deleted: true, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/vera/tips — deterministic, personalised coaching tips.
async function tips(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;
    const context = await buildUserContext(pool, user.id);
    return res.status(200).json({
      tips: buildTips(context),
      summary: describeContext(context),
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { chat, listSessions, getSession, listMemory, addMemory, deleteMemory, tips };
