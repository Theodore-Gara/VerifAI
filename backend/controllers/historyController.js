const pool = require('../db/pool');
const { clampInt, positiveIntegerParam } = require('../middleware/validate');

const TYPES = new Set(['task', 'activity', 'capstone']);

// GET /api/history?limit=&offset=&type=&q=
// One newest-first timeline across scored task attempts, AI Lab practice
// activities and capstone attempts.
//
// Pagination is offset-based (rather than a keyset on created_at) because the
// union has no single id sequence and the timeline is short; `has_more` is
// derived by fetching one row more than asked for, so no COUNT over the union is
// needed.
async function getHistory(req, res, next) {
  try {
    const user = req.user;

    const limit = clampInt(req.query.limit, 30, 1, 100);
    const offset = clampInt(req.query.offset, 0, 0, 100000);
    const type = req.query.type == null ? null : String(req.query.type).toLowerCase();
    if (type && !TYPES.has(type)) {
      return res.status(400).json({ error: 'type must be one of task, activity, capstone.', request_id: req.requestId });
    }
    const q = typeof req.query.q === 'string' && req.query.q.trim()
      ? req.query.q.trim().slice(0, 120)
      : null;

    const result = await pool.query(
      `SELECT type, id, title, feature, score, passed, xp_earned, created_at
       FROM user_activity
       WHERE user_id = $1
         AND NOT (type = 'task' AND practice)
         AND ($2::text IS NULL OR type = $2)
         AND ($3::text IS NULL OR title ILIKE '%' || $3 || '%')
       ORDER BY created_at DESC, id DESC
       LIMIT $4 OFFSET $5`,
      [user.id, type, q, limit + 1, offset],
    );

    const rows = result.rows.slice(0, limit);
    return res.status(200).json({
      entries: rows,
      has_more: result.rows.length > limit,
      limit,
      offset,
      type,
      q,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// GET /api/history/attempts/:id — one scored attempt, including the feedback
// text. Exists so the feedback screen can be reached by id (a deep link or an
// app restart) instead of only through the result object it was pushed with.
async function getAttempt(req, res, next) {
  try {
    const user = req.user;

    const attemptId = positiveIntegerParam(req.params.id, 'attempt id');
    const result = await pool.query(
      `SELECT ta.id, ta.task_id, ta.task_title AS title, t.feature, t.difficulty,
              ta.score, ta.passed, ta.practice, ta.feedback, ta.xp_earned,
              ta.answer, ta.rationale, ta.selected_lines, ta.submitted_at
       FROM task_attempts ta
       JOIN tasks t ON t.id = ta.task_id
       WHERE ta.id = $1 AND ta.user_id = $2`,
      [attemptId, user.id],
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Attempt not found.', request_id: req.requestId });
    }
    return res.status(200).json({ attempt: result.rows[0], request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getHistory, getAttempt };
