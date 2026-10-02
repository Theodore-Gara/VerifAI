const pool = require('../db/pool');
const { positiveIntegerParam } = require('../middleware/validate');

async function getMe(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT u.id, u.firebase_uid, u.email, u.display_name, u.created_at,
              u.industry_track_id,
              t.name AS industry_track_name
       FROM users u
       LEFT JOIN industry_tracks t ON t.id = u.industry_track_id
       WHERE u.firebase_uid = $1`,
      [req.firebaseUser.uid]
    );

    if (!result.rows.length) {
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }

    return res.status(200).json({ user: result.rows[0] });
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

module.exports = { getMe, updateProfile };
