const assert = require('node:assert/strict');
const { test } = require('node:test');
const firebase = require('../db/firebase');
const pool = require('../db/pool');
const request = require('supertest');

firebase.getFirebaseAuth = () => ({
  verifyIdToken: async () => ({ uid: 'test-uid', email: 'test@example.com', name: 'Test User' }),
});

// Every query is recorded so tests can assert on the SQL that was issued.
const queries = [];

const DECISION_OPTIONS = [
  { id: 11, kind: 'decision', label: 'Use AI' },
  { id: 12, kind: 'decision', label: 'Use AI with human review' },
  { id: 13, kind: 'decision', label: "Don't use AI" },
];
const REASON_OPTIONS = [
  { id: 14, kind: 'reason', label: 'A. It is routine, low-risk work.' },
  { id: 15, kind: 'reason', label: 'B. AI always saves time.' },
  { id: 16, kind: 'reason', label: 'C. AI output is never professional.' },
];

pool.query = async (sql) => {
  queries.push(sql);
  if (sql.includes('FROM industry_tracks')) return { rows: [{ id: 1, name: 'Finance', description: 'Finance' }] };
  if (sql.includes('FROM users u')) return { rows: [{ id: 7, industry_track_id: 1, level: 1 }] };
  if (sql.includes('JOIN judgement_tasks')) {
    return { rows: [{ id: 5, feature: 'judgement', title: 'The Month-End Agenda', scenario: '...' }] };
  }
  if (sql.includes('JOIN verification_tasks')) {
    return {
      rows: [{ id: 3, format: 'choice', title: 'Verify the summary', scenario: '...', embedded_flaw: 'missed payment', difficulty: 'easy' }],
    };
  }
  if (sql.includes('FROM task_options')) {
    if (sql.includes("kind = 'answer'")) return { rows: [{ id: 21, label: 'Check the source file' }] };
    return { rows: [...DECISION_OPTIONS, ...REASON_OPTIONS] };
  }
  // Checked last: every task query also contains `SELECT 1` in its seen-filter.
  if (sql.includes('SELECT 1')) return { rows: [{ '?column?': 1 }] };
  return { rows: [] };
};
pool.connect = async () => {};
pool.end = async () => {};

const app = require('../app');

test('GET / returns API metadata', async () => {
  const response = await request(app).get('/');
  assert.equal(response.status, 200);
  assert.equal(response.body.name, 'VerifAI API');
});

test('GET /api/docs returns documented endpoints', async () => {
  const response = await request(app).get('/api/docs');
  assert.equal(response.status, 200);
  assert.ok(response.body.endpoints.includes('POST /api/tasks/:id/attempt'));
});

test('GET /api/health reports database connectivity', async () => {
  const response = await request(app).get('/api/health');
  assert.equal(response.status, 200);
  assert.equal(response.body.status, 'ok');
  assert.equal(response.body.db, 'connected');
  assert.ok(response.headers['x-request-id']);
});

test('GET /api/tracks returns tracks', async () => {
  const response = await request(app).get('/api/tracks');
  assert.equal(response.status, 200);
  assert.equal(response.body.tracks.length, 1);
});

test('protected endpoint rejects missing Firebase token', async () => {
  const response = await request(app).get('/api/tasks/next');
  assert.equal(response.status, 401);
  assert.match(response.body.error, /Authorization/);
});

test('attempt endpoint rejects malformed task id before database access', async () => {
  const response = await request(app)
    .post('/api/tasks/not-a-number/attempt')
    .set('Authorization', 'Bearer test-token')
    .send({ answer: 'test' });
  assert.equal(response.status, 400);
  assert.match(response.body.error, /positive integer/);
});

test('unknown routes return 404', async () => {
  const response = await request(app).get('/api/does-not-exist');
  assert.equal(response.status, 404);
  assert.equal(response.body.error, 'Route not found');
});

test('?dimension= returns the feature task with options but never their scores', async () => {
  queries.length = 0;
  const response = await request(app)
    .get('/api/tasks/next')
    .query({ dimension: 'AI Judgement' })
    .set('Authorization', 'Bearer test-token');

  assert.equal(response.status, 200);
  const task = response.body.task;
  assert.equal(task.feature, 'judgement');
  assert.equal(task.dimension, 'AI Judgement');
  assert.equal(task.options.length, 6);
  for (const option of task.options) assert.ok(!('score' in option));

  const taskSql = queries.find((sql) => sql.includes('JOIN judgement_tasks'));
  assert.ok(taskSql, 'expected the judgement task query');
  assert.ok(taskSql.includes('t.feature = $1'), 'expected the feature filter');
  assert.ok(taskSql.includes('ORDER BY t.id ASC'), 'expected id ordering');
});

test('?dimension=Verification drops the difficulty ordering', async () => {
  queries.length = 0;
  const response = await request(app)
    .get('/api/tasks/next')
    .query({ dimension: 'Verification' })
    .set('Authorization', 'Bearer test-token');

  assert.equal(response.status, 200);
  assert.equal(response.body.task.dimension, 'Verification');
  const taskSql = queries.find((sql) => sql.includes('JOIN verification_tasks'));
  assert.ok(taskSql, 'expected the verification task query');
  assert.ok(!taskSql.includes('CASE v.difficulty'), 'difficulty ordering must be dropped');
});

test('the default request keeps the level-adaptive difficulty ordering', async () => {
  queries.length = 0;
  const response = await request(app).get('/api/tasks/next').set('Authorization', 'Bearer test-token');

  assert.equal(response.status, 200);
  assert.equal(response.body.task.dimension, 'Verification');
  const taskSql = queries.find((sql) => sql.includes('JOIN verification_tasks'));
  assert.ok(taskSql.includes('CASE v.difficulty'), 'default path keeps difficulty ordering');
});

test('an unknown dimension is rejected', async () => {
  const response = await request(app)
    .get('/api/tasks/next')
    .query({ dimension: 'Prompt Smoothing' })
    .set('Authorization', 'Bearer test-token');
  assert.equal(response.status, 400);
  assert.match(response.body.error, /dimension/);
});

test('conflicting feature and dimension are rejected', async () => {
  const response = await request(app)
    .get('/api/tasks/next')
    .query({ feature: 'judgement', dimension: 'Verification' })
    .set('Authorization', 'Bearer test-token');
  assert.equal(response.status, 400);
  assert.match(response.body.error, /do not match/);
});
