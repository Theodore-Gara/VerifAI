const assert = require('node:assert/strict');
const { test } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const { awardAchievements } = require('../services/achievementsService');
const { awardXp } = require('../services/xpService');

function fakeClient({ earnedOnFirstQuery = [] } = {}) {
  const calls = [];
  let awardQueries = 0;
  return {
    calls,
    get awardQueries() { return awardQueries; },
    async query(sql, values = []) {
      const s = sql.replace(/\s+/g, ' ').trim();
      calls.push({ sql: s, values });
      if (s.startsWith('INSERT INTO user_progress') && s.includes('day_gap')) {
        return { rows: [{ id: 1, xp: 240, level: 4, streak: 6, last_activity_date: null, day_gap: null }] };
      }
      if (s.includes('UPDATE user_progress') && s.includes('SET xp')) {
        return { rows: [{ xp: 250, level: 5, streak: 7, last_activity_date: '2026-11-05', readiness_score: 0, tier: 'Novice', tokens: 5 }] };
      }
      if (s.includes('INSERT INTO user_achievements')) {
        awardQueries += 1;
        return { rows: awardQueries === 1 ? earnedOnFirstQuery : [] };
      }
      if (s.includes('INSERT INTO reward_token_events')) return { rows: [{ granted: 5 }] };
      return { rows: [] };
    },
  };
}

const AWARD = fakeClient();
const awardSql = () => {
  const call = AWARD.calls.find((entry) => entry.sql.includes('INSERT INTO user_achievements'));
  return call.sql;
};

test('awarding runs in one statement with every migrated code', async () => {
  await awardAchievements(AWARD, 7);
  const sql = awardSql();
  for (const code of ['track-master', 'xp-250', 'xp-1000', 'level-5', 'streak-7', 'first-task']) {
    assert.match(sql, new RegExp(`'${code}'`), `${code} is awardable`);
  }
  assert.match(sql, /NOT EXISTS/);
  assert.match(sql, /ON CONFLICT DO NOTHING/);
});

test('XP badges read user_progress, not SUM(task_attempts.xp_earned)', async () => {
  const sql = awardSql();
  assert.match(sql, /FROM user_progress WHERE user_id = \$1/);
  assert.doesNotMatch(sql, /SUM\(xp_earned\)/);
  assert.doesNotMatch(sql, /FROM users WHERE id = \$1\) >= 7/, 'streak lives on user_progress');
});

test('Track Master is scoped to the active track', async () => {
  const sql = awardSql();
  assert.match(sql, /t\.track_id = \(SELECT industry_track_id FROM users WHERE id = \$1\)/);
  assert.match(sql, /s\.track_passed >= s\.track_total/);
});

test('the catalog seed adds the former roadmap items idempotently', () => {
  const seed = fs.readFileSync(path.join(__dirname, '..', 'db', 'seed', '79_achievements.sql'), 'utf8');
  for (const code of ['first-task', 'streak-7', 'track-master', 'xp-250', 'xp-1000', 'level-5']) {
    assert.match(seed, new RegExp(`\\('${code}'`));
  }
  assert.match(seed, /ON CONFLICT \(code\) DO UPDATE/);
  assert.match(seed, /'First Steps'/);
  assert.match(seed, /'On Fire'/);
});

test('the XP/streak rollover awards achievements at the same moment', async () => {
  const client = fakeClient({
    earnedOnFirstQuery: [{ id: 9, code: 'level-5', name: 'Seasoned', description: 'Reach level 5.' }],
  });
  const progress = await awardXp(client, 7, 10);
  assert.equal(progress.xp, 250);
  assert.equal(progress.level, 5);
  assert.deepEqual(progress.achievements.map((a) => a.code), ['level-5']);
  assert.ok(client.calls.some((entry) => entry.sql.includes('INSERT INTO reward_token_events')), 'one token grant');
});
