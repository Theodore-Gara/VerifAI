const { getFirebaseAdmin } = require('../db/firebase');

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
    const admin = getFirebaseAdmin();
    req.firebaseUser = await admin.auth().verifyIdToken(token);
    return next();
  } catch (err) {
    console.error('Firebase token verification failed:', err.message);
    return res.status(401).json({ error: 'Invalid or expired token.', request_id: req.requestId });
  }
}

module.exports = { verifyFirebaseToken };
