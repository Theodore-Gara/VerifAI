const assert = require('node:assert/strict');
const { test, beforeEach } = require('node:test');
const request = require('supertest');

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({
  verifyIdToken: async (token) => {
    if (token === 'bad') throw new Error('invalid');
    return { uid: `uid-${token}` };
  },
});

const pool = require('../db/pool');
const { contentCache } = require('../utils/ttlCache');
const fx = require('./helpers/supportFixtures');

const queries = [];
pool.query = async (sql, values = []) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  queries.push({ sql: s, values });
  const content = fx.contentRows(s);
  if (content) return content;
  if (s.includes('find_user_by_uid')) return { rows: [{ id: 7, industry_track_id: 1 }] };
  return { rows: [] };
};
pool.end = async () => {};

const app = require('../app');

beforeEach(() => { contentCache.clear(); queries.length = 0; });

test('GET /api/support/help is public, ordered, versioned and only reads published rows', async () => {
  const res = await request(app).get('/api/support/help');
  assert.equal(res.status, 200);
  assert.deepEqual(res.body.articles.map((a) => a.slug), ['what-is-verifai', 'troubleshooting', 'getting-around-the-app']);
  assert.deepEqual(res.body.categories, ['start', 'troubleshooting']);
  assert.equal(res.body.version, '2026-10-25T09:30:00Z');
  assert.ok(res.body.request_id);
  assert.ok(queries.some((q) => q.sql.includes('FROM help_articles') && q.sql.includes('published = TRUE')));
});

test('GET /api/support/help?category= filters the list', async () => {
  const res = await request(app).get('/api/support/help?category=troubleshooting');
  assert.deepEqual(res.body.articles.map((a) => a.slug), ['troubleshooting']);
});

test('an invalid or missing token never blocks public support reads', async () => {
  const res = await request(app).get('/api/support/help').set('Authorization', 'Bearer bad');
  assert.equal(res.status, 200);
});

test('GET /api/support/help/:slug returns the article and related ones; unknown slug is a clean 404', async () => {
  const ok = await request(app).get('/api/support/help/what-is-verifai');
  assert.equal(ok.status, 200);
  assert.equal(ok.body.article.slug, 'what-is-verifai');
  assert.deepEqual(ok.body.related.map((r) => r.slug), ['getting-around-the-app']);

  const missing = await request(app).get('/api/support/help/does-not-exist');
  assert.equal(missing.status, 404);
  assert.equal(missing.body.code, 'help_article_not_found');
  assert.ok(missing.body.error && missing.body.request_id);
  assert.equal(missing.body.articles, undefined, 'not an empty list');
});

test('GET /api/support/faqs filters by topic and searches question and answer case-insensitively', async () => {
  const topic = await request(app).get('/api/support/faqs?topic=verification');
  assert.deepEqual(topic.body.faqs.map((f) => f.slug), ['what-is-verification-studio']);

  const inQuestion = await request(app).get('/api/support/faqs?q=CHANGE%20MY%20INDUSTRY');
  assert.deepEqual(inQuestion.body.faqs.map((f) => f.slug), ['how-do-i-change-my-industry']);

  const inAnswer = await request(app).get('/api/support/faqs?q=0%20to%20100');
  assert.deepEqual(inAnswer.body.faqs.map((f) => f.slug), ['what-does-the-readiness-score-mean']);

  const none = await request(app).get('/api/support/faqs?q=zzzz-no-match');
  assert.equal(none.status, 200);
  assert.deepEqual(none.body.faqs, []);
  assert.deepEqual(none.body.topics, ['industry', 'verification', 'progress']);
});

test('conditional GET: the ETag revalidates to 304 and changes when content changes', async () => {
  const first = await request(app).get('/api/support/help');
  const etag = first.headers.etag;
  assert.ok(etag);

  const cached = await request(app).get('/api/support/help').set('If-None-Match', etag);
  assert.equal(cached.status, 304);

  // An edit raises updated_at: after the cache is invalidated the version and
  // ETag both change, with no deploy.
  const original = fx.HELP[0].updated_at;
  fx.HELP[0].updated_at = new Date('2026-10-27T08:00:00Z');
  contentCache.clear();
  const changed = await request(app).get('/api/support/help').set('If-None-Match', etag);
  fx.HELP[0].updated_at = original;
  assert.equal(changed.status, 200);
  assert.equal(changed.body.version, '2026-10-27T08:00:00Z');
  assert.notEqual(changed.headers.etag, etag);
});

test('industry guides: list summaries, full guide with resolved related FAQs, 404 for unknown', async () => {
  const list = await request(app).get('/api/support/industry-guides');
  assert.deepEqual(list.body.guides.map((g) => g.slug), ['finance', 'legal']);
  assert.equal(list.body.guides[0].overview_md, undefined, 'list is summaries only');

  const one = await request(app).get('/api/support/industry-guides/finance');
  assert.equal(one.status, 200);
  assert.equal(one.body.guide.track_name, 'Finance');
  // the unpublished/missing FAQ slug is skipped rather than failing the page
  assert.deepEqual(one.body.related_faqs.map((f) => f.slug), ['how-do-i-change-my-industry']);

  const missing = await request(app).get('/api/support/industry-guides/nope');
  assert.equal(missing.status, 404);
  assert.equal(missing.body.code, 'industry_guide_not_found');
});

test('GET /api/support/about returns stored copy, app version and contact details from the environment', async () => {
  delete process.env.SUPPORT_EMAIL;
  const bare = await request(app).get('/api/support/about');
  assert.equal(bare.status, 200);
  assert.equal(bare.body.about.mission_md, 'Mission.');
  assert.equal(bare.body.about.contact.email, null, 'no address is invented');
  assert.match(bare.body.about.app_version, /^\d+\.\d+\.\d+/);

  process.env.SUPPORT_EMAIL = 'help@example.org';
  contentCache.clear();
  const set = await request(app).get('/api/support/about');
  delete process.env.SUPPORT_EMAIL;
  assert.equal(set.body.about.contact.email, 'help@example.org');
  assert.equal(set.body.about.contact.expected_reply, '1–2 working days');
});
