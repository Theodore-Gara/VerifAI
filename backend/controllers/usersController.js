const pool = require('../db/pool');
const { positiveIntegerParam } = require('../middleware/validate');
const { findUserByFirebaseUid } = require('../db/users');
const { purgeAccount } = require('../services/accountPurge');

const AVATAR_MIME = new Set(['image/png', 'image/jpeg', 'image/webp']);
const MAX_AVATAR_BYTES = 2 * 1024 * 1024;

async function getMe(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT u.id, u.firebase_uid, u.email, u.display_name, u.created_at,
              u.industry_track_id,
              t.name AS industry_track_name,
               a.role AS admin_role
       FROM users u
       LEFT JOIN industry_tracks t ON t.id = u.industry_track_id
       LEFT JOIN admin_accounts a ON lower(a.email) = lower(u.email)
       WHERE u.firebase_uid = $1`,
      [req.firebaseUser.uid]
    );

    if (!result.rows.length) {
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }

    return res.status(200).json({ user: result.rows[0], request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

async function updateProfile(req, res, next) {
  try {
    const { display_name: displayName, industry_track_id: industryTrackId } = req.body;

    if (displayName === undefined && industryTrackId === undefined) {
      return res.status(400).json({ error: 'Provide at least one profile field to update.', request_id: req.requestId });
    }

    if (displayName !== undefined && displayName !== null && (typeof displayName !== 'string' || displayName.trim().length === 0 || displayName.length > 255)) {
      return res.status(400).json({ error: 'display_name must be a non-empty string of 255 characters or fewer.', request_id: req.requestId });
    }

    let trackId = null;
    if (industryTrackId !== undefined && industryTrackId !== null) {
      trackId = positiveIntegerParam(industryTrackId, 'industry_track_id');
      const track = await pool.query('SELECT id FROM industry_tracks WHERE id = $1', [trackId]);
      if (!track.rows.length) {
        return res.status(400).json({ error: 'Selected industry track does not exist.', request_id: req.requestId });
      }
    }

    const result = await pool.query(
      `UPDATE users
       SET display_name = CASE WHEN $1::boolean THEN $2 ELSE display_name END,
           industry_track_id = CASE WHEN $3::boolean THEN $4 ELSE industry_track_id END
       WHERE firebase_uid = $5
       RETURNING id, firebase_uid, email, display_name, industry_track_id, created_at`,
      [displayName !== undefined, displayName === null ? null : displayName?.trim(), industryTrackId !== undefined, trackId, req.firebaseUser.uid]
    );

    if (!result.rows.length) {
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }

    return res.status(200).json({ user: result.rows[0] });
  } catch (err) {
    return next(err);
  }
}

// POST /api/users/avatar  { image_base64, mime }
// Stored inline as bytea. Upgrade to object storage if avatars grow.
async function uploadAvatar(req, res, next) {
  try {
    const user = await findUserByFirebaseUid(pool, req.firebaseUser.uid);
    if (!user) {
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }

    const mime = String(req.body.mime || '').toLowerCase().trim();
    if (!AVATAR_MIME.has(mime)) {
      return res.status(400).json({ error: 'mime must be image/png, image/jpeg or image/webp.', request_id: req.requestId });
    }

    let encoded = req.body.image_base64;
    if (typeof encoded !== 'string' || !encoded.trim()) {
      return res.status(400).json({ error: 'image_base64 is required.', request_id: req.requestId });
    }
    // Tolerate a data-URI prefix: "data:image/png;base64,...."
    const comma = encoded.indexOf(',');
    if (encoded.startsWith('data:') && comma >= 0) encoded = encoded.slice(comma + 1);

    const bytes = Buffer.from(encoded, 'base64');
    if (!bytes.length) {
      return res.status(400).json({ error: 'image_base64 is not valid base64.', request_id: req.requestId });
    }
    if (bytes.length > MAX_AVATAR_BYTES) {
      return res.status(413).json({ error: 'Avatar must be 2MB or smaller.', request_id: req.requestId });
    }

    const result = await pool.query(
      `INSERT INTO user_avatars (user_id, mime, bytes)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id) DO UPDATE SET
         mime = EXCLUDED.mime, bytes = EXCLUDED.bytes, updated_at = CURRENT_TIMESTAMP
       RETURNING mime, updated_at, octet_length(bytes) AS bytes`,
      [user.id, mime, bytes],
    );

    return res.status(200).json({ avatar: result.rows[0], request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/users/avatar — returns the raw image
async function getAvatar(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT a.mime, a.bytes
       FROM user_avatars a
       JOIN users u ON u.id = a.user_id
       WHERE u.firebase_uid = $1`,
      [req.firebaseUser.uid],
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'No avatar set.', request_id: req.requestId });
    }
    res.setHeader('Content-Type', result.rows[0].mime);
    res.setHeader('Cache-Control', 'private, max-age=300');
    return res.status(200).send(result.rows[0].bytes);
  } catch (err) {
    return next(err);
  }
}

// DELETE /api/users/me
// Removes the account everywhere: the database row (cascading to all of the
// user's data) and then the Firebase identity, so the email can be reused.
// Shares one implementation with the admin hard delete — see
// services/accountPurge.js for why the order matters.
async function deleteAccount(req, res, next) {
  try {
    const purge = await purgeAccount({ firebaseUid: req.firebaseUser.uid });

    return res.status(200).json({
      deleted: true,
      had_profile: purge.hadProfile,
      identity_deleted: purge.firebaseDeleted,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getMe, updateProfile, uploadAvatar, getAvatar, deleteAccount };