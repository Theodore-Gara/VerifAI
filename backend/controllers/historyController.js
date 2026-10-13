const pool = require('../db/pool');
const { clampInt } = require('../middleware/validate');
const { findUserByFirebaseUid } = require('../db/users');

// GET /api/history
// One newest-first timeline across scored task attempts, AI Lab practice
// activities and capstone attempts.
async function getHistory(req, res, next) {
  try {
    const user = await findUserByFirebaseUid(pool, req.firebaseUser.uid);
    if (!user) {
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }
    const limit = clampInt(req.query.limit, 30, 1, 100);

    const result = await pool.query(
      `SELECT type, id, title, feature, score, passed, xp_earned, created_at
       FROM (
         SELECT 'task' AS type, ta.id AS id, ta.task_title AS title, t.feature AS feature,
                ta.score AS score, ta.passed AS passed, ta.xp_earned AS xp_earned, ta.submitted_at AS created_at
         FROM task_attempts ta
         JOIN tasks t ON t.id = ta.task_id
         WHERE ta.user_id = $1 AND ta.practice = FALSE
         UNION ALL
         SELECT 'activity', aa.id, a.prompt, NULL, NULL, aa.passed, aa.xp_awarded, aa.submitted_at
         FROM lab_activity_attempts aa
         JOIN lab_activities a ON a.id = aa.activity_id
         WHERE aa.user_id = $1
         UNION ALL
         SELECT 'capstone', ca.id, c.title, NULL, ca.score, ca.passed,
                CASE WHEN ca.passed THEN c.xp_reward ELSE 0 END, ca.submitted_at
         FROM lab_capstone_attempts ca
         JOIN lab_capstone_assessments c ON c.id = ca.assessment_id
         WHERE ca.user_id = $1 AND ca.submitted_at IS NOT NULL
       ) h
       ORDER BY created_at DESC, id DESC
       LIMIT $2`,
      [user.id, limit],
    );

    return res.status(200).json({ entries: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getHistory };
