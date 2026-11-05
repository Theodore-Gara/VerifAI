// BF-5: changing industry is a transaction, not a bare column update.
//
// A switch locks the user row, rejects the current track (so a double tap can
// never reset progress), writes exactly one audit row, recomputes readiness for
// the new track inside the same transaction, and returns the frozen contract
// including the tutorial offer and the values that carry across.
const { refreshReadiness } = require('./readinessService');
const { apiError } = require('../utils/apiError');

const TOUR_KEY = 'industry';
const KEPT = ['xp', 'level', 'streak', 'tokens'];

async function tutorialState(client, userId, trackId, { reoffer = false } = {}) {
  const result = await client.query(
    `SELECT status, updated_at
       FROM user_tutorials
      WHERE user_id = $1 AND track_id = $2 AND tour_key = $3`,
    [userId, trackId, TOUR_KEY],
  );
  const row = result.rows[0];
  return {
    tour_key: TOUR_KEY,
    status: row ? row.status : null,
    // No row for this track means it is new to the learner; a skipped tour is
    // only re-offered when the caller explicitly asks for it.
    should_offer: !row || (row.status === 'skipped' && reoffer === true),
    updated_at: row ? row.updated_at : null,
  };
}

// Caller owns the transaction: this function locks, writes and computes, but
// does not BEGIN/COMMIT so the audit row and the update stay atomic.
async function switchIndustry(client, userId, targetTrackId, { displayName, reoffer = false } = {}) {
  const locked = await client.query(
    `SELECT u.id, u.industry_track_id, t.name AS industry_track_name
       FROM users u
       LEFT JOIN industry_tracks t ON t.id = u.industry_track_id
      WHERE u.id = $1
      FOR UPDATE OF u`,
    [userId],
  );
  if (!locked.rows.length) {
    throw apiError(404, 'user_not_found', 'User not found.', {
      publicMessage: 'User not found. Call /api/auth/sync first.',
      retryable: false,
    });
  }
  const current = locked.rows[0];

  if (current.industry_track_id != null && Number(current.industry_track_id) === Number(targetTrackId)) {
    throw apiError(409, 'same_track', 'Switch to the current track rejected.', {
      publicMessage: 'You are already on that industry track.',
      hint: 'Choose a different industry.',
      retryable: false,
    });
  }

  const trackResult = await client.query(
    `SELECT id, name, description FROM industry_tracks WHERE id = $1`,
    [targetTrackId],
  );
  if (!trackResult.rows.length) {
    throw apiError(400, 'unknown_track', 'Unknown industry track.', {
      publicMessage: 'That industry track does not exist.',
      hint: 'Refresh the industry list and choose again.',
      retryable: false,
    });
  }
  const track = trackResult.rows[0];

  await client.query(
    `UPDATE users
        SET industry_track_id = $2,
            display_name = COALESCE($3, display_name)
      WHERE id = $1`,
    [userId, targetTrackId, displayName === undefined ? null : displayName],
  );

  // Exactly one audit row per successful switch.
  await client.query(
    `INSERT INTO user_track_changes (user_id, from_track_id, to_track_id)
     VALUES ($1, $2, $3)`,
    [userId, current.industry_track_id, targetTrackId],
  );

  // Recompute for the NEW track inside the transaction. refreshReadiness also
  // mirrors the active track's value into user_progress for older paths.
  await refreshReadiness(client, userId, targetTrackId);

  // One client, so the queries are queued rather than overlapped.
  const progress = await client.query(
    `SELECT readiness_score, tier
       FROM user_track_progress
      WHERE user_id = $1 AND track_id = $2`,
    [userId, targetTrackId],
  );
  const skills = await client.query(
    `SELECT dimension, score, attempts_count
       FROM skill_scores
      WHERE user_id = $1 AND track_id = $2
      ORDER BY dimension`,
    [userId, targetTrackId],
  );
  const keptRow = await client.query(
    `SELECT COALESCE(xp, 0)::int AS xp,
            COALESCE(level, 1)::int AS level,
            COALESCE(streak, 0)::int AS streak,
            COALESCE(tokens, 0)::int AS tokens
       FROM user_progress WHERE user_id = $1`,
    [userId],
  );
  const tutorial = await tutorialState(client, userId, targetTrackId, { reoffer });

  const progressRow = progress.rows[0] || { readiness_score: 0, tier: 'Novice' };
  return {
    user: {
      id: current.id,
      industry_track_id: track.id,
      industry_track_name: track.name,
    },
    track: { id: track.id, name: track.name, description: track.description },
    progress: {
      readiness_score: Number(progressRow.readiness_score) || 0,
      tier: progressRow.tier || 'Novice',
      skill_scores: skills.rows,
    },
    tour: tutorial,
    kept: [...KEPT],
    // The values themselves, so the client can show "you keep your XP" without
    // a second request. The frozen contract only requires the names.
    kept_values: keptRow.rows[0] || { xp: 0, level: 1, streak: 0, tokens: 0 },
  };
}

module.exports = { switchIndustry, tutorialState, TOUR_KEY, KEPT };
