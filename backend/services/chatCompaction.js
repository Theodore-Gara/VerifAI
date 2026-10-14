// Vera session compaction. Conversations can run long; rather than let the
// context grow until the model rejects it, we keep a running summary of the
// older turns and only send the recent turns verbatim. Compaction runs in the
// background (fire-and-forget) so the learner never waits for it.
const { resolveProfile } = require('./llm/profiles');
const { chatWithFallback } = require('./llm/client');
const { compactorSystem } = require('./llm/prompts');

// Cheap estimate: ~4 characters per token. Good enough to decide when to
// compact (we never need exact tokenisation).
const CHARS_PER_TOKEN = 4;
const MESSAGE_OVERHEAD = 4;

function estimateTokens(text) {
  return Math.ceil(String(text == null ? '' : text).length / CHARS_PER_TOKEN);
}

function estimateMessagesTokens(messages) {
  return (messages || []).reduce(
    (sum, m) => sum + estimateTokens(m.content) + MESSAGE_OVERHEAD,
    0,
  );
}

// The system message, with the running summary folded in when there is one.
function systemWithSummary(system, summary) {
  return summary
    ? `${system}\n\nSummary of the earlier conversation (older turns, condensed):\n${summary}`
    : system;
}

// Assembles the model context from the system prompt, the running summary and
// the recent verbatim messages. The oldest recent messages are dropped until
// the total fits within `budget` minus `reserve` (room for the reply), so a
// request can never overflow even before a summary exists.
function assembleContext({ system, summary, recent, budget, reserve }) {
  const limit = Math.max(1, Number(budget) - Number(reserve || 0));
  const kept = [...(recent || [])];
  const build = () => [
    { role: 'system', content: systemWithSummary(system, summary) },
    ...kept.map((m) => ({ role: m.role, content: m.content })),
  ];
  let messages = build();
  while (kept.length > 0 && estimateMessagesTokens(messages) > limit) {
    kept.shift();
    messages = build();
  }
  return messages;
}

// True once the assembled context reaches `threshold` (default 90%) of budget.
function shouldCompact({ system, summary, recent, budget, threshold = 0.9 }) {
  const messages = [
    { role: 'system', content: systemWithSummary(system, summary) },
    ...(recent || []).map((m) => ({ role: m.role, content: m.content })),
  ];
  return estimateMessagesTokens(messages) >= threshold * Number(budget);
}

// Runs in the background. Folds every message after the stored cutoff, except
// the most recent `keepRecent`, into the session summary and advances the
// cutoff. Returns the new { summary, cutoff } or null when there is nothing to do.
async function compactSession(pool, sessionId, { keepRecent = 6, fetchImpl } = {}) {
  const session = await pool.query(
    `SELECT summary, summary_upto_message_id FROM vera_sessions WHERE id = $1`,
    [sessionId],
  );
  if (!session.rows.length) return null;
  const existingSummary = session.rows[0].summary || '';
  const cutoff = session.rows[0].summary_upto_message_id || 0;

  const rows = await pool.query(
    `SELECT id, role, content FROM vera_messages
      WHERE session_id = $1 AND id > $2 ORDER BY id`,
    [sessionId, cutoff],
  );
  const recent = rows.rows;
  const toSummarize = recent.slice(0, Math.max(0, recent.length - keepRecent));
  if (toSummarize.length === 0) return null;

  const transcript = [
    existingSummary ? `Summary so far:\n${existingSummary}` : '',
    'New turns to fold in:',
    ...toSummarize.map((m) => `${m.role === 'user' ? 'Learner' : 'Vera'}: ${m.content}`),
  ]
    .filter(Boolean)
    .join('\n\n');

  const { content } = await chatWithFallback(
    {
      ...resolveProfile('compactor'),
      messages: [
        { role: 'system', content: compactorSystem() },
        { role: 'user', content: transcript },
      ],
    },
    fetchImpl,
  );
  const summary = String(content || '').trim();
  if (!summary) return null;

  const newCutoff = toSummarize[toSummarize.length - 1].id;
  await pool.query(
    `UPDATE vera_sessions SET summary = $1, summary_upto_message_id = $2 WHERE id = $3`,
    [summary.slice(0, 8000), newCutoff, sessionId],
  );
  return { summary, cutoff: newCutoff };
}

module.exports = {
  estimateTokens,
  estimateMessagesTokens,
  systemWithSummary,
  assembleContext,
  shouldCompact,
  compactSession,
};
