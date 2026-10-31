const { getFirebaseAuth } = require('../db/firebase');
const pool = require('../db/pool');
const { findUserByFirebaseUid } = require('../db/users');

// Identifies the caller when a valid bearer token is present, and carries on
// anonymously when it is not. Used by the public support routes: About, Help
// and Contact must work from the login screen, but a signed-in sender should
// still be linked to their account (so deleting the account deletes the
// message) and rate limited per account instead of per IP.
//
// Unlike verifyFirebaseToken this never rejects: a stale token or a suspended
// account must not stop someone from reading help or asking for help, and the
// troubleshooting guide tells suspended users to use Contact us.
async function optionalAuth(req, res, next) {
  const [scheme, token] = (req.headers.authorization || '').split(' ');
  if (scheme !== 'Bearer' || !token) return next();

  try {
    req.firebaseUser = await getFirebaseAuth().verifyIdToken(token);
  } catch {
    req.firebaseUser = undefined;
    return next();
  }

  try {
    const user = await findUserByFirebaseUid(pool, req.firebaseUser.uid);
    if (user) req.user = user;
  } catch (err) {
    // The route still works anonymously if the lookup fails.
    console.error(`[${req.requestId || 'no-request-id'}] optional auth user lookup failed: ${err.message}`);
  }
  return next();
}

module.exports = optionalAuth;
