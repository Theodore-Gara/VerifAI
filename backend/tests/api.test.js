const assert = require('node:assert/strict');
const { test } = require('node:test');
const firebase = require('../db/firebase');
const pool = require('../db/pool');
const request = require('supertest');

firebase.getFirebaseAuth = () => ({
  verifyIdToken: async () => ({ uid: 'test-uid', email: 'test@example.com', name: 'Test User' }),
});
pool.query = async (sql) => {
  if (sql.includes('SELECT 1')) return { rows: [{ '?column?': 1 }] };
  if (sql.includes('FROM industry_tracks')) return { rows: [{ id: 1, name: 'Finance', description: 'Finance' }] };
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
