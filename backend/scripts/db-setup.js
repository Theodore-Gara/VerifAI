require('dotenv').config();

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const pool = require('../db/pool');

const DB_DIR = path.join(__dirname, '..', 'db');
const MIGRATIONS_DIR = path.join(DB_DIR, 'migrations');
const SEED_DIR = path.join(DB_DIR, 'seed');

const LEDGER_DDL = `
CREATE TABLE IF NOT EXISTS schema_migrations (
  version    TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  checksum   TEXT NOT NULL,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
)`;

// Zero-padded prefixes sort correctly as plain strings, up to 999 migrations.
const MIGRATION_FILE = /^(\d+)_.+\.sql$/;

const listMigrations = () =>
  fs.readdirSync(MIGRATIONS_DIR)
    .filter((f) => MIGRATION_FILE.test(f))
    .sort()
    .map((name) => {
      const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, name), 'utf8');
      const sha = (value) => crypto.createHash('sha256').update(value).digest('hex').slice(0, 16);
      // Hash with LF endings so the checksum is stable across platforms (a
      // Windows checkout that rewrote CRLF would otherwise look like an edit).
      // checksumRaw keeps the on-disk hash so older records still match.
      return {
        version: MIGRATION_FILE.exec(name)[1],
        name,
        sql,
        checksum: sha(sql.replace(/\r\n/g, '\n')),
        checksumRaw: sha(sql),
      };
    });

// Per-feature content files in db/seed/, applied in filename order.
const listSeeds = () =>
  fs.existsSync(SEED_DIR)
    ? fs
        .readdirSync(SEED_DIR)
        .filter((f) => f.endsWith('.sql'))
        .sort()
        .map((name) => ({ name, sql: fs.readFileSync(path.join(SEED_DIR, name), 'utf8') }))
    : [];

const ensureLedger = (client) => client.query(LEDGER_DDL);

/**
 * Applies every migration that is not already recorded in schema_migrations.
 * Each file runs in its own transaction together with its ledger row, so a
 * failure leaves both the schema and the ledger untouched.
 */
async function runMigrations(client, migrations, { log = () => {} } = {}) {
  await ensureLedger(client);

  const { rows } = await client.query(
    'select version, name, checksum, applied_at from schema_migrations'
  );
  const applied = new Map(rows.map((r) => [r.version, r]));

  let ran = 0;
  for (const m of migrations) {
    const prev = applied.get(m.version);
    if (prev) {
      if (prev.checksum !== m.checksum && prev.checksum !== m.checksumRaw) {
        throw new Error(
          `${m.name} changed after it was applied ` +
          `(recorded ${prev.checksum}, now ${m.checksum}). Applied migrations are ` +
          `immutable. Add a new numbered file instead of editing ${m.name}.`
        );
      }
      log(`  skip  ${m.name}  (applied ${new Date(prev.applied_at).toISOString()})`);
      continue;
    }

    log(`  run   ${m.name}`);
    await client.query('BEGIN');
    try {
      await client.query(m.sql);
      await client.query(
        'insert into schema_migrations (version, name, checksum) values ($1, $2, $3)',
        [m.version, m.name, m.checksum]
      );
      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw new Error(`${m.name} failed and was rolled back: ${err.message}`);
    }
    ran++;
  }
  return ran;
}

/**
 * Applies the shared seed.sql then every db/seed/*.sql content file, each in its
 * own transaction. Seeds are idempotent, so this is safe to re-run.
 */
async function runSeeds(client, seeds, { log = () => {} } = {}) {
  const files = [
    { name: 'seed.sql', sql: fs.readFileSync(path.join(DB_DIR, 'seed.sql'), 'utf8') },
    ...seeds,
  ];
  for (const f of files) {
    log(`  seed  ${f.name}`);
    await client.query('BEGIN');
    try {
      await client.query(f.sql);
      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw new Error(`${f.name} failed and was rolled back: ${err.message}`);
    }
  }
}

/**
 * A fresh database built from schema.sql is already at the latest schema, so
 * record every existing migration as applied. Without this the first
 * `db:migrate` on a fresh install would try to convert tables that were never
 * prototyped.
 */
async function baseline(client, migrations) {
  await ensureLedger(client);
  for (const m of migrations) {
    await client.query(
      'insert into schema_migrations (version, name, checksum) values ($1, $2, $3) ' +
      'on conflict (version) do nothing',
      [m.version, m.name, m.checksum]
    );
  }
}

/**
 * True when the database already contains learner accounts. Used to stop a
 * "fresh" setup or an empty ledger from replaying destructive early migrations
 * (002 truncates attempts/progress) over real data.
 */
