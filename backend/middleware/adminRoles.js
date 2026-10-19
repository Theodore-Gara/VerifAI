const pool = require('../db/pool');

// Role hierarchy for the admin panel:
//   super      — everything, including managing admins and destructive tools
//   admin      — everything except admin management (the default)
//   moderator  — users, workshop moderation and audit log only
//
// A caller's role resolves from, in order of precedence:
//   1. the `admin_role` Firebase custom claim (set via the Admin SDK)
//   2. a row in admin_accounts (managed from the panel's System tab)
//   3. ADMIN_EMAILS entries in the form "email" or "email:role"
//      ("ops@x.com:moderator"), defaulting to 'admin'
// Every admin is still gated by middleware/admin.js first — role only decides
// WHICH admin endpoints they may use, never bypasses the auth itself.

const ROLE_LEVEL = { moderator: 1, admin: 2, super: 3 };

async function resolveRole(firebaseUser) {
  const claim = firebaseUser.admin_role || null;
  if (claim && ROLE_LEVEL[claim]) return claim;

  const email = String(firebaseUser.email || '').toLowerCase();
  if (email) {
    try {
      const row = await pool.query('SELECT role FROM admin_accounts WHERE email = $1', [email]);
      if (row.rows[0] && ROLE_LEVEL[row.rows[0].role]) return row.rows[0].role;
    } catch (err) {
      // Registry unavailable (migration not applied) — fall through to env.
    }
    const entry = (process.env.ADMIN_EMAILS || '')
      .split(',')
      .map((s) => s.trim().toLowerCase())
      .find((s) => s === email || s.startsWith(email + ':'));
    if (entry) {
      const role = entry.slice(email.length + 1).trim();
      if (ROLE_LEVEL[role]) return role;
      return 'admin';
    }
  }
  return firebaseUser.admin === true ? 'admin' : null;
}

// requireRole('moderator') passes every admin role; requireRole('admin') passes
// admin and super; requireRole('super') passes only super.
function requireRole(minimum) {
  const minimumLevel = ROLE_LEVEL[minimum];
  if (!minimumLevel) throw new Error(`Unknown admin role: ${minimum}`);

  return async (req, res, next) => {
    try {
      const role = await resolveRole(req.firebaseUser);
      req.adminRole = role;
      if (!role || ROLE_LEVEL[role] < minimumLevel) {
        return res.status(403).json({
          error: `This action requires ${minimum} privileges.`,
          request_id: req.requestId,
        });
      }
      return next();
    } catch (err) {
      return next(err);
    }
  };
}

// Runtime platform config (app_config). Used for maintenance mode + flags.
const CONFIG_DEFAULTS = {
  maintenance_mode: 'off', // 'on' | 'off'
  maintenance_message: 'VerifAI is briefly offline for scheduled maintenance. Please try again shortly.',
  flag_workshop: 'on',
  flag_assistant: 'on',
  flag_vera: 'on',
};

let configCache = null;
let configCachedAt = 0;
const CONFIG_TTL_MS = 5000;

async function getConfig() {
  // Short TTL cache: the gate runs on every request, so it must not hit the
  // database each time.
  if (configCache && Date.now() - configCachedAt < CONFIG_TTL_MS) return configCache;
  const rows = await pool.query('SELECT key, value FROM app_config');
  const config = { ...CONFIG_DEFAULTS };
  for (const row of rows.rows) {
    if (row.value != null) config[row.key] = row.value;
  }
  configCache = config;
  configCachedAt = Date.now();
  return config;
}

function invalidateConfigCache() {
  configCache = null;
}

// Maintenance gate: when maintenance_mode is on, every learner-facing request
// is refused with 503 (admin and health traffic is exempt). Mounted on the API
// router in app.js.
async function maintenanceGate(req, res, next) {
  // Health, auth (so admins can still sign in to turn maintenance off), the
  // admin API and the admin dashboard stay live during maintenance.
  if (req.path.startsWith('/api/health') || req.path.startsWith('/api/admin')
      || req.path.startsWith('/api/auth') || req.path.startsWith('/admin')
      || req.path === '/') {
    return next();
  }
  try {
    const config = await getConfig();
    if (config.maintenance_mode === 'on') {
      return res.status(503).json({
        error: config.maintenance_message,
        code: 'MAINTENANCE_MODE',
        request_id: req.requestId,
      });
    }
    return next();
  } catch (err) {
    // Fail safe: if the config table is unreachable (DB down, migration not
    // applied), let the request through rather than 500-ing every route.
    console.error('Maintenance gate skipped (config unavailable):', err.message);
    return next();
  }
}

module.exports = { resolveRole, requireRole, getConfig, invalidateConfigCache, maintenanceGate, CONFIG_DEFAULTS };
