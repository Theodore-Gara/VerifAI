const assert = require('node:assert/strict');
const { test } = require('node:test');
const { TIERS, tierForScore, nextTier } = require('../services/tiers');
const { refreshReadiness } = require('../services/readinessService');

test('tierForScore maps the readiness bands', () => {
  assert.equal(TIERS.map((t) => t.name).join(' > '), 'Novice > Developing > Proficient > Advanced');
  assert.equal(tierForScore(0), 'Novice');
  assert.equal(tierForScore(49), 'Novice');
  assert.equal(tierForScore(50), 'Developing');
  assert.equal(tierForScore(69), 'Developing');
  assert.equal(tierForScore(70), 'Proficient');
  assert.equal(tierForScore(84), 'Proficient');
  assert.equal(tierForScore(85), 'Advanced');
  assert.equal(tierForScore(100), 'Advanced');
});

test('tierForScore clamps out-of-range and invalid input', () => {
  assert.equal(tierForScore(-10), 'Novice');
  assert.equal(tierForScore(150), 'Advanced');
  assert.equal(tierForScore('nonsense'), 'Novice');
});

test('nextTier returns the next band and null at the top', () => {
  assert.equal(nextTier('Novice').name, 'Developing');
  assert.equal(nextTier('Proficient').name, 'Advanced');
  assert.equal(nextTier('Advanced'), null);
});

function fakeClient({ scores, offered = [], interview = { total: 0, practised: 0 }, learning = { offered: 0, average: 0 } }) {
  const calls = [];
  return {
    calls,
    async query(sql, values) {
      calls.push({ sql, values });
      if (sql.includes('FROM skill_scores')) return { rows: scores };
      if (sql.includes('GROUP BY feature')) return { rows: offered };
      if (sql.includes('FROM interview_questions')) return { rows: [interview] };
      if (sql.includes('lab_capstone_attempts')) return { rows: [learning] };
      return { rows: [] };
    },
  };
}

const writeOf = (client) => client.calls.find((c) => c.sql.includes('INSERT INTO user_progress'));

test('refreshReadiness writes the live weighted score and its derived tier', async () => {
  const client = fakeClient({
    scores: [{ dimension: 'Verification', score: 80 }, { dimension: 'AI Judgement', score: 40 }],
  });

  await refreshReadiness(client, 1, 1);
  const write = writeOf(client);
  // (0.3*80 + 0.3*40) / 0.6 = 60 -> Developing.
  assert.equal(write.values[1], 60);
  assert.equal(write.values[2], 'Developing');
  assert.equal(write.values[0], 1, 'user id');
  // Upsert: a learner with no user_progress row gets one instead of losing the
  // readiness to a no-op UPDATE.
  assert.match(write.sql, /ON CONFLICT \(user_id\) DO UPDATE/);
  // Live value: no monotonic guard, so a lower score can lower readiness+tier.
  assert.doesNotMatch(write.sql, /GREATEST/);
});

test('a module the track offers but the learner has not touched counts as zero', async () => {
  const client = fakeClient({
    // One module aced, one not attempted.
    scores: [{ dimension: 'Verification', score: 100 }],
    offered: [{ feature: 'verification', n: 4 }, { feature: 'risk_governance', n: 3 }],
  });
  await refreshReadiness(client, 1, 1);
  // (0.3*100 + 0.2*0) / 0.5 = 60 -> Developing, not 100/Advanced.
  assert.equal(writeOf(client).values[1], 60);
  assert.equal(writeOf(client).values[2], 'Developing');
});

test('modules a track does not offer are excluded from the denominator', async () => {
  const client = fakeClient({
    scores: [{ dimension: 'Verification', score: 100 }],
    offered: [{ feature: 'verification', n: 4 }],
  });
  await refreshReadiness(client, 1, 1);
  // The only offered module is aced: 0.3*100 / 0.3 = 100.
  assert.equal(writeOf(client).values[1], 100);
  assert.equal(writeOf(client).values[2], 'Advanced');
});
