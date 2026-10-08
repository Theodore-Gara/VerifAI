const pool = require('../db/pool');
const { positiveIntegerParam } = require('../middleware/validate');
const { refreshReadiness } = require('./tasksController');

async function getCurrentUser(firebaseUid) {
  const result = await pool.query(
    `SELECT id, industry_track_id FROM users WHERE firebase_uid = $1`,
    [firebaseUid]
  );
  return result.rows[0] || null;
}

function requireTrack(user) {
  if (!user) return { error: { status: 404, message: 'User not found. Call /api/auth/sync first.' } };
  if (!user.industry_track_id) {
    return { error: { status: 400, message: 'Select an industry track before requesting interview questions.' } };
  }
  return {};
}

// ---------------------------------------------------------------------------
// GET /api/interview/questions
// ---------------------------------------------------------------------------
async function getQuestions(req, res, next) {
  try {
    const user = await getCurrentUser(req.firebaseUser.uid);
    const { error } = requireTrack(user);
    if (error) return res.status(error.status).json({ error: error.message, request_id: req.requestId });

    const result = await pool.query(
      `SELECT q.id, q.track_id, q.question, q.sample_answer, q.what_employers_test, q.sort_order,
              EXISTS (
                SELECT 1 FROM interview_practice ip
                WHERE ip.question_id = q.id AND ip.user_id = $1
              ) AS practiced
       FROM interview_questions q
       WHERE q.track_id = $2
       ORDER BY q.sort_order, q.id`,
      [user.id, user.industry_track_id]
    );

    return res.status(200).json({ questions: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// POST /api/interview/questions/:id/practice
// Idempotent: recording the same question twice changes nothing but the counts.
// ---------------------------------------------------------------------------
async function markPracticed(req, res, next) {
  try {
    const questionId = positiveIntegerParam(req.params.id, 'question id');
    const user = await getCurrentUser(req.firebaseUser.uid);
    const { error } = requireTrack(user);
    if (error) return res.status(error.status).json({ error: error.message, request_id: req.requestId });

    const question = await pool.query(`SELECT id, track_id FROM interview_questions WHERE id = $1`, [questionId]);
    if (!question.rows.length) {
      return res.status(404).json({ error: 'Question not found.', request_id: req.requestId });
    }
    if (Number(question.rows[0].track_id) !== Number(user.industry_track_id)) {
      return res.status(403).json({ error: 'Question is not available for the selected industry track.', request_id: req.requestId });
    }

    await pool.query(
      `INSERT INTO interview_practice (user_id, question_id) VALUES ($1, $2)
       ON CONFLICT DO NOTHING`,
      [user.id, questionId]
    );

    // Coverage is part of the weighted readiness score, so recompute it here.
    await refreshReadiness(pool, user.id, user.industry_track_id);

    const counts = await pool.query(
      `SELECT COUNT(*)::int AS total,
              COUNT(*) FILTER (
                WHERE EXISTS (
                  SELECT 1 FROM interview_practice ip
                  WHERE ip.question_id = q.id AND ip.user_id = $1
                )
              )::int AS practised
       FROM interview_questions q
       WHERE q.track_id = $2`,
      [user.id, user.industry_track_id]
    );

    return res.status(200).json({
      question_id: questionId,
      practiced: true,
      practised_count: counts.rows[0].practised,
      total: counts.rows[0].total,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getQuestions, markPracticed };
