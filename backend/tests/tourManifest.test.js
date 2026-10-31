const assert = require('node:assert/strict');
const { test, beforeEach } = require('node:test');
const request = require('supertest');

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({ verifyIdToken: async () => ({ uid: 'u' }) });

const pool = require('../db/pool');
const { contentCache } = require('../utils/ttlCache');
const fx = require('./helpers/supportFixtures');

pool.query = async (sql) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  return fx.contentRows(s) || { rows: [] };
};
pool.end = async () => {};

const app = require('../app');
beforeEach(() => contentCache.clear());

const STEP_KEYS = ['id', 'title', 'body_md', 'media', 'scope'];

test('GET /api/support/tour without a track is the global tour', async () => {
  const res = await request(app).get('/api/support/tour');
  assert.equal(res.status, 200);
  assert.equal(res.body.tour_key, 'global-v1');
  assert.equal(res.body.autoplay, false);
  assert.equal(res.body.version, '2026-10-22T00:00:00Z');
  assert.deepEqual(res.body.steps.map((s) => s.scope), ['global']);
});

test('?track=<slug> returns the global steps followed by that industry\'s steps', async () => {
  const res = await request(app).get('/api/support/tour?track=finance');
  assert.equal(res.status, 200);
  assert.equal(res.body.tour_key, 'finance-v1');
  assert.equal(res.body.global_tour_key, 'global-v1');
  assert.deepEqual(res.body.steps.map((s) => `${s.scope}:${s.id}`), ['global:dashboard', 'industry:skills']);
  // version is the newest of the two manifests used
  assert.equal(res.body.version, '2026-10-25T09:30:00Z');
  for (const step of res.body.steps) {
    assert.deepEqual(Object.keys(step).sort(), [...STEP_KEYS].sort());
    assert.ok(step.body_md.length > 0, 'every step has a transcript');
  }
});

test('the track may be a numeric id, and hosted media keeps its captions and poster', async () => {
  const res = await request(app).get('/api/support/tour?track=2');
  assert.equal(res.body.tour_key, 'legal-v1');
  const withMedia = res.body.steps.find((s) => s.media);
  assert.deepEqual(Object.keys(withMedia.media).sort(), ['captions_url', 'duration_seconds', 'kind', 'poster', 'url']);
  assert.equal(res.body.steps[0].media, null, 'a step without a recording is null, never missing');
});

test('an unknown track is a 404 with a code', async () => {
  const res = await request(app).get('/api/support/tour?track=astrology');
  assert.equal(res.status, 404);
  assert.equal(res.body.code, 'track_not_found');
});

test('the tour response revalidates with an ETag', async () => {
  const first = await request(app).get('/api/support/tour?track=legal');
  const again = await request(app).get('/api/support/tour?track=legal').set('If-None-Match', first.headers.etag);
  assert.equal(again.status, 304);
});
