const pool = require('../db/pool');
const { contentCache } = require('../utils/ttlCache');
const { sendJsonWithEtag } = require('../utils/httpCache');

async function getTracks(req, res, next) {
  try {
    // Industry tracks are static curriculum data; caching the rows keeps a
    // rarely-changing catalogue off the database and lets clients revalidate.
    const tracks = await contentCache.wrap('tracks', async () => {
      const result = await pool.query(
        `SELECT id, name, description
         FROM industry_tracks
         ORDER BY id ASC`
      );
      return result.rows;
    });

    return sendJsonWithEtag(req, res, { tracks, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getTracks };
