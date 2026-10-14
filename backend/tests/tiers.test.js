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

test('refreshReadiness writes the live weighted score and its derived tier', async () => {
  const calls = [];
  const client = {
    async query(sql, values) {
      calls.push({ sql, values });
      if (sql.includes('FROM skill_scores')) {
        return { rows: [{ dimension: 'Verification', score: 80 }, { dimension: 'AI Judgement', score: 40 }] };
      }
      if (sql.includes('FROM interview_questions')) return { rows: [{ total: 0 }] };
      if (sql.includes('lab_capstone_attempts')) return { rows: [{ graded: 0, average: 0 }] };
      return { rows: [] };
    },
  };

  await refreshReadiness(client, 1, 1);
  const update = calls.find((c) => c.sql.includes('SET readiness_score'));
  // (0.3*80 + 0.3*40) / 0.6 = 60 -> Developing.
  assert.equal(update.values[0], 60);
  assert.equal(update.values[1], 'Developing');
  assert.equal(update.values[2], 1);
  // Live value: no monotonic guard, so a lower score can lower readiness+tier.
  assert.doesNotMatch(update.sql, /GREATEST/);
});
