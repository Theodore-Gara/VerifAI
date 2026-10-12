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
              COALESCE((SELECT COUNT(DISTINCT ta.task_id)::int FROM task_attempts ta
                        WHERE ta.user_id = u.id AND ta.practice = FALSE), 0) AS completed_tasks
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

// GET /api/progress/me/activity
//
// Daily activity history for the requesting user, plus current streak info.
// Optional ?days=<1..90> (default 30) window. One row per day that has at
// least one attempt (practice attempts included, but they earn no XP).
const DEFAULT_DAYS = 30;
const MAX_DAYS = 90;
const ACTIVITY_TIMEZONE = process.env.STREAK_TIMEZONE || 'Africa/Johannesburg';

function parseDays(raw) {
  const parsed = Number.parseInt(raw, 10);
  if (!Number.isInteger(parsed)) return DEFAULT_DAYS;
  return Math.min(MAX_DAYS, Math.max(1, parsed));
}

async function getActivityHistory(req, res, next) {
  try {
    const days = parseDays(req.query.days);

    const me = await pool.query(
      `SELECT u.id AS user_id,
              COALESCE(p.streak, 0)::int AS streak,
              p.last_activity_date
       FROM users u
       LEFT JOIN user_progress p ON p.user_id = u.id
       WHERE u.firebase_uid = $1`,
      [req.firebaseUser.uid]
    );

    if (!me.rows.length) {
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }

    const activity = await pool.query(
      `SELECT to_char((ta.submitted_at::timestamptz AT TIME ZONE $3)::date, 'YYYY-MM-DD') AS activity_date,
              COUNT(*)::int AS attempts,
              COALESCE(SUM(ta.xp_earned), 0)::int AS xp_earned,
              COUNT(*) FILTER (WHERE ta.passed)::int AS passed
       FROM task_attempts ta
       WHERE ta.user_id = $1
         AND (ta.submitted_at::timestamptz AT TIME ZONE $3)::date >=
             (NOW() AT TIME ZONE $3)::date - ($2::int - 1)
       GROUP BY (ta.submitted_at::timestamptz AT TIME ZONE $3)::date
       ORDER BY activity_date ASC`,
      [me.rows[0].user_id, days, ACTIVITY_TIMEZONE]
    );

    return res.status(200).json({
      days,
      streak: {
        current: me.rows[0].streak,
        last_activity_date: me.rows[0].last_activity_date,
      },
      activity: activity.rows,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getProgress, getActivityHistory };
