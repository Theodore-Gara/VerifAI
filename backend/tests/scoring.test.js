const assert = require('node:assert/strict');
const { test } = require('node:test');
const {
  normalize,
  extractKeywords,
  scoreAnswer,
  scoreOptions,
  scoreCriteria,
  scoreFlawLines,
  FIX_POINTS,
  REASON_POINTS,
  calculateXp,
  calculatePracticeXp,
  xpForLevel,
  calculateLevel,
} = require('../services/scoringService');

test('normalizes punctuation and whitespace', () => {
  assert.equal(normalize('  Verify, the SOURCE!  '), 'verify the source');
});

test('extracts unique meaningful keywords', () => {
  const keywords = extractKeywords('Keywords: verify source records, correct the payment, review evidence.');
  for (const keyword of ['verify', 'source', 'records', 'correct', 'payment', 'review', 'evidence']) {
    assert.ok(keywords.includes(keyword));
  }
});

test('scores a strongly matching answer highly', () => {
  const result = scoreAnswer(
    'I would verify the source records, correct the payment and review the evidence before relying on the result.',
    'Keywords: verify source records, correct the payment, review evidence.'
  );
  assert.ok(result.score >= 80);
  assert.equal(result.passed, true);
});

test('gives partial credit when only some concepts are present', () => {
  const result = scoreAnswer(
    'I would verify the source records.',
    'Keywords: verify source records, correct the payment, review evidence.'
  );
  assert.ok(result.score > 0);
  assert.ok(result.score < 100);
  assert.ok(result.missedKeywords.length > 0);
});

test('returns zero for an empty answer', () => {
  assert.equal(scoreAnswer('', 'Keywords: verify source records.').score, 0);
});

test('sums selected option weights and clamps to 100', () => {
  assert.equal(scoreOptions([100]), 100);
  assert.equal(scoreOptions([50, 50]), 100);
  assert.equal(scoreOptions([25, 50]), 75);
  assert.equal(scoreOptions([0, 0]), 0);
});

test('awards no XP for a wrong answer', () => {
  assert.equal(calculateXp(0), 0);
  assert.equal(calculateXp(0, 'hard'), 0);
});

test('scales XP by score and difficulty', () => {
  assert.equal(calculateXp(100, 'medium'), 70);
  assert.equal(calculateXp(100, 'easy'), 50);
  assert.equal(calculateXp(100, 'hard'), 100);
  assert.equal(calculateXp(50, 'medium'), 35); // e.g. R&G partial
  assert.equal(calculateXp(25, 'medium'), 18); // e.g. Judgement neighbour
});

test('a practice pass earns half the XP', () => {
  assert.equal(calculatePracticeXp(100, 'hard'), 50); // full pass would be 100
  assert.equal(calculatePracticeXp(100, 'medium'), 35);
  assert.equal(calculatePracticeXp(100, 'easy'), 25);
  assert.equal(calculatePracticeXp(58, 'hard'), 29); // text task scoring 58
  assert.equal(calculatePracticeXp(0, 'hard'), 0);
});

test('level thresholds rise by 60 XP each level', () => {
  assert.equal(xpForLevel(1), 0);
  assert.equal(xpForLevel(2), 250);
  assert.equal(xpForLevel(3), 560);
  assert.equal(xpForLevel(4), 930);
});

test('calculateLevel follows the rising curve', () => {
  assert.equal(calculateLevel(0), 1);
  assert.equal(calculateLevel(249), 1);
  assert.equal(calculateLevel(250), 2);
  assert.equal(calculateLevel(559), 2);
  assert.equal(calculateLevel(560), 3);
  assert.equal(calculateLevel(929), 3);
  assert.equal(calculateLevel(930), 4);
});

