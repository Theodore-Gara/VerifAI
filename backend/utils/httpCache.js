// Conditional-GET helper for catalogue endpoints whose content changes rarely
// (tracks, sources, the rewards catalogue). The payload is hashed into a strong
// ETag and served with a short private max-age; the client's next request can
// revalidate for a 304 instead of re-downloading JSON it already has.
//
// `request_id` is stripped before hashing: it is unique per request, so leaving
// it in would make every ETag different and no conditional request would ever
// match.
const crypto = require('crypto');

function etagFor(value) {
  const body = { ...value };
  delete body.request_id;
  const digest = crypto
    .createHash('sha1')
    .update(JSON.stringify(body))
    .digest('base64url');
  return `"${digest}"`;
}

function sendJsonWithEtag(req, res, payload, { maxAge = 60 } = {}) {
  const etag = etagFor(payload);
  res.setHeader('ETag', etag);
  res.setHeader('Cache-Control', `private, max-age=${maxAge}`);
  const inm = req.headers['if-none-match'];
  if (inm && inm.split(',').map((v) => v.trim()).includes(etag)) {
    return res.status(304).end();
  }
  return res.status(200).json(payload);
}

module.exports = { etagFor, sendJsonWithEtag };
