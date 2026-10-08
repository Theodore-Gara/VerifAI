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
