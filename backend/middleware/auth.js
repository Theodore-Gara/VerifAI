const { getFirebaseAuth } = require('../db/firebase');
const pool = require('../db/pool');

// Statuses that lock an account out of the API. 'suspended' and 'banned' are
// set from the admin dashboard; every protected route checks this after the
// token itself verifies, so a status change takes effect on the account's
// next request (the Firebase ID token itself is untouched).
const BLOCKED_STATUSES = new Set(['suspended', 'banned']);

const STATUS_HTTP = {
  suspended: { code: 'ACCOUNT_SUSPENDED', status: 403 },
  banned: { code: 'ACCOUNT_BANNED', status: 403 },
};

async function verifyFirebaseToken(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const [scheme, token] = authHeader.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({
      error: 'Missing or malformed Authorization header. Expected: Bearer <token>.',
      request_id: req.requestId,
    });
  }

  try {
    req.firebaseUser = await getFirebaseAuth().verifyIdToken(token);
  } catch (err) {
    console.error('Firebase token verification failed:', err.message);
    return res.status(401).json({ error: 'Invalid or expired token.', request_id: req.requestId });
  }

  // Moderation gate. A single indexed lookup per request; admins are exempt
  // so the dashboard keeps working against any account.
  try {
    const result = await pool.query(
      `SELECT status FROM users WHERE firebase_uid = $1`,
      [req.firebaseUser.uid]
    );
    const status = result.rows[0]?.status || 'active';
    if (BLOCKED_STATUSES.has(status) && !req.firebaseUser.admin) {
      const http = STATUS_HTTP[status];
      return res.status(http.status).json({
        error: `Your account is ${status}.`,
        code: http.code,
        request_id: req.requestId,
      });
    }
  } catch (err) {
    // If the status lookup itself fails (e.g. migration not applied yet), do
    // not lock everyone out — fall through and let the route run.
    console.error('Account status check failed:', err.message);
  }

  return next();
}

module.exports = { verifyFirebaseToken };