test('flaw scoring is an exact line-set match (order-insensitive)', () => {
  assert.equal(scoreFlawLines([8, 9], [8, 9]), 30);
  assert.equal(scoreFlawLines([9, 8], [8, 9]), 30);
  assert.equal(scoreFlawLines([8, 9, 9], [8, 9]), 30);
  assert.equal(scoreFlawLines([8], [8, 9]), 0);
  assert.equal(scoreFlawLines([8, 9, 10], [8, 9]), 0);
  assert.equal(scoreFlawLines([], [8, 9]), 0);
});

test('criteria scoring is proportional and synonym/prefix aware', () => {
  const criteria = ['deduct|less|subtract', '84,900|84900', 'reconcil'];
  const full = scoreCriteria(
    'Deduct R6,200 so the reconciliation balances at 84900',
    criteria,
    FIX_POINTS
  );
  assert.equal(full.matched, 3);
  assert.equal(full.score, FIX_POINTS);

  const partial = scoreCriteria('I would subtract it', criteria, FIX_POINTS);
  assert.equal(partial.matched, 1);
  assert.equal(partial.score, Math.round(FIX_POINTS / 3));

  const none = scoreCriteria('no idea', criteria, REASON_POINTS);
  assert.equal(none.matched, 0);
  assert.equal(none.score, 0);
});

test('negated criteria do not count as matched', () => {
  const criteria = ['anonymise|anonymization', 'verify|verification'];

  // Positive answers still match.
  const positive = scoreCriteria('I would anonymise the data and verify the totals', criteria, REASON_POINTS);
  assert.equal(positive.matched, 2);

  // Negated usage must NOT count (SCORING_REVIEW §3.1).
  const negated = scoreCriteria('I will not anonymise the data', criteria, REASON_POINTS);
  assert.equal(negated.matched, 0);
  assert.equal(negated.score, 0);

  // A negation more than 3 tokens before the criterion does not block it.
  const distant = scoreCriteria(
    'Never assume anything. The first step is to verify the totals.',
    criteria,
    REASON_POINTS
  );
  assert.equal(distant.matched, 1);
});

test('not only does not negate criteria or free-text keywords', () => {
  const criteria = scoreCriteria(
    'I would not only anonymise the data, but also verify the totals',
    ['anonymise', 'verify'],
    REASON_POINTS
  );
  assert.equal(criteria.matched, 2);

  const negated = scoreAnswer('I will not anonymise data', 'Keywords: anonymise data');
  assert.equal(negated.score, 0);
  assert.equal(negated.passed, false);

  const positive = scoreAnswer(
    'I would not only anonymise the data, but also verify the source',
    'Keywords: anonymise data verify source'
  );
  assert.equal(positive.score, 100);
  assert.equal(positive.passed, true);
});

test('compact matching only applies to numbers, not short words', () => {
  // Numeric variants still match after separator stripping.
  const numbers = scoreCriteria('The balance is 1860 units', ['1,860|1860'], FIX_POINTS);
  assert.equal(numbers.matched, 1);

  // A short non-numeric variant must not falsely match mid-word in a longer token
  // ('gen' is too short for the prefix-stem rule, and compact matching no longer
  // applies to words).
  const words = scoreCriteria('a generic passphrase example', ['gen'], FIX_POINTS);
  assert.equal(words.matched, 0);
});

// ---------------------------------------------------------------------------
// Feature-scoring paths (scoreByFeature) — AJ-B6 / RG-B2.
// ---------------------------------------------------------------------------
const { scoreByFeature } = require('../controllers/tasksController');

const JUDGEMENT_CONTENT = {
  decisions: [
    { id: 11, score: 50 },
    { id: 12, score: 25 },
    { id: 13, score: 0 },
  ],
  reasons: [
    { id: 14, score: 50 },
    { id: 15, score: 0 },
    { id: 16, score: 0 },
  ],
};

