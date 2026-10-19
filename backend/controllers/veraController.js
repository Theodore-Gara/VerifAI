const pool = require('../db/pool');
const { positiveIntegerParam, clampInt } = require('../middleware/validate');
const { getVeraReply, streamVeraReply, extractMemories } = require('../services/nvidiaAssistant');
const { buildUserContext, describeContext, buildTips, buildAppKnowledge, buildAttemptAnswers, buildLeaderboardContext, buildTokenContext, buildWellnessContext } = require('../services/veraContext');
const { webSearch } = require('../services/tavily');
const { MEMORY_KINDS, veraSystem, wellnessSection } = require('../services/llm/prompts');
const { assembleContext, shouldCompact, compactSession } = require('../services/chatCompaction');
const { handleAiError } = require('../middleware/aiError');
const { openStream, sendEvent, endStream } = require('../middleware/sse');

const MAX_MESSAGE_LENGTH = 2000;
const CONTEXTS = new Set(['assistant', 'coach', 'lab', 'verification', 'general']);

// The model's context window for the chat model, and the fraction at which we
// fold older turns into the running summary. Overridable for other models.
const CHAT_CONTEXT_TOKENS = Number(process.env.CHAT_CONTEXT_TOKENS) || 262144;
const COMPACT_AT = 0.9;
const REPLY_RESERVE_TOKENS = 2000; // room for the reply + safety

// Guard so a session is never compacted twice at once.
const compactionInFlight = new Set();

async function requireUser(res, req) {
  const result = await pool.query(
    `SELECT u.id, u.industry_track_id, u.display_name, u.created_at,
            t.name AS track_name
     FROM users u
     LEFT JOIN industry_tracks t ON t.id = u.industry_track_id
     WHERE u.firebase_uid = $1`,
    [req.firebaseUser.uid],
  );
  if (!result.rows.length) {
    res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    return null;
  }
  return result.rows[0];
}

// Vera's conversation is rebuilt server-side from the stored session history,
// so only the newest message matters: it must be the learner's next question.
// Earlier client entries (which may include long assistant replies) are ignored.
function validateLatestUserTurn(value) {
  if (!Array.isArray(value) || value.length === 0) {
    const error = new Error('messages must contain at least one message.');
    error.status = 400;
    throw error;
  }
  const newest = value[value.length - 1];
  if (!newest || newest.role !== 'user') {
    const error = new Error('The latest message must be from the user.');
    error.status = 400;
    throw error;
  }
  const content = typeof newest.content === 'string' ? newest.content.trim() : '';
  if (!content || content.length > MAX_MESSAGE_LENGTH) {
    const error = new Error(`Your message must be 1 to ${MAX_MESSAGE_LENGTH} characters.`);
    error.status = 400;
    throw error;
  }
  return { role: 'user', content };
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
  const [appKnowledge, attemptAnswers, leaderboard, tokens, wellness] = await Promise.all([
    buildAppKnowledge(pool, user.id, user.industry_track_id),
    buildAttemptAnswers(pool, user.id),
    buildLeaderboardContext(pool, user.id, user.industry_track_id),
    buildTokenContext(pool, user.id),
    buildWellnessContext(pool, user.id),
  ]);
  return {
    context,
    contextText: describeContext(context),
    memories: memResult.rows.map((m) => `${m.kind}: ${m.content}`),
    appKnowledge,
    attemptAnswers,
    leaderboard,
    tokens,
    wellness,
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

    const lastUser = validateLatestUserTurn(req.body.messages);
    if (!process.env.NVIDIA_API_KEY) {
      return res.status(503).json({ error: 'Vera is not configured.', request_id: req.requestId });
    }

    const contextName = CONTEXTS.has(req.body.context) ? req.body.context : 'assistant';

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

    // Persist the newest user turn; the rest of the conversation lives in the DB.
    await pool.query(
      `INSERT INTO vera_messages (session_id, user_id, role, content) VALUES ($1, $2, 'user', $3)`,
      [sessionId, user.id, lastUser.content],
    );

    const { contextText, memories, appKnowledge, attemptAnswers, leaderboard, tokens, wellness } = await loadVeraInputs(user);

    // The learner can ask Vera to verify their input: search the web on request.
    const webResults = req.body.web_search === true ? await webSearch(lastUser.content, { maxResults: 5 }) : [];
    const sources = webResults.map((r) => ({ title: r.title, url: r.url }));

    const system = veraSystem({
      userName: user.display_name,
      trackName: user.track_name,
      accountCreatedAt: user.created_at,
      contextText,
      memories,
      contextName,
      appKnowledge,
      attemptAnswers,
      webResults,
      leaderboard,
      tokens,
      wellness,
    });

    // Rebuild the context from stored history: the running summary covers the
    // older turns; everything after the cutoff is sent verbatim.
    const sessionRow = await pool.query(
      `SELECT summary, summary_upto_message_id FROM vera_sessions WHERE id = $1`,
      [sessionId],
    );
    const summary = sessionRow.rows[0]?.summary || '';
    const cutoff = sessionRow.rows[0]?.summary_upto_message_id || 0;
    const historyRows = await pool.query(
      `SELECT id, role, content FROM vera_messages
        WHERE session_id = $1 AND id > $2 ORDER BY id`,
      [sessionId, cutoff],
    );
    const recent = historyRows.rows;

    const context = assembleContext({
      system,
      summary,
      recent,
      budget: CHAT_CONTEXT_TOKENS,
      reserve: REPLY_RESERVE_TOKENS,
    });

    // Insert the live, authoritative snapshot as the message immediately before
    // the learner's latest turn. This is the most recent instruction the model
    // sees, so a progress report uses current figures instead of echoing stale
    // numbers from earlier turns.
    if (context.length) {
      const wellnessText = wellness ? `\n\n${wellnessSection(wellness)}` : '';
      context.splice(context.length - 1, 0, {
        role: 'system',
        content: `CURRENT LEARNER DATA (live, fetched for this message and authoritative). If the learner asks about their progress or stats (XP, level, streak, tokens, readiness, tier, skills, leaderboard) or their recent mood, quote these EXACT figures and ignore any numbers stated earlier in the conversation:\n${contextText || 'No activity recorded yet.'}${wellnessText}`,
      });
    }

    const needsCompaction = shouldCompact({ system, summary, recent, budget: CHAT_CONTEXT_TOKENS, threshold: COMPACT_AT });

    // Compact in the background once the session nears the context window; the
    // learner never waits for it and never sees it happen.
    const scheduleCompaction = () => {
      if (!needsCompaction || compactionInFlight.has(sessionId)) return;
      compactionInFlight.add(sessionId);
      compactSession(pool, sessionId)
        .catch(() => {})
        .finally(() => compactionInFlight.delete(sessionId));
    };

    const wantsStream = req.query.stream === '1' || req.body.stream === true;

    if (!wantsStream) {
      const reply = await getVeraReply({ messages: context });
      await persistAssistantTurn(user, sessionId, lastUser.content, reply, contextText);
      scheduleCompaction();
      return res.status(200).json({ session_id: sessionId, reply, sources, web_searched: webResults.length > 0, request_id: req.requestId });
    }

    openStream(res);
    sendEvent(res, { session_id: sessionId });
    let full = '';
    try {
      for await (const chunk of streamVeraReply({ messages: context })) {
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
    scheduleCompaction();
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
