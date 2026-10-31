const assert = require('node:assert/strict');
const { test, beforeEach } = require('node:test');
const request = require('supertest');

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({
  verifyIdToken: async (token) => {
    if (token === 'admin') return { uid: 'a1', email: 'admin@example.com', admin_role: 'admin' };
    return { uid: `uid-${token}` };
  },
});

const pool = require('../db/pool');
const { sanitiseMetadata, EVENT_SPECS } = require('../controllers/supportController');

const events = [];
let failEvents = false;
let insightQueries = [];
pool.query = async (sql, values = []) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('find_user_by_uid')) return { rows: [{ id: 5, industry_track_id: 1 }] };
  if (s.startsWith('INSERT INTO support_events')) {
    if (failEvents) throw new Error('db down');
    events.push(values);
    return { rows: [] };
  }
  if (s.includes('FROM support_events') || s.includes('FROM support_messages')) {
    insightQueries.push({ s, values });
    if (s.includes("event = 'article_view'")) return { rows: [{ slug: 'troubleshooting', views: 9 }] };
    if (s.includes("event = 'faq_expand'") && s.includes('AS topic')) return { rows: [{ topic: 'industry', expands: 4 }] };
    if (s.includes("event = 'faq_expand'")) return { rows: [{ slug: 'how-do-i-change-my-industry', expands: 4 }] };
    if (s.includes("event = 'faq_search'")) return { rows: [{ total: 10, no_result: 3 }] };
    if (s.includes('tour_start')) return { rows: [{ tour_key: 'finance-v1', starts: 8, completes: 5, skips: 2 }, { tour_key: 'legal-v1', starts: 0, completes: 0, skips: 0 }] };
    if (s.includes('FROM support_messages')) return { rows: [{ category: 'bug', messages: 3 }, { category: 'account', messages: 1 }] };
    if (s.includes('contact_open')) return { rows: [{ opens: 12, submits: 4 }] };
  }
  return { rows: [] };
};
pool.end = async () => {};

const app = require('../app');
let n = 0;
const post = (body) => request(app).post('/api/support/events').set('Authorization', `Bearer ev-${n += 1}`).send(body);

beforeEach(() => { events.length = 0; failEvents = false; insightQueries = []; });

test('POST /api/support/events records one allowlisted event', async () => {
  const res = await post({ event: 'article_view', target: 'Troubleshooting', metadata: { source: 'drawer' } });
  assert.equal(res.status, 202);
  assert.equal(res.body.recorded, true);
  const [userId, event, target, metadata] = events[0];
  assert.equal(userId, 5);
  assert.equal(event, 'article_view');
  assert.equal(target, 'troubleshooting');
  assert.deepEqual(JSON.parse(metadata), { source: 'drawer' });
});

test('metadata allowlist: unknown keys and free text are never stored', async () => {
  const res = await post({
    event: 'faq_expand', target: 'how-do-i-change-my-industry',
    metadata: {
      topic: 'industry',
      email: 'me@example.com', query: 'how do I delete my account please', message: 'secret',
      name: 'Naledi', extra: { nested: true },
    },
  });
  assert.equal(res.status, 202);
  assert.deepEqual(JSON.parse(events[0][3]), { topic: 'industry' });

  // A permitted key with a free-text value is dropped, not stored.
  await post({ event: 'faq_expand', target: 'x', metadata: { topic: 'a sentence with spaces and an @' } });
  assert.deepEqual(JSON.parse(events[1][3]), {});
});

test('faq_search stores only the result count, never the search text', async () => {
  await post({ event: 'faq_search', target: 'delete my account', metadata: { result_count: 0, query: 'delete my account' } });
  assert.equal(events[0][2], null);
  assert.deepEqual(JSON.parse(events[0][3]), { result_count: 0 });
});

test('allowlist contract: every spec only accepts slugs, enums or small integers', () => {
  const hostile = { source: 'x y', topic: 'Not A Slug!', track: '<b>', category: 'free text', result_count: 'many', steps_viewed: -1, step_index: 1.5 };
  for (const [event, spec] of Object.entries(EVENT_SPECS)) {
    assert.deepEqual(sanitiseMetadata(spec, hostile), {}, event);
    assert.ok(Object.keys(spec.meta).length <= 3, `${event}: capped keys`);
  }
  assert.deepEqual(sanitiseMetadata(EVENT_SPECS.tour_skip, { track: 'finance', step_index: 2 }), { track: 'finance', step_index: 2 });
  assert.deepEqual(sanitiseMetadata(EVENT_SPECS.contact_submit, { category: 'bug' }), { category: 'bug' });
});

test('unknown events and bad targets are 400s with codes', async () => {
  const unknown = await post({ event: 'delete_everything' });
  assert.equal(unknown.status, 400);
  assert.equal(unknown.body.code, 'invalid_event');
  const proto = await post({ event: '__proto__' });
  assert.equal(proto.status, 400);
  const badTarget = await post({ event: 'article_view', target: 'has spaces and Free Text' });
  assert.equal(badTarget.status, 400);
  assert.equal(badTarget.body.code, 'invalid_target');
  assert.equal(events.length, 0);
});

test('a failed insert never returns an error to the app', async () => {
  failEvents = true;
  const res = await post({ event: 'help_open', metadata: { source: 'dashboard' } });
  assert.equal(res.status, 202);
  assert.equal(res.body.recorded, false);
});

test('anonymous events are accepted with a null user', async () => {
  const res = await request(app).post('/api/support/events').send({ event: 'help_open' });
  assert.equal(res.status, 202);
  assert.equal(events[0][0], null);
});

test('GET /api/admin/support/insights summarises a 30-day window using indexed range filters', async () => {
  const res = await request(app).get('/api/admin/support/insights').set('Authorization', 'Bearer admin');
  assert.equal(res.status, 200);
  assert.equal(res.body.days, 30);
  assert.deepEqual(res.body.top_articles, [{ slug: 'troubleshooting', views: 9 }]);
  assert.deepEqual(res.body.top_faq_topics, [{ topic: 'industry', expands: 4 }]);
  assert.deepEqual(res.body.searches, { total: 10, no_result: 3, no_result_rate: 0.3 });
  assert.equal(res.body.tours[0].skip_rate, 0.25);
  assert.equal(res.body.tours[1].skip_rate, null, 'no starts, no rate');
  assert.equal(res.body.contact.total, 4);
  assert.deepEqual(res.body.contact.by_category.map((c) => c.category), ['bug', 'account']);
  assert.equal(res.body.contact.opens, 12);

  // Every query is a created_at range scan, never a full-table read.
  assert.ok(insightQueries.length >= 6);
  for (const q of insightQueries) {
    assert.match(q.s, /created_at >= \$1/);
    assert.ok(q.values[0] instanceof Date);
  }
  const since = Date.now() - insightQueries[0].values[0].getTime();
  assert.ok(Math.abs(since - 30 * 86400000) < 5000);
});

test('insights: days is clamped and a non-admin is refused', async () => {
  const big = await request(app).get('/api/admin/support/insights?days=99999').set('Authorization', 'Bearer admin');
  assert.equal(big.body.days, 365);
  const learner = await request(app).get('/api/admin/support/insights').set('Authorization', 'Bearer someone');
  assert.equal(learner.status, 403);
});
