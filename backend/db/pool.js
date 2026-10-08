const { Pool } = require('pg');

if (!process.env.DATABASE_URL) {
  console.warn('DATABASE_URL is not set. Database-backed routes will fail until it is configured.');
}

// Managed Postgres (Supabase, Railway, Neon, ...) requires TLS; a database on
// localhost does not. Keying this off NODE_ENV alone meant a local `npm start`
// against a hosted database negotiated no TLS and failed to connect.
const databaseUrl = process.env.DATABASE_URL || '';
const isLocalDatabase = /@(localhost|127\.0\.0\.1|\[::1\])(:|\/)/.test(databaseUrl);

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: Number(process.env.DB_POOL_MAX) || 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
  // ponytail: rejectUnauthorized:false accepts any server cert. Fine for now;
  // pin Supabase's CA (ssl.ca) if this ever carries sensitive data over an
  // untrusted network.
  ssl: databaseUrl && !isLocalDatabase ? { rejectUnauthorized: false } : false,
});

pool.on('error', (err) => {
  console.error('Unexpected PostgreSQL pool error:', err.message);
});

module.exports = pool;
