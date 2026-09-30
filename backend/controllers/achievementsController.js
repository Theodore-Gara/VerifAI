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

module.exports = { getAchievements };
