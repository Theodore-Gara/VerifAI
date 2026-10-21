const pool = require('../db/pool');
const { positiveIntegerParam } = require('../middleware/validate');

// GET /api/industry-practice/cases
// Informational case studies for the user's track (plus cross-industry ones),
// each with a `read` flag.
async function listCases(req, res, next) {
  try {
    const user = req.user;

    const result = await pool.query(
      `SELECT c.id, c.title, c.source_title, c.source_url, c.sort_order,
              EXISTS (SELECT 1 FROM industry_case_reads r WHERE r.case_id = c.id AND r.user_id = $1) AS read
       FROM industry_cases c
       WHERE c.active = TRUE AND (c.track_id IS NULL OR c.track_id = $2)
       ORDER BY c.sort_order, c.id`,
      [user.id, user.industry_track_id],
    );

    return res.status(200).json({ cases: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/industry-practice/cases/:id — full case (scenario, cause, solution);
// reading it marks it as read.
async function getCase(req, res, next) {
  try {
    const user = req.user;

    const id = positiveIntegerParam(req.params.id, 'case id');
    const result = await pool.query(
      `SELECT id, title, scenario, cause, solution, source_title, source_url
       FROM industry_cases
       WHERE id = $1 AND active = TRUE AND (track_id IS NULL OR track_id = $2)`,
      [id, user.industry_track_id],
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Case not found for your selected track.', request_id: req.requestId });
    }

    await pool.query(
      `INSERT INTO industry_case_reads (user_id, case_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
      [user.id, id],
    );

    return res.status(200).json({ case: { ...result.rows[0], read: true }, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// POST /api/industry-practice/cases/:id/read — idempotent.
async function markRead(req, res, next) {
  try {
    const user = req.user;

    const id = positiveIntegerParam(req.params.id, 'case id');
    const exists = await pool.query(
      `SELECT id FROM industry_cases WHERE id = $1 AND active = TRUE AND (track_id IS NULL OR track_id = $2)`,
      [id, user.industry_track_id],
    );
    if (!exists.rows.length) {
      return res.status(404).json({ error: 'Case not found for your selected track.', request_id: req.requestId });
    }

    await pool.query(
      `INSERT INTO industry_case_reads (user_id, case_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
      [user.id, id],
    );
    return res.status(200).json({ read: true, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

module.exports = { listCases, getCase, markRead };
