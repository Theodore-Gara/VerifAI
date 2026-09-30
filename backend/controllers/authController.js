const pool = require('../db/pool');

async function syncUser(req, res, next) {
  try {
    const { uid, email, name } = req.firebaseUser;

    if (!uid) {
      return res.status(401).json({ error: 'Firebase token does not contain a user ID.', request_id: req.requestId });
    }

    const result = await pool.query(
      `INSERT INTO users (firebase_uid, email, display_name)
       VALUES ($1, $2, $3)
       ON CONFLICT (firebase_uid)
       DO UPDATE SET
         email = EXCLUDED.email,
         display_name = COALESCE(EXCLUDED.display_name, users.display_name)
       RETURNING id, firebase_uid, email, display_name, created_at`,
      [uid, email || '', name || null]
    );

    return res.status(200).json({ user: result.rows[0] });
  } catch (err) {
    return next(err);
  }
}

module.exports = { syncUser };
