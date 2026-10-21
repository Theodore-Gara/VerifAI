const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({ verifyIdToken: async () => ({ uid: 'test-uid' }) });

const pool = require('../db/pool');

const CASE = { id: 1, title: 'Samsung staff leaked source code to a public AI chatbot', scenario: 'Engineers pasted source code.', cause: 'No approved-tool policy.', solution: 'Publish a policy and train staff.', source_title: 'HumanFirewall', source_url: 'https://example.org', sort_order: 10 };

let read = false;
let missing = false;

pool.query = async (sql) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('find_user_by_uid')) return { rows: [{ id: 7, industry_track_id: 1 }] };
  if (s.includes('FROM industry_cases c')) return { rows: [{ id: 1, title: CASE.title, source_title: CASE.source_title, source_url: CASE.source_url, sort_order: 10, read }] };
  if (s.includes('SELECT id, title, scenario, cause, solution')) return { rows: missing ? [] : [{ id: 1, title: CASE.title, scenario: CASE.scenario, cause: CASE.cause, solution: CASE.solution, source_title: CASE.source_title, source_url: CASE.source_url }] };
  if (s.includes('SELECT id FROM industry_cases')) return { rows: missing ? [] : [{ id: 1 }] };
  if (s.includes('INSERT INTO industry_case_reads')) { read = true; return { rows: [] }; }
  return { rows: [] };
};
pool.end = async () => {};

const app = require('../app');
const auth = (req) => req.set('Authorization', 'Bearer test-token');

test('GET /api/industry-practice/cases lists cases with read flags', async () => {
  read = false;
  const response = await auth(request(app).get('/api/industry-practice/cases'));
  assert.equal(response.status, 200);
  assert.equal(response.body.cases.length, 1);
  assert.equal(response.body.cases[0].read, false);
});

test('GET /api/industry-practice/cases/:id returns the full case and marks it read', async () => {
  missing = false;
  const response = await auth(request(app).get('/api/industry-practice/cases/1'));
  assert.equal(response.status, 200);
  assert.equal(response.body.case.scenario, CASE.scenario);
  assert.equal(response.body.case.cause, CASE.cause);
  assert.equal(response.body.case.solution, CASE.solution);
  assert.equal(response.body.case.read, true);
});

test('GET /api/industry-practice/cases/:id returns 404 for a case outside the track', async () => {
  missing = true;
  const response = await auth(request(app).get('/api/industry-practice/cases/999'));
  assert.equal(response.status, 404);
  missing = false;
});

test('POST /api/industry-practice/cases/:id/read is idempotent', async () => {
  read = false;
  const response = await auth(request(app).post('/api/industry-practice/cases/1/read')).send({});
  assert.equal(response.status, 200);
  assert.equal(response.body.read, true);
});
