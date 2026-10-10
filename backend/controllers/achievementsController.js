const pool = require('../db/pool');

async function getAchievements(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT a.id, a.code, a.name, a.description, ua.earned_at
       FROM user_achievements ua
       JOIN achievements a ON a.id = ua.achievement_id
       JOIN users u ON u.id = ua.user_id
       WHERE u.firebase_uid = $1
       ORDER BY ua.earned_at DESC, a.id ASC`,
      [req.firebaseUser.uid]
    );

    return res.status(200).json({ achievements: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/achievements
//
// Full achievements catalog. Every achievement is listed with an `earned`
// flag and (when earned) the timestamp — so the client can render locked and
// unlocked states from one call.
async function getCatalog(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT a.id, a.code, a.name, a.description,
              (ua.id IS NOT NULL) AS earned,
              ua.earned_at
       FROM achievements a
       LEFT JOIN user_achievements ua
         ON ua.achievement_id = a.id
        AND ua.user_id = (SELECT id FROM users WHERE firebase_uid = $1)
       ORDER BY a.id ASC`,
      [req.firebaseUser.uid]
    );

    return res.status(200).json({ achievements: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/achievements/milestones
//
// Code-defined track milestones with live progress. `?track=<id>` overrides
// the user's selected track. Milestones cover task completion, XP, streak
// and level; `achieved` flips as soon as `current >= target`.
const XP_MILESTONES = [250, 1000];
const STREAK_MILESTONES = [7];
const LEVEL_MILESTONES = [5];

function buildMilestones({ xp, level, streak, totalTasks, completed }) {
  const milestones = [
    {
      code: 'first_task',
      name: 'First Steps',
      description: 'Complete your first task',
      target: 1,
      current: completed,
      achieved: completed >= 1,
    },
    {
      code: 'track_master',
      name: 'Track Master',
      description: `Complete every task in the track (${totalTasks})`,
      target: totalTasks,
      current: completed,
      achieved: totalTasks > 0 && completed >= totalTasks,
    },
  ];
  for (const target of XP_MILESTONES) {
    milestones.push({
      code: `xp_${target}`,
      name: target === 250 ? 'Committed' : 'Dedicated',
      description: `Earn ${target} XP`,
      target,
      current: xp,
      achieved: xp >= target,
    });
  }
  for (const target of STREAK_MILESTONES) {
    milestones.push({
      code: `streak_${target}`,
      name: 'On Fire',
      description: `Reach a ${target}-day streak`,
      target,
      current: streak,
      achieved: streak >= target,
    });
  }
  for (const target of LEVEL_MILESTONES) {
    milestones.push({
      code: `level_${target}`,
      name: 'Seasoned',
      description: `Reach level ${target}`,
      target,
      current: level,
      achieved: level >= target,
    });
  }
  return milestones;
}

async function getMilestones(req, res, next) {
  try {
    const me = await pool.query(
      `SELECT u.id AS user_id,
              u.industry_track_id,
              COALESCE(p.xp, 0)::int AS xp,
              COALESCE(p.level, 1)::int AS level,
              COALESCE(p.streak, 0)::int AS streak
       FROM users u
       LEFT JOIN user_progress p ON p.user_id = u.id
       WHERE u.firebase_uid = $1`,
      [req.firebaseUser.uid]
    );

    if (!me.rows.length) {
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }
    const meRow = me.rows[0];

    const requested = req.query.track === undefined ? null : Number.parseInt(req.query.track, 10);
    const trackId = Number.isInteger(requested) ? requested : meRow.industry_track_id;

    if (trackId === null) {
      return res.status(400).json({
        error: 'No industry track selected. Pass ?track=<id> or complete onboarding.',
        request_id: req.requestId,
      });
    }

    // Distinct tasks passed vs total tasks in the track. ta.user_id lives in
    // the JOIN condition so users with zero attempts still get totalTasks.
    const totals = await pool.query(
      `SELECT COUNT(*)::int AS total_tasks,
              COUNT(DISTINCT ta.task_id) FILTER (WHERE ta.passed)::int AS completed
       FROM tasks t
       LEFT JOIN task_attempts ta
         ON ta.task_id = t.id AND ta.user_id = $2
       WHERE t.track_id = $1`,
      [trackId, meRow.user_id]
    );
    const { total_tasks: totalTasks, completed } = totals.rows[0];

    return res.status(200).json({
      track_id: trackId,
      milestones: buildMilestones({
        xp: meRow.xp,
        level: meRow.level,
        streak: meRow.streak,
        totalTasks,
        completed,
      }),
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getAchievements, getCatalog, getMilestones };