async function hasLearnerData(client) {
  const table = await client.query("SELECT to_regclass('public.users') AS t");
  if (!table.rows[0] || !table.rows[0].t) return false;
  const result = await client.query('SELECT COUNT(*)::int AS n FROM users');
  return (result.rows[0] && result.rows[0].n) > 0;
}

async function main() {
  // node scripts/db-setup.js          fresh database   -> schema.sql + seed data, baselined
  // node scripts/db-setup.js migrate  existing schema   -> pending migrations only
  // node scripts/db-setup.js seed     (re)apply seed data only
  // node scripts/db-setup.js baseline record every migration as applied (repair a lost ledger)
  //
  // --force overrides the "this database already has learner data" guard. There
  // is deliberately no flag that drops the schema.
  const mode = ['migrate', 'seed', 'baseline'].includes(process.argv[2]) ? process.argv[2] : 'fresh';
  const force = process.argv.includes('--force');

  if (!process.env.DATABASE_URL) {
    console.error('DATABASE_URL is not set. Copy .env.example to .env and fill it in.');
    process.exit(1);
  }

  let client;
  try {
    client = await pool.connect();
    const populated = await hasLearnerData(client);

    // A fresh setup on a populated database used to re-run the seed files,
    // which deleted task options/activities and cascaded learner attempts away.
    if (mode === 'fresh' && populated && !force) {
      throw new Error(
        'This database already has learner data. Refusing to run a fresh setup. ' +
        'Use `npm run db:migrate` for schema changes, `npm run db:setup seed` to re-apply ' +
        'content (now non-destructive), or add --force if you really mean a fresh setup.',
      );
    }

    if (mode === 'migrate') {
      const migrations = listMigrations();
      await ensureLedger(client);
      const ledger = await client.query('SELECT COUNT(*)::int AS n FROM schema_migrations');
      const applied = (ledger.rows[0] && ledger.rows[0].n) || 0;

      // An empty ledger on a populated database means 001-0xx would replay.
      // 002 truncates progression tables, so refuse unless the operator
      // explicitly repairs or forces it.
      if (applied === 0 && populated && !force) {
        throw new Error(
          'This database has learner data but no migration ledger. Refusing to replay ' +
          'migrations from 001 (002 truncates attempts/progress). If the schema is known ' +
          'to be current, run `npm run db:baseline`; otherwise restore schema_migrations.',
        );
      }

      if (!migrations.length) {
        console.log('No migrations found in db/migrations.');
      } else {
        console.log(`Checking ${migrations.length} migration(s):`);
        const ran = await runMigrations(client, migrations, { log: console.log });
        console.log(ran ? `\n${ran} applied.` : '\nAlready up to date, nothing to run.');
      }
    } else if (mode === 'baseline') {
      const migrations = listMigrations();
      await baseline(client, migrations);
      console.log(`Recorded ${migrations.length} migration(s) as applied (schema assumed current).`);
    } else if (mode === 'seed') {
      console.log('Applying seed data:');
      await runSeeds(client, listSeeds(), { log: console.log });
      console.log('\nSeed data applied.');
    } else {
      process.stdout.write('  schema.sql ... ');
      await client.query(fs.readFileSync(path.join(DB_DIR, 'schema.sql'), 'utf8'));
      console.log('ok');
      console.log('Applying seed data:');
      await runSeeds(client, listSeeds(), { log: console.log });
      const migrations = listMigrations();
      await baseline(client, migrations);
      console.log(`Fresh database ready. ${migrations.length} migration(s) baselined as applied.`);
    }

    const { rows } = await client.query(
      "select table_name from information_schema.tables where table_schema = 'public' order by table_name"
    );
    console.log(`\n${rows.length} tables present:`);
    for (const row of rows) console.log(`  - ${row.table_name}`);
  } catch (err) {
    console.error(`\nFAILED: ${err.message}`);
    if (err.code === 'ENOTFOUND') {
      console.error('Check DATABASE_URL: the host is not a real hostname.');
    } else if (err.code === '28P01') {
      console.error('Check DATABASE_URL: the password was rejected.');
    } else if (err.code === 'ECONNREFUSED') {
      console.error('Check DATABASE_URL: wrong port, or the service is not running.');
    } else if (/certificate|self.signed|SSL/i.test(err.message)) {
      console.error('SSL negotiation failed. Railway public endpoints require SSL.');
    }
    process.exitCode = 1;
  } finally {
    if (client) client.release();
    await pool.end();
  }
}

if (require.main === module) main();

module.exports = { listMigrations, ensureLedger, runMigrations, baseline };
