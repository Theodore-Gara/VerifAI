const { verifyFirebaseToken } = require('./auth');

// Admin gate. Two ways to qualify:
//  1. The Firebase ID token carries an `admin: true` custom claim (set via the
//     Firebase Admin SDK when promoting an account permanently), OR
//  2. The verified token's email appears in the ADMIN_EMAILS env allowlist
//     (comma-separated, case-insensitive; entries may carry a role suffix like
//     "ops@x.com:moderator"), OR
//  3. The email has a row in admin_accounts (managed from the panel's System
//     tab — requires DB access, so checked async).
//
// isAdmin is the synchronous fast path (claims + allowlist only); the full
// requireAdminAuth also consults the registry via resolveRole. Keep the two in
// agreement: any email recognised by resolveRole must pass isAdmin.
function isAdmin(firebaseUser) {
  if (firebaseUser.admin === true) return true;
  if (typeof firebaseUser.admin_role === 'string' && firebaseUser.admin_role) return true;
  const email = String(firebaseUser.email || '').toLowerCase();
  if (!email) return false;
  const allowlist = (process.env.ADMIN_EMAILS || '')
    .split(',')
    .map((entry) => entry.trim().toLowerCase())
    .filter(Boolean);
  // Entries may carry a role suffix ("ops@x.com:moderator") — match the email part.
  return allowlist.some((entry) => entry === email || entry.startsWith(email + ':'));
}

async function requireAdmin(req, res, next) {
  if (!req.firebaseUser) {
    return res.status(401).json({ error: 'Missing or malformed Authorization header. Expected: Bearer <token>.', request_id: req.requestId });
  }
  if (isAdmin(req.firebaseUser)) return next();
  // Registry rows (admin_accounts) grant access too — checked async since
  // isAdmin is the synchronous fast path used elsewhere.
  try {
    const pool = require('../db/pool');
    const email = String(req.firebaseUser.email || '').toLowerCase();
    if (email) {
      const row = await pool.query('SELECT 1 FROM admin_accounts WHERE lower(email) = $1 LIMIT 1', [email]);
      if (row.rows.length) return next();
    }
  } catch (err) {
    // Registry unavailable (migration not applied) — fall through to 403.
  }
  return res.status(403).json({ error: 'Admin access required.', request_id: req.requestId });
}

// Convenience: one middleware pair for admin routes.
function requireAdminAuth(req, res, next) {
  verifyFirebaseToken(req, res, (err) => {
    if (err) return next(err);
    requireAdmin(req, res, next);
  });
}

module.exports = { requireAdmin, requireAdminAuth, isAdmin };
