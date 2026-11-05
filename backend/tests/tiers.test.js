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

function fakeClient({ scores, offered = [], interview = { total: 0, practised: 0 }, learning = { offered: 0, average: 0 }, currentBest = null }) {
  const calls = [];
  return {
    calls,
    async query(sql, values) {
      calls.push({ sql, values });
      // Readiness inputs now arrive as one row of JSON aggregates.
      if (sql.includes('readiness_inputs')) {
        return {
          rows: [{
            scores,
            available: offered.map((row) => ({ feature: row.feature })),
            capstone_offered: learning.offered,
            capstone_average: learning.average,
            interview_practised: interview.practised,
            tasks_completed: 2,
            current_readiness: null,
            current_best: currentBest,
            last_activity_date: null,
            active_track_id: 1,
          }],
        };
      }
      if (sql.includes('FROM interview_questions')) return { rows: [{ total: interview.total }] };
      return { rows: [] };
    },
  };
}

const writeOf = (client) => client.calls.find((c) => c.sql.includes('INSERT INTO user_track_progress'));

test('refreshReadiness writes the live weighted score and its derived tier', async () => {
  const client = fakeClient({
    scores: [{ dimension: 'Verification', score: 80 }, { dimension: 'AI Judgement', score: 40 }],
  });

  await refreshReadiness(client, 1, 1);
  const write = writeOf(client);
  // (0.3*80 + 0.3*40) / 0.6 = 60 -> Developing. Values: user, track, score, best, tier.
  assert.equal(write.values[2], 60);
  assert.equal(write.values[4], 'Developing');
  assert.equal(write.values[0], 1, 'user id');
  assert.equal(write.values[1], 1, 'track id');
  assert.match(write.sql, /ON CONFLICT \(user_id, track_id\) DO UPDATE/);
  // Live value can fall; the best-ever value used by the roadmap cannot.
  assert.match(write.sql, /GREATEST\(user_track_progress\.readiness_best, EXCLUDED\.readiness_best\)/);
});

test('a module the track offers but the learner has not touched counts as zero', async () => {
  const client = fakeClient({
    // One module aced, one not attempted.
    scores: [{ dimension: 'Verification', score: 100 }],
    offered: [{ feature: 'verification', n: 4 }, { feature: 'risk_governance', n: 3 }],
  });
  await refreshReadiness(client, 1, 1);
  // (0.3*100 + 0.2*0) / 0.5 = 60 -> Developing, not 100/Advanced.
  assert.equal(writeOf(client).values[2], 60);
  assert.equal(writeOf(client).values[4], 'Developing');
});

test('modules a track does not offer are excluded from the denominator', async () => {
  const client = fakeClient({
    scores: [{ dimension: 'Verification', score: 100 }],
    offered: [{ feature: 'verification', n: 4 }],
  });
  await refreshReadiness(client, 1, 1);
  // The only offered module is aced: 0.3*100 / 0.3 = 100.
  assert.equal(writeOf(client).values[2], 100);
  assert.equal(writeOf(client).values[4], 'Advanced');
});

test('a lower live score never lowers the best-ever readiness', async () => {
  const client = fakeClient({
    scores: [{ dimension: 'Verification', score: 40 }],
    offered: [{ feature: 'verification', n: 4 }],
    currentBest: 72,
  });
  const readiness = await refreshReadiness(client, 1, 1);
  assert.equal(readiness, 40);
  assert.equal(writeOf(client).values[3], 72, 'readiness_best keeps the high-water mark');
});
