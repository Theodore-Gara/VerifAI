const { verifyFirebaseToken } = require('./auth');

// Admin gate. Two ways to qualify:
//  1. The Firebase ID token carries an `admin: true` custom claim (set via the
//     Firebase Admin SDK when promoting an account permanently), OR
//  2. The verified token's email appears in the ADMIN_EMAILS env allowlist
//     (comma-separated, case-insensitive). No database column needed.
//
// Always mounted AFTER verifyFirebaseToken, so the email/uid are verified.
function isAdmin(firebaseUser) {
  if (firebaseUser.admin === true) return true;
  const allowlist = (process.env.ADMIN_EMAILS || '')
    .split(',')
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);
  const email = String(firebaseUser.email || '').toLowerCase();
  return !!email && allowlist.includes(email);
}

async function requireAdmin(req, res, next) {
  if (!req.firebaseUser) {
    return res.status(401).json({ error: 'Missing or malformed Authorization header. Expected: Bearer <token>.', request_id: req.requestId });
  }
  if (!isAdmin(req.firebaseUser)) {
    return res.status(403).json({ error: 'Admin access required.', request_id: req.requestId });
  }
  return next();
}

// Convenience: one middleware pair for admin routes.
function requireAdminAuth(req, res, next) {
  verifyFirebaseToken(req, res, (err) => {
    if (err) return next(err);
    requireAdmin(req, res, next);
  });
}

module.exports = { requireAdmin, requireAdminAuth, isAdmin };
