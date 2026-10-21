const assert = require('node:assert/strict');
const { test } = require('node:test');
const {
  grantTokens,
  levelGrants,
  achievementGrants,
  XP_PER_LEVEL_TOKENS,
  TOKENS_PER_ACHIEVEMENT,
} = require('../services/rewardTokens');

test('levelGrants emits one grant per level gained, keyed by level', () => {
  assert.deepEqual(levelGrants(1, 3), [
    { delta: XP_PER_LEVEL_TOKENS, reason: 'level_up', ref: 'level-2' },
    { delta: XP_PER_LEVEL_TOKENS, reason: 'level_up', ref: 'level-3' },
  ]);
  assert.deepEqual(levelGrants(4, 4), []);
});

test('achievementGrants emits one grant per achievement, keyed by code', () => {
  assert.deepEqual(achievementGrants([{ code: 'first-task' }]), [
    { delta: TOKENS_PER_ACHIEVEMENT, reason: 'achievement', ref: 'first-task' },
  ]);
});

// The whole grant set is applied in one statement, so the fake database
// receives parallel delta/reason/ref arrays and reports the net total the
// UNIQUE(user_id, reason, ref) constraint allowed through.
function ledgerClient(existingRefs = []) {
  const calls = [];
  return {
    calls,
    async query(sql, values) {
      calls.push({ sql: sql.replace(/\s+/g, ' ').trim(), values });
      const [, deltas = [], , refs = []] = values;
      let granted = 0;
      refs.forEach((ref, index) => {
        if (!existingRefs.includes(ref)) granted += deltas[index];
      });
      return { rows: [{ granted }] };
    },
  };
}

test('grantTokens skips already-recorded refs and adds only the new total', async () => {
  // Simulate an existing ledger row for level-2 (idempotency).
  const client = ledgerClient(['level-2']);

  const granted = await grantTokens(client, 7, levelGrants(1, 4));

  assert.equal(granted, XP_PER_LEVEL_TOKENS * 2);
  assert.equal(client.calls.length, 1, 'one statement for the whole grant set');
  const [call] = client.calls;
  assert.deepEqual(call.values[1], [10, 10, 10]);
  assert.deepEqual(call.values[3], ['level-2', 'level-3', 'level-4']);
  assert.match(call.sql, /ON CONFLICT \(user_id, reason, ref\) DO NOTHING/);
  assert.match(call.sql, /UPDATE user_progress SET tokens = tokens \+/);
});

test('grantTokens makes no balance update when every grant is a duplicate', async () => {
  const client = ledgerClient(['level-2']);

  const granted = await grantTokens(client, 7, [{ delta: 10, reason: 'level_up', ref: 'level-2' }]);

  assert.equal(granted, 0);
  // The balance write is guarded inside the same statement.
  assert.match(client.calls[0].sql, /\(SELECT granted FROM total\) > 0/);
});
