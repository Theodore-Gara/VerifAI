const assert = require('node:assert/strict');
const { test } = require('node:test');
const { webSearch } = require('../services/tavily');

test('webSearch returns an empty list without a key', async () => {
  const previous = process.env.TAVILY_API_KEY;
  delete process.env.TAVILY_API_KEY;
  try {
    assert.deepEqual(await webSearch('anything'), []);
  } finally {
    if (previous !== undefined) process.env.TAVILY_API_KEY = previous;
  }
});

test('webSearch maps Tavily results and tolerates failures', async () => {
  process.env.TAVILY_API_KEY = 'test-key';
  try {
    const results = await webSearch('q', {
      fetchImpl: async () => ({ ok: true, json: async () => ({ results: [{ title: 'T', url: 'https://u', content: 'c' }] }) }),
    });
    assert.equal(results.length, 1);
    assert.equal(results[0].title, 'T');

    const failed = await webSearch('q', { fetchImpl: async () => ({ ok: false }) });
    assert.deepEqual(failed, []);

    const thrown = await webSearch('q', { fetchImpl: async () => { throw new Error('network'); } });
    assert.deepEqual(thrown, []);
  } finally {
    delete process.env.TAVILY_API_KEY;
  }
});
