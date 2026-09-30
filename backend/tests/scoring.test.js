const {
  normalize,
  extractKeywords,
  scoreAnswer,
  calculateXp,
  calculateLevel,
} = require('../services/scoringService');

describe('scoringService', () => {
  test('normalizes punctuation and whitespace', () => {
    expect(normalize('  Verify, the SOURCE!  ')).toBe('verify the source');
  });

  test('extracts unique meaningful keywords', () => {
    expect(extractKeywords('Keywords: verify source records, correct the payment, review evidence.'))
      .toEqual(expect.arrayContaining(['verify', 'source', 'records', 'correct', 'payment', 'review', 'evidence']));
  });

  test('scores a strongly matching answer highly', () => {
    const result = scoreAnswer(
      'I would verify the source records, correct the payment and review the evidence before relying on the result.',
      'Keywords: verify source records, correct the payment, review evidence.'
    );
    expect(result.score).toBeGreaterThanOrEqual(80);
    expect(result.passed).toBe(true);
  });

  test('gives partial credit when only some concepts are present', () => {
    const result = scoreAnswer(
      'I would verify the source records.',
      'Keywords: verify source records, correct the payment, review evidence.'
    );
    expect(result.score).toBeGreaterThan(0);
    expect(result.score).toBeLessThan(100);
    expect(result.missedKeywords.length).toBeGreaterThan(0);
  });

  test('returns zero for an empty answer', () => {
    expect(scoreAnswer('', 'Keywords: verify source records.').score).toBe(0);
  });

  test('calculates bounded XP', () => {
    expect(calculateXp(0)).toBe(20);
    expect(calculateXp(100)).toBe(70);
  });

  test('levels increase every 250 XP', () => {
    expect(calculateLevel(0)).toBe(1);
    expect(calculateLevel(249)).toBe(1);
    expect(calculateLevel(250)).toBe(2);
    expect(calculateLevel(500)).toBe(3);
  });
});
