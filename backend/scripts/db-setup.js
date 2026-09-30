require('dotenv').config();

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const pool = require('../db/pool');

const DB_DIR = path.join(__dirname, '..', 'db');
const MIGRATIONS_DIR = path.join(DB_DIR, 'migrations');

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
      return {
        version: MIGRATION_FILE.exec(name)[1],
        name,
        sql,
        checksum: crypto.createHash('sha256').update(sql).digest('hex').slice(0, 16),
      };
    });

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
      if (prev.checksum !== m.checksum) {
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

async function main() {
  // node scripts/db-setup.js          fresh database   -> schema.sql + seed.sql, baselined
  // node scripts/db-setup.js migrate  existing schema   -> pending migrations only
  const mode = process.argv[2] === 'migrate' ? 'migrate' : 'fresh';

  if (!process.env.DATABASE_URL) {
    console.error('DATABASE_URL is not set. Copy .env.example to .env and fill it in.');
    process.exit(1);
  }

  let client;
  try {
    client = await pool.connect();

    if (mode === 'migrate') {
      const migrations = listMigrations();
      if (!migrations.length) {
        console.log('No migrations found in db/migrations.');
      } else {
        console.log(`Checking ${migrations.length} migration(s):`);
        const ran = await runMigrations(client, migrations, { log: console.log });
        console.log(ran ? `\n${ran} applied.` : '\nAlready up to date, nothing to run.');
      }
    } else {
      for (const file of ['schema.sql', 'seed.sql']) {
        process.stdout.write(`  ${file} ... `);
        await client.query(fs.readFileSync(path.join(DB_DIR, file), 'utf8'));
        console.log('ok');
      }
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
