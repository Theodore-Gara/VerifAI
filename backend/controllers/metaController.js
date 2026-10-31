const { sendJsonWithEtag } = require('../utils/httpCache');
const {
  MAX_FILE_BYTES, MAX_PDF_PAGES, MAX_TEXT, ACCEPTED_DOCUMENT_FORMATS,
} = require('../services/extract');
const { CONTACT_RATE_PER_HOUR } = require('../services/supportLimits');
const { loadTours } = require('../services/supportContent');
const { version: API_VERSION } = require('../package.json');

// GET /api/meta: limits and accepted formats, so the app stops hardcoding them.
//
// Every number comes from the same exported constant the validator or limiter
// enforces (extract.js, supportLimits.js), so the app can never be told one
// limit while the server applies another. tests/backendWiring.test.js asserts
// the equality.
//
// Public and ETag-cached, like the other catalogue endpoints. The tour version
// comes from the database; if that read fails the rest of the document is still
// served with tour_version null rather than failing the whole call.
async function getMeta(req, res, next) {
  try {
    let tourVersion = null;
    try {
      tourVersion = (await loadTours()).version;
    } catch (err) {
      console.error(`[${req.requestId}] meta: tour version unavailable: ${err.message}`);
    }

    return sendJsonWithEtag(req, res, {
      api_version: API_VERSION,
      verification: {
        max_document_bytes: MAX_FILE_BYTES,
        max_pages: MAX_PDF_PAGES,
        max_total_chars: MAX_TEXT,
        accepted_formats: ACCEPTED_DOCUMENT_FORMATS,
      },
      support: { tour_version: tourVersion },
      limits: { contact_rate_per_hour: CONTACT_RATE_PER_HOUR },
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getMeta };
