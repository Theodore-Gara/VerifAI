const pool = require('../db/pool');
const { resolveRole } = require('../middleware/adminRoles');

const USER_COLUMNS = 'id, firebase_uid, email, display_name, created_at';

async function syncUser(req, res, next) {
  try {
    const { uid, email, name } = req.firebaseUser;

    if (!uid) {
      return res.status(401).json({ error: 'Firebase token does not contain a user ID.', request_id: req.requestId });
    }

    // Update an existing user in place. Checking first, instead of using an
    // upsert, avoids drawing a `users_id_seq` value on every sign-in - each
    // INSERT ... ON CONFLICT advances the sequence even when it conflicts,
    // which is what produced the large gaps in user ids.
    const updated = await pool.query(
      `UPDATE users
       SET email = $2, display_name = COALESCE($3, display_name)
       WHERE firebase_uid = $1
       RETURNING ${USER_COLUMNS}`,
      [uid, email || '', name || null],
    );
    if (updated.rows.length) {
      return res.status(200).json({ user: updated.rows[0] });
    }

    try {
      const inserted = await pool.query(
        `INSERT INTO users (firebase_uid, email, display_name)
         VALUES ($1, $2, $3)
         RETURNING ${USER_COLUMNS}`,
        [uid, email || '', name || null],
      );
      return res.status(200).json({ user: inserted.rows[0] });
    } catch (err) {
      // A concurrent first sign-in may have created the row between our UPDATE
      // and INSERT; return theirs rather than failing.
      if (err.code === '23505') {
        const existing = await pool.query(
          `SELECT ${USER_COLUMNS} FROM users WHERE firebase_uid = $1`,
          [uid],
        );
        if (existing.rows.length) return res.status(200).json({ user: existing.rows[0] });
      }
      throw err;
    }
  } catch (err) {
    return next(err);
  }
}

// GET /api/auth/me — who the signed-in user is, plus their admin status and
// role so the app can show a profile role badge and an Admin Panel entry
// point. Admin status resolves the same way the panel gates it: the
// admin_accounts registry (database-driven, e.g. vusani@verify.com = super),
// an admin_role Firebase claim, or the ADMIN_EMAILS env bootstrap.
async function me(req, res, next) {
  try {
    const { uid, email } = req.firebaseUser;
    if (!uid) {
      return res.status(401).json({ error: 'Firebase token does not contain a user ID.', request_id: req.requestId });
    }
    const updated = await pool.query(
      `UPDATE users
       SET email = $2, display_name = COALESCE(display_name, $3)
       WHERE firebase_uid = $1
       RETURNING ${USER_COLUMNS}`,
      [uid, email || '', req.firebaseUser.name || null],
    );
    let user = updated.rows[0];
    if (!user) {
      // Not synced yet — create the row so the profile has an identity.
      const inserted = await pool.query(
        `INSERT INTO users (firebase_uid, email, display_name)
         VALUES ($1, $2, $3)
         RETURNING ${USER_COLUMNS}`,
        [uid, email || '', req.firebaseUser.name || null],
      );
      user = inserted.rows[0];
    }

    const role = await resolveRole(req.firebaseUser);
    return res.status(200).json({
      user,
      is_admin: !!role,
      role: role || null,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { syncUser, me };
