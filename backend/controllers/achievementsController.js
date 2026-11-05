const pool = require('../db/pool');
const { sendApiError } = require('../utils/apiError');

// GET /api/achievements/me — earned achievements only (kept for older builds).
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
// unlocked states from one call. Ordered by id, as the contract requires.
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
// BF-9: the former roadmap checklist moved to the achievements catalog and to
// GET /api/roadmap (BB-10). Keep a 410 Gone shim for one release so an old app
// build gets a clear code instead of an empty list or a 404.
function goneMilestones(req, res) {
  return sendApiError(
    req,
    res,
    410,
    'roadmap_moved',
    'The track roadmap moved to /api/roadmap.',
    {
      hint: 'Open GET /api/roadmap for the staged journey.',
      retryable: false,
    },
  );
}

module.exports = { getAchievements, getCatalog, goneMilestones };
