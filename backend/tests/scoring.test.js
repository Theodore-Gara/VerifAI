const assert = require('node:assert/strict');
const { test } = require('node:test');
const {
  normalize,
  extractKeywords,
  scoreAnswer,
  calculateXp,
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

test('calculates bounded XP', () => {
  assert.equal(calculateXp(0), 20);
  assert.equal(calculateXp(100), 70);
});

test('levels increase every 250 XP', () => {
  assert.equal(calculateLevel(0), 1);
  assert.equal(calculateLevel(249), 1);
  assert.equal(calculateLevel(250), 2);
  assert.equal(calculateLevel(500), 3);
});
