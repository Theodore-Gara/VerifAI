const pool = require('../db/pool');

async function getProgress(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT u.id AS user_id,
              COALESCE(p.xp, 0)::int AS xp,
              COALESCE(p.level, 1)::int AS level,
              COALESCE(p.streak, 0)::int AS streak,
              p.last_activity_date,
              COALESCE(p.readiness_score, 0)::int AS readiness_score,
              COALESCE(p.tier, 'Novice') AS tier,
              COALESCE(p.tier_tasks_completed, 0)::int AS tier_tasks_completed,
              COALESCE((SELECT json_agg(json_build_object(
                  'dimension', ss.dimension,
                  'score', ss.score,
                  'attempts_count', ss.attempts_count
                ) ORDER BY ss.dimension) FROM skill_scores ss WHERE ss.user_id = u.id), '[]'::json) AS skill_scores,
              COALESCE((SELECT COUNT(*)::int FROM task_attempts ta WHERE ta.user_id = u.id), 0) AS completed_tasks
       FROM users u
       LEFT JOIN user_progress p ON p.user_id = u.id
       WHERE u.firebase_uid = $1`,
      [req.firebaseUser.uid]
    );

    if (!result.rows.length) {
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }

    return res.status(200).json({ progress: result.rows[0], request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getProgress };
