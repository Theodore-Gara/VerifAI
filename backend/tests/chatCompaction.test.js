const assert = require('node:assert/strict');
const { test } = require('node:test');
const {
  estimateTokens,
  estimateMessagesTokens,
  systemWithSummary,
  assembleContext,
  shouldCompact,
} = require('../services/chatCompaction');

test('estimateTokens approximates ~4 characters per token', () => {
  assert.equal(estimateTokens(''), 0);
  assert.equal(estimateTokens(null), 0);
  assert.equal(estimateTokens('abcd'), 1);
  assert.equal(estimateTokens('abcde'), 2);
});

test('systemWithSummary folds the running summary into the system prompt', () => {
  assert.equal(systemWithSummary('SYS', ''), 'SYS');
  const withSummary = systemWithSummary('SYS', 'the learner wants to pass finance');
  assert.match(withSummary, /^SYS/);
  assert.match(withSummary, /the learner wants to pass finance/);
});

test('assembleContext puts the system first and includes the recent turns', () => {
  const messages = assembleContext({
    system: 'SYS',
    summary: 'earlier stuff',
    recent: [{ role: 'user', content: 'hi' }],
    budget: 100000,
    reserve: 0,
  });
  assert.equal(messages[0].role, 'system');
  assert.match(messages[0].content, /SYS/);
  assert.match(messages[0].content, /earlier stuff/);
  assert.deepEqual(messages.slice(1), [{ role: 'user', content: 'hi' }]);
});

test('assembleContext trims the oldest recent turns to fit the budget', () => {
  const recent = Array.from({ length: 10 }, (_, i) => ({
    role: i % 2 ? 'assistant' : 'user',
    content: 'x'.repeat(400),
  }));
  const messages = assembleContext({ system: 'S', summary: '', recent, budget: 350, reserve: 0 });
  assert.ok(estimateMessagesTokens(messages) <= 350);
  assert.ok(messages.length < recent.length + 1, 'some oldest turns are dropped');
  assert.equal(messages[messages.length - 1].content, recent[recent.length - 1].content);
});

test('shouldCompact fires at the threshold of the budget', () => {
  const recent = [{ role: 'user', content: 'x'.repeat(4000) }]; // ~1000 tokens
  assert.equal(shouldCompact({ system: 'S', summary: '', recent, budget: 1100, threshold: 0.9 }), true);
  assert.equal(shouldCompact({ system: 'S', summary: '', recent, budget: 5000, threshold: 0.9 }), false);
});
