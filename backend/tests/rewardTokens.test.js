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

test('grantTokens skips already-recorded refs and adds only the new total', async () => {
  const calls = [];
  const client = {
    async query(sql, values) {
      calls.push({ sql: sql.replace(/\s+/g, ' ').trim(), values });
      if (sql.startsWith('INSERT INTO reward_token_events')) {
        // Simulate an existing ledger row for level-2 (idempotency).
        return { rowCount: values[3] === 'level-2' ? 0 : 1 };
      }
      return { rowCount: 1 };
    },
  };

  const granted = await grantTokens(client, 7, levelGrants(1, 4));

  assert.equal(granted, XP_PER_LEVEL_TOKENS * 2);
  const update = calls.find((c) => c.sql.startsWith('UPDATE user_progress SET tokens'));
  assert.deepEqual(update.values, [XP_PER_LEVEL_TOKENS * 2, 7]);
});

test('grantTokens makes no balance update when every grant is a duplicate', async () => {
  const calls = [];
  const client = {
    async query(sql, values) {
      calls.push({ sql, values });
      return { rowCount: 0 };
    },
  };

  const granted = await grantTokens(client, 7, [{ delta: 10, reason: 'level_up', ref: 'level-2' }]);

  assert.equal(granted, 0);
  assert.equal(calls.some((c) => c.sql.startsWith('UPDATE user_progress SET tokens')), false);
});
