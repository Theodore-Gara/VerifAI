// scripts/local-db.js — local development database, no external Postgres needed.
//
// Wraps the `embedded-postgres` dev dependency: initialises (once) and starts a
// real Postgres cluster under backend/.pgdata, ensures the `verifai` database
// exists, writes DATABASE_URL into backend/.env (without touching any existing
// keys), then hands off to scripts/db-setup.js to build schema + seeds.
//
//   node scripts/local-db.js          build/refresh the DB, then keep it running
//
// embedded-postgres shuts the cluster down when this process exits, so the
// script stays in the foreground (Ctrl+C to stop). Run it in one terminal and
// `npm start` in another. The cluster listens on 127.0.0.1:5433 (not 5432, to
// avoid clashing with any system Postgres), with password auth so the
// DATABASE_URL matches what a hosted deployment looks like. This is a
// DEVELOPMENT convenience only — the deployed environment keeps using its own
// DATABASE_URL (Railway/Supabase).

require('dotenv').config();

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const DATA_DIR = path.join(__dirname, '..', '.pgdata');
const ENV_PATH = path.join(__dirname, '..', '.env');
const DB_NAME = 'verifai';
const DB_USER = 'verifai';
const DB_PASSWORD = 'verifai-local';
const DB_PORT = Number(process.env.LOCAL_PG_PORT) || 5433;

// embedded-postgres is ESM-only; Node 22 can import() it from CommonJS.
async function loadEmbeddedPostgres() {
  const mod = await import('embedded-postgres');
  return mod.default;
}

// Creates or updates KEY=VALUE in backend/.env, preserving every other line.
function upsertEnvVar(key, value) {
  const line = `${key}=${value}`;
  let content = fs.existsSync(ENV_PATH) ? fs.readFileSync(ENV_PATH, 'utf8') : '';
  const regex = new RegExp(`^${key}=.*$`, 'm');
  if (regex.test(content)) {
    content = content.replace(regex, line);
  } else {
    const sep = content && !content.endsWith('\n') ? '\n' : '';
    content += `${sep}${line}\n`;
  }
  fs.writeFileSync(ENV_PATH, content);
}

async function main() {
  const EmbeddedPostgres = await loadEmbeddedPostgres();
  const pg = new EmbeddedPostgres({
    databaseDir: DATA_DIR, user: DB_USER, password: DB_PASSWORD, port: DB_PORT, persistent: true,
  });

  // initialise() refuses to re-init an existing cluster, so only run it when
  // the data directory has never been populated.
  if (!fs.existsSync(path.join(DATA_DIR, 'PG_VERSION'))) {
    console.log('Initialising local Postgres cluster (first run only)…');
    await pg.initialise();
  }
  await pg.start();
  console.log(`Local Postgres running on 127.0.0.1:${DB_PORT}.`);

  await pg.createDatabase(DB_NAME).catch((err) => {
    // "already exists" is fine on re-runs.
    if (!/already exists/i.test(err.message)) throw err;
  });

  const url = `postgresql://${DB_USER}:${DB_PASSWORD}@127.0.0.1:${DB_PORT}/${DB_NAME}`;
  upsertEnvVar('DATABASE_URL', url);
  upsertEnvVar('NODE_ENV', process.env.NODE_ENV || 'development');
  upsertEnvVar('PORT', process.env.PORT || '3000');
  // Local-friendly admin allowlist default so /admin is reachable out of the
  // box; the file remains editable for real accounts.
  upsertEnvVar('ADMIN_EMAILS', process.env.ADMIN_EMAILS || 'admin@example.com,vusani@verify.com');
  console.log(`DATABASE_URL written to backend/.env → ${url}`);

  // Re-use the standard setup path so local and hosted builds are identical.
  process.env.DATABASE_URL = url;
  await new Promise((resolve, reject) => {
    const child = spawn(process.execPath, [require.resolve('./db-setup.js'), 'fresh'], {
      stdio: 'inherit', env: process.env,
    });
    child.on('exit', (code) => (code === 0 ? resolve() : reject(new Error(`db-setup exited with code ${code}`))));
    child.on('error', reject);
  });

  console.log('\n✔ Local database ready.');
  console.log('  • Start the API in another terminal:  npm start');
  console.log('  • Admin dashboard:                    http://localhost:3000/admin');
  console.log('  • Stop the database (Ctrl+C here) when you are done.');
}

main().catch((err) => {
  console.error(`\nFAILED: ${err && err.message ? err.message : String(err)}`);
  process.exit(1);
});
