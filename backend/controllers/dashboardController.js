// GET /api/dashboard — everything the Home screen renders, in one round trip.
//
// Home used to fan out to /users/me, /progress/me and three /tasks/next calls
// (one per difficulty), then render none of the task data. That was five
// requests and eight-plus queries for a screen with two data-dependent widgets,
// all on the cold-start path. This composes the same sources server-side and
// reuses the task selection logic rather than forking it.
const pool = require('../db/pool');
const { getNextTask } = require('./tasksController');
const { xpForLevel } = require('../services/scoringService');

// Runs the existing next-task selection without duplicating its query. The
// controller writes its answer through `res.json`, so a minimal response object
// captures the payload; this is the same swap the task importer uses.
async function nextTaskFor(req) {
  let payload = null;
  const fakeReq = {
    firebaseUser: req.firebaseUser,
    query: {},
    requestId: req.requestId,
    method: 'GET',
  };
  const fakeRes = {
    status() {
      return this;
    },
    json(body) {
      payload = body;
      return this;
    },
  };
  await getNextTask(fakeReq, fakeRes, (err) => {
    throw err;
  });
  return payload || {};
}

async function getDashboard(req, res, next) {
  try {
    const summary = await pool.query(
      `SELECT u.id, u.display_name, u.email, u.industry_track_id,
              t.name AS industry_track_name,
              COALESCE(p.xp, 0) AS xp, COALESCE(p.level, 1) AS level,
              COALESCE(p.streak, 0) AS streak, COALESCE(p.tokens, 0) AS tokens,
              COALESCE(p.readiness_score, 0) AS readiness_score,
              COALESCE(p.tier, 'Novice') AS tier,
              p.last_activity_date
       FROM users u
       LEFT JOIN industry_tracks t ON t.id = u.industry_track_id
       LEFT JOIN user_progress p ON p.user_id = u.id
       WHERE u.firebase_uid = $1`,
      [req.firebaseUser.uid],
    );

    if (!summary.rows.length) {
      return res.status(404).json({
        error: 'User not found. Call /api/auth/sync first.',
        request_id: req.requestId,
      });
    }

    const user = summary.rows[0];

    const [dimensions, counts, nextTask] = await Promise.all([
      pool.query(
        `SELECT dimension, score FROM skill_scores WHERE user_id = $1 ORDER BY dimension`,
        [user.id],
      ),
      pool.query(
        `SELECT
           COUNT(DISTINCT task_id) FILTER (WHERE passed)::int AS tasks_completed,
           COUNT(*)::int AS attempts_total,
           COUNT(*) FILTER (WHERE passed AND submitted_at >= NOW() - INTERVAL '7 days')::int AS passed_last_7_days
         FROM task_attempts
         WHERE user_id = $1 AND practice = FALSE`,
        [user.id],
      ),
      nextTaskFor(req),
    ]);

    const level = Number(user.level) || 1;
    const xp = Number(user.xp) || 0;
    const levelBase = xpForLevel(level);
    const nextLevelAt = xpForLevel(level + 1);

    return res.status(200).json({
      user: {
        id: user.id,
        display_name: user.display_name,
        email: user.email,
        industry_track_id: user.industry_track_id,
        industry_track_name: user.industry_track_name,
      },
      progress: {
        xp,
        level,
        streak: Number(user.streak) || 0,
        tokens: Number(user.tokens) || 0,
        readiness_score: Number(user.readiness_score) || 0,
        tier: user.tier,
        last_activity_date: user.last_activity_date,
        // Level curve comes from the server so the app never re-implements it.
        xp_at_level_start: levelBase,
        xp_for_next_level: nextLevelAt - levelBase,
        xp_into_level: Math.max(0, xp - levelBase),
        next_level: level + 1,
      },
      dimensions: dimensions.rows,
      tasks_completed: counts.rows[0].tasks_completed,
      attempts_total: counts.rows[0].attempts_total,
      passed_last_7_days: counts.rows[0].passed_last_7_days,
      next_task: nextTask.task || null,
      next_task_error: nextTask.task ? null : nextTask.error || nextTask.message || null,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getDashboard };
