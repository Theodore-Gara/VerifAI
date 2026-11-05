const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');

process.env.NVIDIA_API_KEY = 'test-key';
process.env.TAVILY_API_KEY = 'test-key';

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({ verifyIdToken: async () => ({ uid: 'test-uid' }) });

const pool = require('../db/pool');
let tavilyCalls = 0;
let modelCalls = 0;
let claimMode = 'claim';

pool.query = async (sql, values = []) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('find_user_by_uid')) return { rows: [{ id: 7, industry_track_id: 1 }] };
  if (s.startsWith('INSERT INTO verification_analyses')) {
    const report = JSON.parse(values[7]);
    return {
      rows: [{
        id: 1,
        kind: values[1],
        document_name: values[2],
        overall_status: report.overall_status,
        items_requiring_review: values[4],
        sources_confirmed: report.sources_confirmed,
        summary: report.summary,
        report,
        created_at: 'now',
      }],
    };
  }
  return { rows: [] };
};
pool.end = async () => {};

global.fetch = async (url, options) => {
  if (String(url).includes('tavily')) {
    tavilyCalls += 1;
    const body = JSON.parse(options.body);
    assert.ok(body.query);
    return {
      ok: true,
      json: async () => ({
        results: [{ title: 'Authoritative source', url: 'https://example.org/source', content: 'The figure was 12%, not 15%.' }],
      }),
    };
  }

  modelCalls += 1;
  const body = JSON.parse(options.body);
  const system = body.messages[0].content;
  let content;
  if (system.includes('find factual claims')) {
    content = claimMode === 'none'
      ? JSON.stringify({ claims: [] })
      : JSON.stringify({ claims: [{ text: 'Revenue grew 15% in 2024.', page: null, kind: 'statistic' }] });
  } else if (system.includes('verification analyst')) {
    content = JSON.stringify({
      verdicts: [{
        id: 1,
        verdict: claimMode === 'none' ? 'unverified' : 'contradicted',
        concern: 'The source says 12%, not 15%.',
        evidence: ['https://example.org/source'],
      }],
    });
  } else {
    content = '{}';
  }
  return { ok: true, json: async () => ({ choices: [{ message: { content } }], usage: {} }) };
};

const app = require('../app');
const auth = (req) => req.set('Authorization', 'Bearer test-token');

test('POST /api/verification/analyze searches each claim, not the document body', async () => {
  tavilyCalls = 0;
  modelCalls = 0;
  claimMode = 'claim';

  const response = await auth(request(app).post('/api/verification/analyze'))
    .send({ kind: 'claim', content: 'Revenue grew 15% in 2024.' });

  assert.equal(response.status, 201);
  // One claim -> one search, and the query is the claim (never the raw body).
  assert.equal(tavilyCalls, 1);
  assert.equal(response.body.web_searched, true);
  assert.equal(response.body.sources.length, 1);
  assert.equal(response.body.sources[0].url, 'https://example.org/source');

  // BF-3: the server derived the status from the verdict, not the model.
  assert.equal(response.body.analysis.overall_status, 'human_review_required');
  assert.equal(response.body.analysis.version, 2);
  assert.equal(response.body.analysis.claims.length, 1);
  assert.equal(response.body.analysis.claims[0].verdict, 'contradicted');
  assert.deepEqual(response.body.analysis.claims[0].evidence, [
    { title: 'Authoritative source', url: 'https://example.org/source' },
  ]);
  assert.equal(response.body.analysis.checks.claims_checked, 1);
  assert.equal(response.body.analysis.checks.sources_found, 1);
  assert.equal(response.body.analysis.sources_confirmed, 0);
});

test('POST /api/verification/analyze can skip the web search', async () => {
  tavilyCalls = 0;
  claimMode = 'claim';

  const response = await auth(request(app).post('/api/verification/analyze'))
    .send({ kind: 'claim', content: 'Revenue grew 15% in 2024.', web_search: false });

  assert.equal(response.status, 201);
  assert.equal(tavilyCalls, 0);
  assert.equal(response.body.web_searched, false);
  assert.deepEqual(response.body.sources, []);
  // A claimed source that was never supplied cannot support the verdict.
  assert.equal(response.body.analysis.claims[0].verdict, 'unverified');
  assert.equal(response.body.analysis.overall_status, 'insufficient_evidence');
});

test('a document with no checkable claims is insufficient evidence, never sound', async () => {
  tavilyCalls = 0;
  modelCalls = 0;
  claimMode = 'none';

  const response = await auth(request(app).post('/api/verification/analyze'))
    .send({ kind: 'claim', content: 'Some text that contains no checkable facts at all.' });

  assert.equal(response.status, 201);
  assert.equal(tavilyCalls, 0, 'no claims means no searches');
  assert.equal(modelCalls, 1, 'the verdict model is not called without claims');
  assert.equal(response.body.analysis.overall_status, 'insufficient_evidence');
  assert.equal(response.body.analysis.claims.length, 0);
  assert.equal(response.body.analysis.checks.claims_checked, 0);
  assert.equal(response.body.web_searched, false);
  assert.match(response.body.analysis.summary, /No checkable/i);
});
