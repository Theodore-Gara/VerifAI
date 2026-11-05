// BF-7: tutorial state lives on the server, per (user, track), so a reinstall or
// a second device does not forget that the tour was completed or skipped.
const pool = require('../db/pool');
const { findUserByFirebaseUid } = require('../db/users');
const { tutorialState, TOUR_KEY } = require('../services/industrySwitch');
const { apiError } = require('../utils/apiError');

const STATUSES = new Set(['completed', 'skipped']);

async function resolveTrack(req) {
  const raw = req.query.track_id ?? req.body.track_id ?? req.body.track;
  if (raw !== undefined && raw !== null && raw !== '') {
    const trackId = Number(raw);
    if (!Number.isInteger(trackId) || trackId <= 0) {
      throw apiError(400, 'invalid_track', 'track_id must be a positive integer.', {
        publicMessage: 'track_id must be a positive integer.',
        retryable: false,
      });
    }
    return trackId;
  }
  const user = await findUserByFirebaseUid(pool, req.firebaseUser.uid);
  if (!user) {
    throw apiError(404, 'user_not_found', 'User not found.', {
      publicMessage: 'User not found. Call /api/auth/sync first.',
      retryable: false,
    });
  }
  if (!user.industry_track_id) {
    throw apiError(400, 'no_track', 'No industry track selected.', {
      publicMessage: 'Select an industry track first.',
      hint: 'Choose an industry, then open the tour.',
      retryable: false,
    });
  }
  return user.industry_track_id;
}

async function ensureTrackExists(trackId) {
  const result = await pool.query('SELECT id FROM industry_tracks WHERE id = $1', [trackId]);
  if (!result.rows.length) {
    throw apiError(400, 'unknown_track', 'Unknown industry track.', {
      publicMessage: 'That industry track does not exist.',
      hint: 'Refresh the industry list and choose again.',
      retryable: false,
    });
  }
}

// GET /api/onboarding/tour?track_id=&reoffer=1
async function getTourState(req, res, next) {
  try {
    const trackId = await resolveTrack(req);
    await ensureTrackExists(trackId);
    const user = await findUserByFirebaseUid(pool, req.firebaseUser.uid);
    if (!user) {
      throw apiError(404, 'user_not_found', 'User not found.', {
        publicMessage: 'User not found. Call /api/auth/sync first.',
        retryable: false,
      });
    }

    const reoffer = req.query.reoffer === '1' || req.query.reoffer === 'true';
    const state = await tutorialState(pool, user.id, trackId, { reoffer });
    return res.status(200).json({
      ...state,
      track_id: trackId,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// PUT /api/onboarding/tour { track_id?, status: completed|skipped, reoffer? }
async function putTourState(req, res, next) {
  try {
    const status = typeof req.body.status === 'string' ? req.body.status.trim().toLowerCase() : '';
    if (!STATUSES.has(status)) {
      throw apiError(400, 'invalid_status', `Invalid tour status: ${status || '(missing)'}.`, {
        publicMessage: 'status must be completed or skipped.',
        hint: 'Send completed or skipped.',
        retryable: false,
      });
    }

    const trackId = await resolveTrack(req);
    await ensureTrackExists(trackId);
    const user = await findUserByFirebaseUid(pool, req.firebaseUser.uid);
    if (!user) {
      throw apiError(404, 'user_not_found', 'User not found.', {
        publicMessage: 'User not found. Call /api/auth/sync first.',
        retryable: false,
      });
    }

    // Idempotent upsert: repeating the same status does not move updated_at.
    const result = await pool.query(
      `INSERT INTO user_tutorials (user_id, track_id, tour_key, status)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id, track_id, tour_key) DO UPDATE SET
         status = EXCLUDED.status,
         updated_at = CASE
           WHEN user_tutorials.status IS DISTINCT FROM EXCLUDED.status
             THEN CURRENT_TIMESTAMP
           ELSE user_tutorials.updated_at
         END
       RETURNING status, updated_at`,
      [user.id, trackId, TOUR_KEY, status],
    );

    const reoffer = req.body.reoffer === true || req.body.reoffer === '1';
    return res.status(200).json({
      tour_key: TOUR_KEY,
      status: result.rows[0].status,
      should_offer: status === 'skipped' && reoffer,
      updated_at: result.rows[0].updated_at,
      track_id: trackId,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getTourState, putTourState };
