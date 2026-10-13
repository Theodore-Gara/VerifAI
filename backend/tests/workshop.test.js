const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({
  verifyIdToken: async () => ({ uid: 'test-uid', email: 'test@example.com', name: 'Test User' }),
});

const pool = require('../db/pool');

const USER = { id: 7, industry_track_id: 1 };
const POST = {
  id: 1, parent_id: null, lesson_id: null, body: 'How do you verify a citation?',
  created_at: '2026-10-12T00:00:00.000Z', edited_at: null,
  author_id: 7, author_name: 'Test User', is_mine: true, reply_count: 2, reaction_count: 3, reacted: false,
};

let postAuthorId = 8;
let myReaction = false;

pool.query = async (sql, values = []) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('FROM users WHERE firebase_uid')) return { rows: [USER] };
  if (s.includes('INSERT INTO workshop_posts')) return { rows: [{ id: 5, parent_id: values[3], lesson_id: values[1], body: values[4], created_at: 'now' }] };
  if (s.includes('FROM workshop_posts p') && s.includes('p.parent_id = $2')) {
    return { rows: [{ id: 4, parent_id: 1, body: 'Try SAFLII.', created_at: 'now', edited_at: null, author_id: 9, author_name: 'Peer', is_mine: false, reaction_count: 0, reacted: false }] };
  }
  if (s.includes('FROM workshop_posts p')) return { rows: [POST] };
  if (s.includes('SELECT author_id FROM workshop_posts WHERE id')) return { rows: [{ author_id: postAuthorId }] };
  if (s.includes('SELECT id FROM workshop_posts WHERE id = $1 AND track_id')) return { rows: [{ id: 1 }] };
  if (s.includes('DELETE FROM workshop_posts')) return { rows: [] };
  return { rows: [] };
};
pool.end = async () => {};

const fakeClient = {
  async query(sql, values = []) {
    const s = sql.replace(/\s+/g, ' ').trim();
    if (['BEGIN', 'COMMIT', 'ROLLBACK'].includes(s)) return { rows: [] };
    if (s.includes('SELECT id FROM workshop_posts WHERE id = $1 AND track_id')) return { rows: [{ id: 1 }] };
    if (s.includes('SELECT id, author_id FROM workshop_posts WHERE id = $1 AND track_id')) return { rows: [{ id: 1, author_id: postAuthorId }] };
    if (s.includes('SELECT 1 FROM workshop_reactions')) return { rows: myReaction ? [{ '?column?': 1 }] : [] };
    if (s.includes('DELETE FROM workshop_reactions')) return { rows: [] };
    if (s.includes('INSERT INTO workshop_reactions')) return { rows: [] };
    if (s.includes('SELECT COUNT(*)::int AS n FROM workshop_reactions')) return { rows: [{ n: myReaction ? 0 : 1 }] };
    if (s.includes('INSERT INTO workshop_reports')) return { rows: [{ id: 1 }] };
    if (s.includes('SELECT COUNT(*)::int AS n FROM workshop_reports')) return { rows: [{ n: 3 }] };
    if (s.includes('UPDATE workshop_posts SET hidden')) return { rows: [] };
    return { rows: [] };
  },
  release() {},
};
pool.connect = async () => fakeClient;

const app = require('../app');
const auth = (req) => req.set('Authorization', 'Bearer test-token');

test('GET /api/workshop/posts lists track threads with reaction/reply counts', async () => {
  const response = await auth(request(app).get('/api/workshop/posts'));
  assert.equal(response.status, 200);
  assert.equal(response.body.posts.length, 1);
  assert.equal(response.body.posts[0].reply_count, 2);
  assert.equal(response.body.posts[0].is_mine, true);
});

test('GET /api/workshop/posts/:id/replies returns replies', async () => {
  const response = await auth(request(app).get('/api/workshop/posts/1/replies'));
  assert.equal(response.status, 200);
  assert.equal(response.body.replies[0].author_name, 'Peer');
});

test('POST /api/workshop/posts creates a thread', async () => {
  const response = await auth(request(app).post('/api/workshop/posts')).send({ body: 'How do you verify a citation?' });
  assert.equal(response.status, 201);
  assert.equal(response.body.post.id, 5);
});

test('POST /api/workshop/posts rejects an empty body', async () => {
  const response = await auth(request(app).post('/api/workshop/posts')).send({ body: '   ' });
  assert.equal(response.status, 400);
});

test('POST /api/workshop/posts/:id/react toggles an upvote on', async () => {
  myReaction = false;
  const response = await auth(request(app).post('/api/workshop/posts/1/react')).send({});
  assert.equal(response.status, 200);
  assert.equal(response.body.reacted, true);
  assert.equal(response.body.reaction_count, 1);
});

test('POST /api/workshop/posts/:id/react toggles an upvote off', async () => {
  myReaction = true;
  const response = await auth(request(app).post('/api/workshop/posts/1/react')).send({});
  assert.equal(response.status, 200);
  assert.equal(response.body.reacted, false);
});

test('POST /api/workshop/posts/:id/report auto-hides after enough reports', async () => {
  postAuthorId = 8;
  const response = await auth(request(app).post('/api/workshop/posts/1/report')).send({ reason: 'spam' });
  assert.equal(response.status, 200);
  assert.equal(response.body.hidden, true);
});

test('POST /api/workshop/posts/:id/report rejects reporting your own post', async () => {
  postAuthorId = 7;
  const response = await auth(request(app).post('/api/workshop/posts/1/report')).send({ reason: 'spam' });
  assert.equal(response.status, 400);
});

test('POST /api/workshop/posts/:id/report rejects an unknown reason', async () => {
  const response = await auth(request(app).post('/api/workshop/posts/1/report')).send({ reason: 'nonsense' });
  assert.equal(response.status, 400);
});

test('DELETE /api/workshop/posts/:id lets the author delete', async () => {
  postAuthorId = 7;
  const response = await auth(request(app).delete('/api/workshop/posts/1'));
  assert.equal(response.status, 200);
  assert.equal(response.body.deleted, true);
});

test('DELETE /api/workshop/posts/:id forbids deleting another user post', async () => {
  postAuthorId = 8;
  const response = await auth(request(app).delete('/api/workshop/posts/1'));
  assert.equal(response.status, 403);
});