test('AI Judgement scoring sums the decision and reason weights', () => {
  assert.equal(scoreByFeature('judgement', JUDGEMENT_CONTENT, { decision_option_id: 11, reason_option_id: 14 }).score, 100);
  assert.equal(scoreByFeature('judgement', JUDGEMENT_CONTENT, { decision_option_id: 12, reason_option_id: 14 }).score, 75);
  assert.equal(scoreByFeature('judgement', JUDGEMENT_CONTENT, { decision_option_id: 13, reason_option_id: 15 }).score, 0);
});

test('Risk & Governance scoring uses the 2-option decision with the same reason bank', () => {
  const rg = {
    decisions: [
      { id: 21, score: 50 },
      { id: 22, score: 0 },
    ],
    reasons: JUDGEMENT_CONTENT.reasons,
  };
  assert.equal(scoreByFeature('risk_governance', rg, { decision_option_id: 21, reason_option_id: 14 }).score, 100);
  assert.equal(scoreByFeature('risk_governance', rg, { decision_option_id: 21, reason_option_id: 16 }).score, 50);
  assert.equal(scoreByFeature('risk_governance', rg, { decision_option_id: 22, reason_option_id: 14 }).score, 50);
  assert.equal(scoreByFeature('risk_governance', rg, { decision_option_id: 22, reason_option_id: 15 }).score, 0);
});

test('scoring rejects option ids that do not belong to the task', () => {
  assert.throws(() => scoreByFeature('judgement', JUDGEMENT_CONTENT, { decision_option_id: 999, reason_option_id: 14 }), /decision/);
  assert.throws(() => scoreByFeature('judgement', JUDGEMENT_CONTENT, { decision_option_id: 11, reason_option_id: 999 }), /reason/);
  assert.throws(() => scoreByFeature('judgement', JUDGEMENT_CONTENT, { reason_option_id: 14 }), /decision/);
});

test('verification choice scoring is all-or-nothing', () => {
  const content = { format: 'choice', options: [{ id: 31, score: 100 }, { id: 32, score: 0 }] };
  assert.equal(scoreByFeature('verification', content, { answer_option_id: 31 }).score, 100);
  assert.equal(scoreByFeature('verification', content, { answer_option_id: 32 }).score, 0);
  assert.throws(() => scoreByFeature('verification', content, {}), /answer option/);
  assert.throws(() => scoreByFeature('verification', content, { answer_option_id: 41 }), /does not belong/);
});

// ---------------------------------------------------------------------------
// Streak + level bookkeeping now lives in services/xpService.awardXp.
// ---------------------------------------------------------------------------
const { awardXp } = require('../services/xpService');

const PROGRESS_ROW = { id: 1, xp: 20, level: 1, streak: 1, last_activity_date: '2026-10-08' };

function fakeProgressClient(dayGap) {
  const calls = [];
  return {
    calls,
    async query(sql, values) {
      calls.push({ sql, values });
      if (sql.includes('INSERT INTO user_progress')) return { rows: [PROGRESS_ROW] };
      if (sql.includes('day_gap')) return { rows: [{ today: '2026-10-09', day_gap: dayGap }] };
      if (sql.includes('INSERT INTO reward_token_events')) return { rows: [] };
      if (sql.includes('UPDATE user_progress') && sql.includes('SET xp')) {
        return { rows: [{ xp: 70, level: 1, streak: 2, readiness_score: 0, tier: 'Novice', tokens: 0 }] };
      }
      return { rows: [] };
    },
  };
}

const updateOf = (fake) => fake.calls.find((call) => call.sql.includes('SET xp'));

test('streak increments on a 1-day gap and pins the timezone, not the server clock', async () => {
  const fake = fakeProgressClient(1);
  await awardXp(fake, 7, 50);

  const gapCall = fake.calls.find((call) => call.sql.includes('day_gap'));
  const update = updateOf(fake);
  // Both the gap lookup and the stored activity date must use the configured
  // timezone (parameterised), never the database server's CURRENT_DATE.
  assert.match(gapCall.sql, /AT TIME ZONE \$2/);
  assert.match(update.sql, /AT TIME ZONE \$5/);
  assert.doesNotMatch(update.sql, /last_activity_date = CURRENT_DATE/);
  assert.deepEqual(gapCall.values, [1, process.env.STREAK_TIMEZONE || 'Africa/Johannesburg']);
  assert.equal(update.values[4], process.env.STREAK_TIMEZONE || 'Africa/Johannesburg');
  // 1-day gap -> streak advances; 20 + 50 XP.
  assert.equal(update.values[0], 70);
  assert.equal(update.values[2], 2);
});

