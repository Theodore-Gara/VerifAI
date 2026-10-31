const assert = require('node:assert/strict');
const { test, beforeEach } = require('node:test');
const request = require('supertest');

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({
  verifyIdToken: async (token) => ({ uid: `uid-${token}` }),
});

const pool = require('../db/pool');

const inserts = [];
let failInsert = false;
pool.query = async (sql, values = []) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('find_user_by_uid')) return { rows: [{ id: 42, industry_track_id: 1 }] };
  if (s.startsWith('INSERT INTO support_messages')) {
    if (failInsert) throw new Error('db down');
    inserts.push(values);
    return { rows: [{ public_ref: values[0] }] };
  }
  return { rows: [] };
};
pool.end = async () => {};

const app = require('../app');

const valid = () => ({
  name: 'Naledi M', email: 'Naledi@Example.com', subject: 'Cannot see my tasks',
  message: 'The task list stays empty after I switch industry.', category: 'bug', app_version: '2.0.0+14',
});
let n = 0;
// A fresh signed-in identity per test keeps the 5/hour limiter independent.
const asNewUser = (req) => req.set('Authorization', `Bearer contact-${n += 1}`);

beforeEach(() => { inserts.length = 0; failInsert = false; delete process.env.SUPPORT_NOTIFY_EMAIL; });

test('POST /api/support/contact stores the message and returns a ticket reference', async () => {
  const res = await asNewUser(request(app).post('/api/support/contact')).send(valid());
  assert.equal(res.status, 201);
  assert.match(res.body.ticket_id, /^VF-[A-Z2-9]{8}$/);
  assert.equal(res.body.expected_reply, '1–2 working days');
  assert.ok(res.body.request_id);

  assert.equal(inserts.length, 1);
  const [ref, userId, name, email, subject, message, category, appVersion, requestId] = inserts[0];
  assert.equal(ref, res.body.ticket_id);
  assert.equal(userId, 42, 'linked to the signed-in account');
  assert.equal(name, 'Naledi M');
  assert.equal(email, 'naledi@example.com');
  assert.equal(subject, 'Cannot see my tasks');
  assert.equal(message, 'The task list stays empty after I switch industry.');
  assert.equal(category, 'bug');
  assert.equal(appVersion, '2.0.0+14');
  assert.equal(requestId, res.body.request_id);
});

test('signed-out senders are accepted too (user_id is null)', async () => {
  const res = await request(app).post('/api/support/contact').send(valid());
  assert.equal(res.status, 201);
  assert.equal(inserts[0][1], null);
});

test('the message is never echoed back or logged', async () => {
  const secret = 'my-private-sentence-9f31';
  const logged = [];
  const original = { log: console.log, error: console.error, warn: console.warn };
  console.log = (...a) => logged.push(a.join(' '));
  console.error = (...a) => logged.push(a.join(' '));
  console.warn = (...a) => logged.push(a.join(' '));
  let res;
  try {
    res = await asNewUser(request(app).post('/api/support/contact')).send({ ...valid(), message: `${secret} and more text` });
    // A malformed body must not be quoted back either.
    await asNewUser(request(app).post('/api/support/contact'))
      .set('Content-Type', 'application/json').send(`{"message":"${secret}", oops`);
  } finally {
    Object.assign(console, original);
  }
  assert.equal(res.status, 201);
  assert.ok(!JSON.stringify(res.body).includes(secret));
  assert.ok(!logged.join('\n').includes(secret));
});

test('malformed JSON is a 400 with a code and no quoted body', async () => {
  const res = await request(app).post('/api/support/contact')
    .set('Content-Type', 'application/json').send('{"message": "x", oops');
  assert.equal(res.status, 400);
  assert.equal(res.body.code, 'invalid_json');
});

