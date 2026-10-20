const pool = require('../db/pool');
const { leaderboardCache } = require('../utils/ttlCache');

// GET /api/leaderboard
//
// Deterministic top-N board ordered by XP (ties broken by readiness score,
// then user id so the order is stable). Auth required. Optional filters:
//   ?track=<industry_track_id>  limit the board to one industry track
//   ?limit=<1..50>              board size (default 20)
// The response always includes `me` — the requesting user's own row with their
// computed rank — even when they sit outside the top N.

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 50;

function parseLimit(raw) {
  const parsed = Number.parseInt(raw, 10);
  if (!Number.isInteger(parsed)) return DEFAULT_LIMIT;
  return Math.min(MAX_LIMIT, Math.max(1, parsed));
}

function buildTrackFilter(params, rawTrack) {
  const trackId = rawTrack === undefined ? null : Number.parseInt(rawTrack, 10);
  if (trackId === null || !Number.isInteger(trackId)) return '';
  params.push(trackId);
  return ` WHERE u.industry_track_id = $${params.length}`;
}

async function getLeaderboard(req, res, next) {
  try {
    const limit = parseLimit(req.query.limit);

    // ---- Board ------------------------------------------------------------
    const boardParams = [];
    const trackFilter = buildTrackFilter(boardParams, req.query.track);
    boardParams.push(limit);

    // The board is a full RANK() over every learner, and it changes slowly, so
    // it is cached per (track, limit) for a minute. The caller's own rank below
    // stays live: that is the row a learner actually notices.
    const cacheKey = `board:${trackFilter ? boardParams[0] : 'all'}:${limit}`;
    const board = await leaderboardCache.wrap(cacheKey, async () => {
      const result = await pool.query(
      `SELECT r.rank, r.user_id, r.display_name, r.level, r.xp,
              r.streak, r.readiness_score, r.tier
       FROM (
         SELECT u.id AS user_id,
                u.display_name,
                COALESCE(p.level, 1)::int AS level,
                COALESCE(p.xp, 0)::int AS xp,
                COALESCE(p.streak, 0)::int AS streak,
                COALESCE(p.readiness_score, 0)::int AS readiness_score,
                COALESCE(p.tier, 'Novice') AS tier,
                ROW_NUMBER() OVER (
                  ORDER BY COALESCE(p.xp, 0) DESC,
                           COALESCE(p.readiness_score, 0) DESC,
                           u.id ASC
                ) AS rank
         FROM users u
         LEFT JOIN user_progress p ON p.user_id = u.id
         ${trackFilter}
       ) r
       ORDER BY r.rank ASC
       LIMIT $${boardParams.length}`,
        boardParams
      );
      return result.rows;
    });

    // ---- Requesting user --------------------------------------------------
    const me = await pool.query(
      `SELECT u.id AS user_id,
              u.display_name,
              u.industry_track_id,
              COALESCE(p.level, 1)::int AS level,
              COALESCE(p.xp, 0)::int AS xp,
              COALESCE(p.streak, 0)::int AS streak,
              COALESCE(p.readiness_score, 0)::int AS readiness_score,
              COALESCE(p.tier, 'Novice') AS tier
       FROM users u
       LEFT JOIN user_progress p ON p.user_id = u.id
       WHERE u.firebase_uid = $1`,
      [req.firebaseUser.uid]
    );

    if (!me.rows.length) {
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }
    const meRow = me.rows[0];

    // Use the same tie-breakers as the board so `me.rank` matches its row rank.
    const rankParams = [meRow.xp, meRow.readiness_score, meRow.user_id];
    let rankFilter = '';
    if (trackFilter) {
      rankParams.push(boardParams[0]);
      rankFilter = ` AND u.industry_track_id = $${rankParams.length}`;
    }

    const rank = await pool.query(
      `SELECT (COUNT(*)::int + 1) AS rank
       FROM users u
       LEFT JOIN user_progress p ON p.user_id = u.id
       WHERE (
         COALESCE(p.xp, 0) > $1
         OR (COALESCE(p.xp, 0) = $1 AND COALESCE(p.readiness_score, 0) > $2)
         OR (COALESCE(p.xp, 0) = $1 AND COALESCE(p.readiness_score, 0) = $2 AND u.id < $3)
       )${rankFilter}`,
      rankParams
    );

    return res.status(200).json({
      track_id: trackFilter ? boardParams[0] : null,
      leaderboard: board,
      me: { ...meRow, rank: rank.rows[0].rank },
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getLeaderboard };