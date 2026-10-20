require('dotenv').config();
const pool = require('../db/pool');

// Permanently removes journal entries that have sat in the trash for 30+ days.
//
// This used to run inline at the top of GET /api/wellness/journal, which meant a
// DELETE on every journal open (a scan, since the only index on the table is
// partial on `deleted_at IS NULL`). Run it on a schedule instead, e.g. a daily
// Render cron job or `pg_cron`:
//
//   0 3 * * *  cd backend && node scripts/purge-wellness-trash.js
const JOURNAL_TRASH_DAYS = 30;

async function main() {
  try {
    const result = await pool.query(
      `DELETE FROM wellness_journal_entries
       WHERE deleted_at IS NOT NULL
         AND deleted_at < now() - ($1::int * interval '1 day')`,
      [JOURNAL_TRASH_DAYS],
    );
    console.log(`Purged ${result.rowCount} journal entr${result.rowCount === 1 ? 'y' : 'ies'} older than ${JOURNAL_TRASH_DAYS} days.`);
  } catch (err) {
    console.error(`FAILED: ${err.message}`);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

if (require.main === module) main();
