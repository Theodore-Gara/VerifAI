const assert = require('node:assert/strict');
const { test } = require('node:test');

const { prune } = require('../scripts/prune-support');
const { RETENTION } = require('../services/supportLimits');

function executor(counts) {
  const log = [];
  return {
    log,
    async query(sql, values = []) {
      const s = sql.replace(/\s+/g, ' ').trim();
      log.push({ s, values });
      if (s.startsWith('SELECT COUNT(*)') && s.includes('support_messages')) return { rows: [{ n: counts.messages }] };
      if (s.startsWith('SELECT COUNT(*)') && s.includes('support_events')) return { rows: [{ n: counts.events }] };
      return { rows: [] };
    },
  };
}

test('retention defaults are 24 months for resolved messages and 12 for events', () => {
  assert.equal(RETENTION.resolvedMessageMonths, 24);
  assert.equal(RETENTION.eventMonths, 12);
});

test('dry run reports counts and deletes nothing', async () => {
  const exec = executor({ messages: 3, events: 40 });
  const out = [];
  const result = await prune({ executor: exec, log: (l) => out.push(l) });
  assert.deepEqual(result, { applied: false, counts: { messages: 3, events: 40 } });
  assert.ok(exec.log.every((c) => !c.s.startsWith('DELETE') && c.s !== 'BEGIN'));
  assert.ok(out.some((l) => /Dry run/.test(l)));
  assert.ok(out.some((l) => /: 3$/.test(l)) && out.some((l) => /: 40$/.test(l)));
});

test('--apply deletes in one transaction, only resolved messages, with the configured windows', async () => {
  const exec = executor({ messages: 1, events: 2 });
  const result = await prune({ apply: true, executor: exec, log: () => {} });
  assert.equal(result.applied, true);
  const statements = exec.log.map((c) => c.s);
  assert.deepEqual(statements.filter((s) => s === 'BEGIN' || s === 'COMMIT'), ['BEGIN', 'COMMIT']);
  const del = exec.log.find((c) => c.s.startsWith('DELETE FROM support_messages'));
  assert.match(del.s, /status = 'resolved'/);
  assert.match(del.s, /resolved_at IS NOT NULL/);
  assert.deepEqual(del.values, [24]);
  assert.deepEqual(exec.log.find((c) => c.s.startsWith('DELETE FROM support_events')).values, [12]);
});

test('a failed delete rolls back', async () => {
  const exec = executor({ messages: 1, events: 1 });
  const original = exec.query;
  exec.query = async (sql, values) => {
    if (sql.startsWith('DELETE FROM support_events')) throw new Error('nope');
    return original(sql, values);
  };
  await assert.rejects(() => prune({ apply: true, executor: exec, log: () => {} }), /nope/);
  assert.ok(exec.log.some((c) => c.s === 'ROLLBACK'));
});