test('streak holds on a same-day gap and resets after a missed day', async () => {
  const sameDay = fakeProgressClient(0);
  await awardXp(sameDay, 7, 10);
  assert.equal(updateOf(sameDay).values[2], 1);

  const missed = fakeProgressClient(5);
  await awardXp(missed, 7, 10);
  assert.equal(updateOf(missed).values[2], 1);
});

test('a zero-XP graded attempt still marks the day active', async () => {
  const fake = fakeProgressClient(1);
  const row = await awardXp(fake, 7, 0);
  assert.equal(row.xp_earned, 0);
  assert.equal(updateOf(fake).values[0], 20, 'XP balance is untouched');
  assert.equal(updateOf(fake).values[2], 2, 'streak still advances');
});

test('an admin adjustment does not fabricate a streak', async () => {
  const fake = fakeProgressClient(1);
  await awardXp(fake, 7, 500, { advanceStreak: false });
  assert.equal(updateOf(fake).values[5], false, 'advanceStreak flag reaches the UPDATE');
  assert.equal(updateOf(fake).values[2], 1, 'streak is carried over');
});

test('crossing a level boundary levels up and credits level tokens', async () => {
  const fake = {
    calls: [],
    async query(sql, values) {
      this.calls.push({ sql, values });
      if (sql.includes('INSERT INTO user_progress')) {
        return { rows: [{ id: 1, xp: 240, level: 1, streak: 1, last_activity_date: '2026-10-08' }] };
      }
      if (sql.includes('day_gap')) return { rows: [{ day_gap: 0 }] };
      if (sql.includes('INSERT INTO reward_token_events')) return { rows: [] };
      if (sql.includes('UPDATE user_progress') && sql.includes('SET xp')) {
        return { rows: [{ xp: 260, level: 2, streak: 1, readiness_score: 0, tier: 'Novice', tokens: 5 }] };
      }
      return { rows: [] };
    },
  };
  await awardXp(fake, 7, 20);
  assert.equal(xpForLevel(2), 250);
  assert.equal(calculateLevel(260), 2);
  assert.equal(updateOf(fake).values[1], 2, 'level recomputed from the new balance');
  assert.ok(
    fake.calls.some((call) => call.sql.includes('INSERT INTO reward_token_events')),
    'level-up credits reward tokens',
  );
});

// ---------------------------------------------------------------------------
// Verification pass rules (§3.1): a reason alone must not pass a line_text task.
// ---------------------------------------------------------------------------
const { isPass } = require('../controllers/tasksController');

test('line_text verification requires a flaw and a fix, not just a reason', () => {
  // Flawed lines picked (30) + a plausible reason (30), nothing fixed: the old
  // flat 60 threshold passed this. It must not.
  assert.equal(isPass('verification', { format: 'line_text', score: 60, flawScore: 30, fixScore: 0 }), false);
  // Fix and flaw, no reason: 70 total is a pass (the fix is the skill).
  assert.equal(isPass('verification', { format: 'line_text', score: 70, flawScore: 30, fixScore: 40 }), true);
  // No flaw found, however good the fix: not a pass.
  assert.equal(isPass('verification', { format: 'line_text', score: 70, flawScore: 0, fixScore: 40 }), false);
  // Choice tasks keep the plain threshold.
  assert.equal(isPass('verification', { format: 'choice', score: 60 }), true);
  assert.equal(isPass('verification', { format: 'choice', score: 40 }), false);
});
