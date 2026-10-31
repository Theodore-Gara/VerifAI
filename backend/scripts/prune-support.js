require('dotenv').config();
const pool = require('../db/pool');
const { RETENTION } = require('../services/supportLimits');

// Retention for support data (policy in the README):
//   - support_messages that were resolved more than 24 months ago
//   - support_events older than 12 months
// Unresolved messages are never pruned. Dry run by default, like
// recompute-readiness.js: it reports counts and deletes only with --apply.
//
//   node scripts/prune-support.js           report only
//   node scripts/prune-support.js --apply   delete
async function prune({ apply = false, executor = pool, log = console.log } = {}) {
  const messagesSql = `resolved_at IS NOT NULL AND status = 'resolved'
                       AND resolved_at < now() - ($1::int * interval '1 month')`;
  const eventsSql = `created_at < now() - ($1::int * interval '1 month')`;

  const counts = {
    messages: Number((await executor.query(
      `SELECT COUNT(*)::int AS n FROM support_messages WHERE ${messagesSql}`,
      [RETENTION.resolvedMessageMonths])).rows[0]?.n) || 0,
    events: Number((await executor.query(
      `SELECT COUNT(*)::int AS n FROM support_events WHERE ${eventsSql}`,
      [RETENTION.eventMonths])).rows[0]?.n) || 0,
  };

  log(`Resolved messages older than ${RETENTION.resolvedMessageMonths} months: ${counts.messages}`);
  log(`Events older than ${RETENTION.eventMonths} months: ${counts.events}`);

  if (!apply) {
    log('Dry run: nothing deleted. Re-run with --apply to delete.');
    return { applied: false, counts };
  }

  await executor.query('BEGIN');
  try {
    await executor.query(`DELETE FROM support_messages WHERE ${messagesSql}`, [RETENTION.resolvedMessageMonths]);
    await executor.query(`DELETE FROM support_events WHERE ${eventsSql}`, [RETENTION.eventMonths]);
    await executor.query('COMMIT');
  } catch (err) {
    await executor.query('ROLLBACK').catch(() => {});
    throw err;
  }
  log('Deleted.');
  return { applied: true, counts };
}

async function main() {
  const apply = process.argv.includes('--apply');
  const client = await pool.connect();
  try {
    await prune({ apply, executor: client });
  } catch (err) {
    console.error(`FAILED: ${err.message}`);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

if (require.main === module) main();

module.exports = { prune };
