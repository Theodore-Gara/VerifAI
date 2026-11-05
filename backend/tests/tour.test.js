const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({ verifyIdToken: async () => ({ uid: 'test-uid' }) });

const pool = require('../db/pool');

let tutorialRow = null;
let userTrack = 1;

pool.query = async (sql, values = []) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('find_user_by_uid')) return { rows: [{ id: 7, industry_track_id: userTrack }] };
  if (s.includes('FROM industry_tracks WHERE id = $1')) return { rows: values[0] === 1 ? [{ id: 1 }] : [] };
  if (s.includes('FROM user_tutorials')) return { rows: tutorialRow ? [tutorialRow] : [] };
  if (s.startsWith('INSERT INTO user_tutorials')) {
    const status = values[3];
    // Idempotent: only a status change moves updated_at.
    const updatedAt = tutorialRow && tutorialRow.status === status ? tutorialRow.updated_at : 'now';
    tutorialRow = { status, updated_at: updatedAt };
    return { rows: [{ status, updated_at: updatedAt }] };
  }
  return { rows: [] };
};
pool.end = async () => {};

const app = require('../app');
const auth = (req) => req.set('Authorization', 'Bearer test-token');

test('a new industry returns should_offer true and no status', async () => {
  tutorialRow = null;
  const response = await auth(request(app).get('/api/onboarding/tour'));
  assert.equal(response.status, 200);
  assert.equal(response.body.tour_key, 'industry');
  assert.equal(response.body.status, null);
  assert.equal(response.body.should_offer, true);
  assert.equal(response.body.track_id, 1);
});

test('completing the tour records completed server-side', async () => {
  tutorialRow = null;
  const response = await auth(request(app).put('/api/onboarding/tour')).send({ status: 'completed' });
  assert.equal(response.status, 200);
  assert.equal(response.body.status, 'completed');
  assert.equal(tutorialRow.status, 'completed');

  const read = await auth(request(app).get('/api/onboarding/tour'));
  assert.equal(read.body.status, 'completed');
  assert.equal(read.body.should_offer, false);
});

test('skipping records skipped and is only re-offered on request', async () => {
  tutorialRow = null;
  const skipped = await auth(request(app).put('/api/onboarding/tour')).send({ status: 'skipped' });
  assert.equal(skipped.status, 200);
  assert.equal(skipped.body.should_offer, false);

  const normal = await auth(request(app).get('/api/onboarding/tour'));
  assert.equal(normal.body.should_offer, false);

  const reoffer = await auth(request(app).get('/api/onboarding/tour?reoffer=1'));
  assert.equal(reoffer.body.should_offer, true);
});

test('repeat PUT is idempotent and does not move updated_at', async () => {
  tutorialRow = { status: 'completed', updated_at: '2026-11-01T00:00:00.000Z' };
  const response = await auth(request(app).put('/api/onboarding/tour')).send({ status: 'completed' });
  assert.equal(response.status, 200);
  assert.equal(response.body.updated_at, '2026-11-01T00:00:00.000Z');
});

test('a track can be named explicitly and an invalid status is a 400', async () => {
  tutorialRow = null;
  const response = await auth(request(app).put('/api/onboarding/tour')).send({ status: 'paused' });
  assert.equal(response.status, 400);
  assert.equal(response.body.code, 'invalid_status');

  const explicit = await auth(request(app).get('/api/onboarding/tour?track_id=1'));
  assert.equal(explicit.status, 200);
});

test('no industry selected is a clear 400', async () => {
  userTrack = null;
  try {
    const response = await auth(request(app).get('/api/onboarding/tour'));
    assert.equal(response.status, 400);
    assert.equal(response.body.code, 'no_track');
  } finally {
    userTrack = 1;
  }
});
