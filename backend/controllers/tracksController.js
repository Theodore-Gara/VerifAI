const pool = require('../db/pool');

async function getTracks(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT id, name, description
       FROM industry_tracks
       ORDER BY id ASC`
    );

    return res.status(200).json({ tracks: result.rows });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getTracks };
