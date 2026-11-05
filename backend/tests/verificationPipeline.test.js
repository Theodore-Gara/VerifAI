const assert = require('node:assert/strict');
const { test } = require('node:test');
const {
  chunkMaterial, selectWindows, fallbackClaims, extractClaims, searchClaims, judgeClaims,
} = require('../services/verification/claims');

test('page-aware chunking keeps page markers and samples the whole document', () => {
  const pages = Array.from({ length: 30 }, (_, i) => {
    const n = i + 1;
    return `[page ${n}]\n${`Page ${n} text. `.repeat(220)}`;
  }).join('\n');
  const windows = chunkMaterial(pages);
  assert.equal(windows.length, 30);
  assert.equal(windows[0].page, 1);
  assert.equal(windows.at(-1).page, 30);

  const sampled = selectWindows(windows, 6);
  assert.equal(sampled.length, 6);
  assert.equal(sampled[0].page, 1);
  assert.equal(sampled.at(-1).page, 30, 'the last page is represented, not only the first 60k');
});

test('the deterministic fallback finds checkable sentences', () => {
  const claims = fallbackClaims([{
    page: 2,
    text: 'The report says load shedding cost R300bn in 2023. Some other prose here.',
  }]);
  assert.ok(claims.length >= 1);
  assert.equal(claims[0].page, 2);
  assert.match(claims[0].text, /R300bn/);
});

test('extractClaims asks for claims and keeps page numbers', async () => {
  let prompt = '';
  const claims = await extractClaims({
    material: '[page 7]\nRevenue grew 15% in 2024, according to the annual report.',
    complete: async ({ system, user, profile }) => {
      prompt = user;
      assert.equal(profile, 'claims');
      assert.match(system, /factual claims/i);
      return {
        content: JSON.stringify({ claims: [{ text: 'Revenue grew 15% in 2024.', page: 7, kind: 'statistic' }] }),
      };
    },
  });
  assert.equal(claims.length, 1);
  assert.equal(claims[0].page, 7);
  assert.match(prompt, /\[page 7\]/);
});

test('a paraphrased document claim is still attributed to its page', async () => {
  const claims = await extractClaims({
    material: '[page 4]\nThe audit found that procurement spending rose sharply in 2023, the report says.',
    complete: async () => ({
      content: JSON.stringify({ claims: [{ text: 'Procurement spending rose sharply in 2023.', page: null, kind: 'statistic' }] }),
    }),
  });
  assert.equal(claims.length, 1);
  assert.equal(claims[0].page, 4);
});

test('a model failure falls back deterministically instead of failing the request', async () => {
  const claims = await extractClaims({
    material: 'The company lost R12 million in 2023, the filing shows. Another sentence.',
    complete: async () => { throw new Error('upstream down'); },
  });
  assert.ok(claims.length >= 1);
  assert.match(claims[0].text, /R12 million/);
});

test('searches are capped, sequential and de-duplicated by URL', async () => {
  const calls = [];
  const source = { title: 'One source', url: 'https://example.org/one', content: 'evidence' };
  const claims = [
    { text: 'Revenue grew 15%.', page: 1, kind: 'statistic' },
    { text: 'Costs fell 4%.', page: 2, kind: 'statistic' },
  ];
  const result = await searchClaims(claims, {
    search: async (query, options) => {
      calls.push({ query, options });
      return [source];
    },
  });

  assert.equal(calls.length, 2);
  assert.ok(calls.every((call) => call.options.maxResults === 3));
  assert.equal(result.sources.length, 1, 'one URL is cited once');
  assert.equal(result.claims[0].evidence[0].url, source.url);
  assert.equal(result.claims[1].evidence[0].url, source.url);
});

test('the search fan-out stops at the wall-clock budget', async () => {
  let time = 0;
  let calls = 0;
  const claims = [
    { text: 'First claim.', page: 1 },
    { text: 'Second claim.', page: 2 },
  ];
  await searchClaims(claims, {
    clock: () => time,
    budgetMs: 20000,
    search: async () => {
      calls += 1;
      time += 30000;
      return [];
    },
  });
  assert.equal(calls, 1, 'no search starts after the budget is spent');
});

test('a fenced verdict reply is accepted', async () => {
  const claims = [{
    text: 'Revenue grew 15%.', page: 1, kind: 'statistic',
    evidence: [{ title: 'S', url: 'https://example.org/s', content: 'It grew 12%.' }],
  }];
  const verdicts = await judgeClaims({
    material: 'Revenue grew 15%.',
    claims,
    complete: async () => ({
      content: '```json\n{"verdicts":[{"id":1,"verdict":"contradicted","concern":"Source says 12%.","evidence":["https://example.org/s"]}]}\n```',
    }),
  });
  assert.equal(verdicts[0].verdict, 'contradicted');
  assert.equal(verdicts[0].evidence[0].url, 'https://example.org/s');
});

test('malformed JSON is repaired exactly once', async () => {
  let calls = 0;
  const claims = [{ text: 'Revenue grew 15%.', page: 1, kind: 'statistic', evidence: [] }];
  const verdicts = await judgeClaims({
    material: 'Revenue grew 15%.',
    claims,
    complete: async ({ user }) => {
      calls += 1;
      if (calls === 1) return { content: 'I think it is probably true.' };
      assert.match(user, /previous answer was not valid JSON/i);
      return { content: '{"verdicts":[{"id":1,"verdict":"unverified","concern":"no source","evidence":[]}]}' };
    },
  });
  assert.equal(calls, 2);
  assert.equal(verdicts[0].verdict, 'unverified');
});

test('two malformed replies fail with report_unreadable and retryable true', async () => {
  let calls = 0;
  const claims = [{ text: 'Revenue grew 15%.', page: 1, kind: 'statistic', evidence: [] }];
  await assert.rejects(
    () => judgeClaims({
      material: 'Revenue grew 15%.',
      claims,
      complete: async () => { calls += 1; return { content: '' }; },
    }),
    (err) => {
      assert.equal(err.status, 502);
      assert.equal(err.apiCode, 'report_unreadable');
      assert.equal(err.retryable, true);
      return true;
    },
  );
  assert.equal(calls, 2, 'one repair attempt, never a loop');
});
