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

// Every authenticated request used to cost a second query just to read the
// moderation status. A short TTL keeps that off the hot path; a status change
// clears the entry immediately, so the only staleness is between two API
// instances (bounded by AUTH_STATUS_CACHE_MS, default 60s).
const STATUS_TTL_MS = Number(process.env.AUTH_STATUS_CACHE_MS) || 60000;
const statusCache = new Map();

function readCachedStatus(uid) {
  const entry = statusCache.get(uid);
  if (!entry) return null;
  if (entry.expiresAt <= Date.now()) {
    statusCache.delete(uid);
    return null;
  }
  return entry;
}

function rememberStatus(uid, status, isAdmin) {
  // Bound the cache so a long-lived process with many visitors cannot grow it
  // without limit; entries are cheap and re-readable.
  if (statusCache.size > 10000) statusCache.clear();
  statusCache.set(uid, { status, isAdmin, expiresAt: Date.now() + STATUS_TTL_MS });
}

/**
 * Drops the cached status for one account (or all of them). Called whenever an
 * admin changes a status or an account is deleted, so the change is visible on
 * that user's very next request.
 */
function invalidateStatusCache(uid) {
  if (uid) statusCache.delete(uid);
  else statusCache.clear();
}

async function verifyFirebaseToken(req, res, next) {
  // A learner-route guard may have already verified the token.
  if (req.firebaseUser) return next();

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

  // Moderation gate. Admins are exempt so the dashboard keeps working against
  // any account.
  try {
    let entry = readCachedStatus(req.firebaseUser.uid);
    if (entry === null) {
      const result = await pool.query(
        `SELECT status, is_admin FROM users WHERE firebase_uid = $1`,
        [req.firebaseUser.uid]
      );
      const status = result.rows[0]?.status || 'active';
      const isAdmin = result.rows[0]?.is_admin === true;
      // Only cache a real row: an account that has not called /api/auth/sync
      // yet must not be remembered as "active" forever.
      if (result.rows.length) rememberStatus(req.firebaseUser.uid, status, isAdmin);
      entry = { status, isAdmin };
    }

    req.userIsAdmin = entry.isAdmin === true
      || require('./admin').isAdmin(req.firebaseUser);

    if (BLOCKED_STATUSES.has(entry.status) && !req.userIsAdmin) {
      const http = STATUS_HTTP[entry.status];
      return res.status(http.status).json({
        error: `Your account is ${entry.status}.`,
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

// Learner routes are off-limits to admin accounts. The app already redirects
// admins to the admin portal; this is the server-side half of the boundary.
function verifyLearnerToken(req, res, next) {
  const url = req.originalUrl.split('?')[0];
  // Reading your own profile is part of the auth handshake, not a learner
  // action. Admin accounts need it during sign-in before the app can route them
  // to the admin portal.
  if (req.method === 'GET' && url === '/api/users/me') {
    return verifyFirebaseToken(req, res, next);
  }
  // Capstone marking lives under /api/lab but is an admin/reviewer endpoint.
  // Let it reach requireAdminAuth instead of rejecting the admin here.
  if (/^\/api\/lab\/assessments\/[^/]+\/attempts\/\d+\/mark$/.test(url)) {
    return verifyFirebaseToken(req, res, next);
  }
  verifyFirebaseToken(req, res, (err) => {
    if (err) return next(err);
    if (req.userIsAdmin) {
      return res.status(403).json({
        error: 'Admin accounts cannot use learner features.',
        code: 'admin_learner_blocked',
        request_id: req.requestId,
      });
    }
    return next();
  });
}

module.exports = { verifyFirebaseToken, verifyLearnerToken, invalidateStatusCache };
