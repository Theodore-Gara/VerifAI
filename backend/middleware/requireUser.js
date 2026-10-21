const pool = require('../db/pool');
const { findUserByFirebaseUid } = require('../db/users');

// Resolves the signed-in Firebase uid to the local user row exactly once per
// request, then hands it to the controller as `req.user`.
//
// Every feature router used to re-implement this (seven copies of the same
// function, each issuing its own query). Attaching the row here means one
// lookup per request and one definition of the "call /api/auth/sync first"
// response.
async function requireUser(req, res, next) {
  if (req.user) return next();
  if (!req.firebaseUser || !req.firebaseUser.uid) {
    return res.status(401).json({ error: 'Sign in to continue.', request_id: req.requestId });
  }
  try {
    const user = await findUserByFirebaseUid(pool, req.firebaseUser.uid);
    if (!user) {
      return res.status(404).json({
        error: 'User not found. Call /api/auth/sync first.',
        request_id: req.requestId,
      });
    }
    req.user = user;
    return next();
  } catch (err) {
    return next(err);
  }
}

module.exports = requireUser;