test('validation: bad email, short/long message, name, subject, category and app version are 400 with codes', async () => {
  const cases = [
    [{ email: 'not-an-email' }, 'invalid_email'],
    [{ email: 'a@b' }, 'invalid_email'],
    [{ message: 'short' }, 'invalid_message'],
    [{ message: 'x'.repeat(4001) }, 'invalid_message'],
    [{ name: '   ' }, 'invalid_name'],
    [{ subject: 'hi' }, 'invalid_subject'],
    [{ category: 'spam' }, 'invalid_category'],
    [{ category: undefined }, 'invalid_category'],
    [{ app_version: '<script>' }, 'invalid_app_version'],
  ];
  for (const [patch, code] of cases) {
    const res = await asNewUser(request(app).post('/api/support/contact')).send({ ...valid(), ...patch });
    assert.equal(res.status, 400, JSON.stringify(patch));
    assert.equal(res.body.code, code, JSON.stringify(patch));
    assert.ok(res.body.request_id);
  }
  assert.equal(inserts.length, 0, 'nothing is stored for an invalid request');
});

test('NUL and control characters are stripped before storage', async () => {
  const res = await asNewUser(request(app).post('/api/support/contact')).send({ ...valid(), message: 'Line one\u0000 with a NUL\u0007 and\nanother line' });
  assert.equal(res.status, 201);
  assert.equal(inserts[0][5], 'Line one with a NUL and\nanother line');
});

test('honeypot: a bot gets the same success shape and nothing is stored', async () => {
  const bot = await asNewUser(request(app).post('/api/support/contact')).send({ ...valid(), website: 'http://spam.example' });
  assert.equal(bot.status, 201);
  assert.match(bot.body.ticket_id, /^VF-[A-Z2-9]{8}$/);
  assert.equal(bot.body.expected_reply, '1–2 working days');
  assert.equal(inserts.length, 0);

  // An empty honeypot (a real user) is stored normally.
  const human = await asNewUser(request(app).post('/api/support/contact')).send({ ...valid(), website: '' });
  assert.equal(human.status, 201);
  assert.equal(inserts.length, 1);
});

test('rate limit: the sixth message in an hour from one account is refused with a generic 429', async () => {
  const token = 'contact-limit-user';
  const send = () => request(app).post('/api/support/contact').set('Authorization', `Bearer ${token}`).send(valid());
  for (let i = 0; i < 5; i += 1) assert.equal((await send()).status, 201);
  const refused = await send();
  assert.equal(refused.status, 429);
  assert.equal(refused.body.code, 'rate_limited');
  assert.doesNotMatch(JSON.stringify(refused.body), /honeypot|bot|spam/i);
  assert.equal(inserts.length, 5);
});

test('a missing notification provider does not fail the request', async () => {
  delete process.env.RESEND_API_KEY;
  process.env.SUPPORT_NOTIFY_EMAIL = 'team@example.org';
  const res = await asNewUser(request(app).post('/api/support/contact')).send(valid());
  assert.equal(res.status, 201);
});

test('a notification provider failure does not fail the request, and the email never carries the message', async () => {
  process.env.SUPPORT_NOTIFY_EMAIL = 'team@example.org';
  process.env.RESEND_API_KEY = 'key';
  process.env.SUPPORT_NOTIFY_FROM = 'VerifAI <support@example.org>';
  const bodies = [];
  const realFetch = global.fetch;
  global.fetch = async (url, options) => { bodies.push(String(options.body)); throw new Error('provider down'); };
  try {
    const res = await asNewUser(request(app).post('/api/support/contact')).send(valid());
    await new Promise((resolve) => setImmediate(resolve));
    assert.equal(res.status, 201);
  } finally {
    global.fetch = realFetch;
    delete process.env.RESEND_API_KEY;
    delete process.env.SUPPORT_NOTIFY_EMAIL;
    delete process.env.SUPPORT_NOTIFY_FROM;
  }
  assert.equal(bodies.length, 1);
  assert.doesNotMatch(bodies[0], /task list stays empty|Naledi|example\.com/);
});

test('a database failure is a 500, not a silent success', async () => {
  failInsert = true;
  const res = await asNewUser(request(app).post('/api/support/contact')).send(valid());
  assert.equal(res.status, 500);
});
