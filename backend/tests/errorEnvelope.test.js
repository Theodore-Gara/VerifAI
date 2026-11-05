const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');

process.env.NVIDIA_API_KEY = 'test-key';
process.env.TAVILY_API_KEY = 'test-key';

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({ verifyIdToken: async () => ({ uid: 'test-uid' }) });

const pool = require('../db/pool');
let verdictMode = 'valid';
let providerSecret = false;

pool.query = async (sql) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('find_user_by_uid')) return { rows: [{ id: 7, industry_track_id: 1 }] };
  return { rows: [] };
};
pool.end = async () => {};

global.fetch = async (url, options) => {
  if (String(url).includes('tavily')) {
    return { ok: true, json: async () => ({ results: [] }) };
  }
  const body = JSON.parse(options.body);
  const system = body.messages[0].content;
  if (system.includes('find factual claims')) {
    return { ok: true, json: async () => ({ choices: [{ message: { content: JSON.stringify({ claims: [{ text: 'Revenue grew 15% in 2024.', page: null, kind: 'statistic' }] }) } }] }) };
  }
  if (providerSecret) {
    // HTTP 200 with a provider error frame: the secret text must stay in logs.
    return { ok: true, json: async () => ({ error: { code: 502, message: 'SECRET PROVIDER DETAIL' } }) };
  }
  if (verdictMode === 'invalid') {
    return { ok: true, json: async () => ({ choices: [{ message: { content: 'not json at all' } }] }) };
  }
  return { ok: true, json: async () => ({ choices: [{ message: { content: JSON.stringify({ verdicts: [{ id: 1, verdict: 'unverified', concern: 'no source', evidence: [] }] }) } }] }) };
};

const app = require('../app');
const auth = (req) => req.set('Authorization', 'Bearer test-token');

function assertEnvelope(response, status, code) {
  assert.equal(response.status, status);
  assert.equal(response.body.code, code);
  assert.equal(typeof response.body.error, 'string');
  assert.equal(typeof response.body.hint, 'string');
  assert.equal(typeof response.body.retryable, 'boolean');
  assert.ok(response.body.request_id);
}

test('no input is a coded 400 with a hint', async () => {
  const response = await auth(request(app).post('/api/verification/analyze')).send({ kind: 'claim' });
  assertEnvelope(response, 400, 'no_input');
  assert.equal(response.body.retryable, false);
});

test('an unsupported file type carries document_unsupported and a remedy', async () => {
  const response = await auth(request(app).post('/api/verification/analyze')).send({
    kind: 'document',
    sources: [{ type: 'document', name: 'brief.doc', mime: 'application/msword', base64: Buffer.from('x').toString('base64') }],
  });
  assertEnvelope(response, 415, 'document_unsupported');
  assert.match(response.body.hint, /Save the file as \.docx/);
});

test('a scanned/empty document is document_no_text', async () => {
  const response = await auth(request(app).post('/api/verification/analyze')).send({
    kind: 'document',
    sources: [{ type: 'document', name: 'scan.txt', mime: 'text/plain', base64: Buffer.from('   ').toString('base64') }],
  });
  assertEnvelope(response, 422, 'document_no_text');
  assert.match(response.body.hint, /scanned PDF/i);
});

test('the global 404 also uses the envelope', async () => {
  const response = await request(app).get('/api/definitely-not-a-route');
  assertEnvelope(response, 404, 'not_found');
});

test('malformed JSON is invalid_json and does not echo the body', async () => {
  const response = await request(app)
    .post('/api/verification/analyze')
    .set('Content-Type', 'application/json')
    .set('Authorization', 'Bearer test-token')
    .send('{"message":"SECRET SUPPORT MESSAGE"');
  assertEnvelope(response, 400, 'invalid_json');
  assert.equal(JSON.stringify(response.body).includes('SECRET SUPPORT MESSAGE'), false);
});

test('provider text never reaches the response body', async () => {
  providerSecret = true;
  try {
    const response = await auth(request(app).post('/api/verification/analyze'))
      .send({ kind: 'claim', content: 'Revenue grew 15% in 2024.' });
    assertEnvelope(response, 502, 'ai_unavailable');
    assert.equal(JSON.stringify(response.body).includes('SECRET'), false);
    assert.equal(response.body.retryable, true);
  } finally {
    providerSecret = false;
  }
});

test('an unreadable report is report_unreadable with retryable true', async () => {
  verdictMode = 'invalid';
  try {
    const response = await auth(request(app).post('/api/verification/analyze'))
      .send({ kind: 'claim', content: 'Revenue grew 15% in 2024.' });
    assertEnvelope(response, 502, 'report_unreadable');
    assert.equal(response.body.retryable, true);
  } finally {
    verdictMode = 'valid';
  }
});
