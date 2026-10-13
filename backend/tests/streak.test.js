const assert = require('node:assert/strict');
const { test } = require('node:test');
const { computeStreak } = require('../services/streak');
const { awardXp } = require('../services/xpService');

test('computeStreak: first activity, same day, next day, and a missed day', async () => {
  assert.equal(await computeStreak({ query: async () => ({ rows: [] }) }, { last_activity_date: null }), 1);

  const client = (gap) => ({ query: async () => ({ rows: [{ day_gap: gap }] }) });
  assert.equal(await computeStreak(client(0), { id: 1, streak: 4, last_activity_date: '2026-10-13' }), 4);
  assert.equal(await computeStreak(client(1), { id: 1, streak: 4, last_activity_date: '2026-10-12' }), 5);
  assert.equal(await computeStreak(client(3), { id: 1, streak: 4, last_activity_date: '2026-10-10' }), 1);
});

test('awardXp advances the streak and credits tokens for a level gained', async () => {
  const calls = [];
  const client = {
    async query(sql) {
      calls.push(sql.replace(/\s+/g, ' ').trim());
      if (sql.startsWith('INSERT INTO user_progress')) {
        return { rows: [{ id: 1, xp: 240, level: 1, streak: 2, last_activity_date: '2026-10-12' }] };
      }
      if (sql.includes('UPDATE user_progress') && sql.includes('SET xp')) {
        return { rows: [{ xp: 310, level: 2, streak: 3, tokens: 10 }] };
      }
      if (sql.includes('SELECT (NOW() AT TIME ZONE')) return { rows: [{ day_gap: 1 }] };
      if (sql.startsWith('INSERT INTO reward_token_events')) return { rowCount: 1, rows: [] };
      if (sql.includes('UPDATE user_progress') && sql.includes('SET tokens')) return { rowCount: 1, rows: [] };
      return { rows: [] };
    },
  };

  const result = await awardXp(client, 7, 70);
  assert.equal(result.xp_earned, 70);
  assert.equal(result.streak, 3);
  assert.equal(result.tokens, 10);
});
