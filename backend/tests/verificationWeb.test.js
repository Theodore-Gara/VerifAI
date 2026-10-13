const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');

process.env.NVIDIA_API_KEY = 'test-key';
process.env.TAVILY_API_KEY = 'test-key';

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({ verifyIdToken: async () => ({ uid: 'test-uid' }) });

const pool = require('../db/pool');
let tavilyCalls = 0;

const REPORT = {
  overall_status: 'insufficient_evidence',
  items_requiring_review: [{ claim: 'Revenue grew 15%', concern: 'No source cited' }],
  sources_confirmed: 0,
  summary: 'Needs human review.',
};

pool.query = async (sql) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('FROM users WHERE firebase_uid')) return { rows: [{ id: 7, industry_track_id: 1 }] };
  if (s.startsWith('INSERT INTO verification_analyses')) {
    return { rows: [{ id: 1, kind: 'claim', document_name: null, overall_status: REPORT.overall_status, items_requiring_review: 1, sources_confirmed: 0, summary: REPORT.summary, report: REPORT, created_at: 'now' }] };
  }
  return { rows: [] };
};
pool.end = async () => {};

global.fetch = async (url, options) => {
  if (String(url).includes('tavily')) {
    tavilyCalls += 1;
    const body = JSON.parse(options.body);
    assert.ok(body.query);
    return { ok: true, json: async () => ({ results: [{ title: 'Authoritative source', url: 'https://example.org/source', content: 'The figure is 12%, not 15%.' }] }) };
  }
  return { ok: true, json: async () => ({ choices: [{ message: { content: JSON.stringify(REPORT) } }], usage: {} }) };
};

const app = require('../app');
const auth = (req) => req.set('Authorization', 'Bearer test-token');

test('POST /api/verification/analyze searches the web and returns sources', async () => {
  tavilyCalls = 0;
  const response = await auth(request(app).post('/api/verification/analyze')).send({ kind: 'claim', content: 'Revenue grew 15%' });
  assert.equal(response.status, 201);
  assert.equal(tavilyCalls, 1);
  assert.equal(response.body.web_searched, true);
  assert.equal(response.body.sources.length, 1);
  assert.equal(response.body.sources[0].url, 'https://example.org/source');
});

test('POST /api/verification/analyze can skip the web search', async () => {
  tavilyCalls = 0;
  const response = await auth(request(app).post('/api/verification/analyze')).send({ kind: 'claim', content: 'Revenue grew 15%', web_search: false });
  assert.equal(response.status, 201);
  assert.equal(tavilyCalls, 0);
  assert.equal(response.body.web_searched, false);
  assert.deepEqual(response.body.sources, []);
});
