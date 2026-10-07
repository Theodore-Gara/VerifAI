const assert = require('node:assert/strict');
const { test } = require('node:test');
const {
  normalize,
  extractKeywords,
  scoreAnswer,
  scoreOptions,
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
