const assert = require('node:assert/strict');
const { test, beforeEach } = require('node:test');
const request = require('supertest');

const firebase = require('../db/firebase');
const CLAIMS = {
  admin: { uid: 'a1', email: 'admin@example.com', admin_role: 'admin' },
  mod: { uid: 'm1', email: 'mod@example.com', admin_role: 'moderator' },
  learner: { uid: 'l1', email: 'learner@example.com' },
};
firebase.getFirebaseAuth = () => ({ verifyIdToken: async (token) => CLAIMS[token] || { uid: token } });

const pool = require('../db/pool');
const { contentCache } = require('../utils/ttlCache');
const fx = require('./helpers/supportFixtures');

const audit = [];
const updates = [];
let articleRow;
let messageRow;

function resetRows() {
  articleRow = { ...fx.HELP[0], published: true };
  messageRow = {
    id: 9, public_ref: 'VF-ABCD2345', user_id: 42, name: 'N', email: 'n@example.com', subject: 'Subject here',
    message: 'A message body', category: 'bug', app_version: '2.0.0', status: 'new', internal_note: null,
    resolved_at: null, created_at: fx.T1, updated_at: fx.T1,
  };
}

pool.query = async (sql, values = []) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('INSERT INTO moderation_events')) { audit.push(values); return { rows: [] }; }
  if (s.includes('SELECT status FROM users')) return { rows: [] };
  if (s.startsWith('SELECT') && s.includes('FROM help_articles') && s.includes('WHERE id = $1')) {
    return { rows: values[0] === articleRow.id ? [articleRow] : [] };
  }
  if (s.startsWith('UPDATE help_articles')) {
    updates.push({ s, values });
    const next = { ...articleRow };
    const cols = [...s.matchAll(/(\w+) = \$(\d+)/g)];
    for (const [, col, idx] of cols) next[col] = values[Number(idx) - 1];
    next.updated_at = new Date('2026-10-28T10:00:00Z');
    articleRow = next;
    return { rows: [next] };
  }
  if (s.startsWith('SELECT') && s.includes('FROM help_articles')) return { rows: [articleRow] };
  if (s.startsWith('SELECT') && s.includes('FROM support_messages WHERE id = $1')) return { rows: [messageRow] };
  if (s.startsWith('UPDATE support_messages')) {
    updates.push({ s, values });
    return { rows: [{ ...messageRow, status: 'resolved' }] };
  }
  if (s.includes('FROM support_messages') && s.includes('COUNT(*)')) return { rows: [{ count: 1 }] };
  if (s.includes('FROM support_messages')) return { rows: [messageRow] };
  const content = fx.contentRows(s.replace('FROM help_articles', 'FROM help_articles'));
  if (content && s.includes('published = TRUE')) {
    // Public read of the (possibly edited) article.
    if (s.includes('FROM help_articles')) return { rows: [articleRow] };
    return content;
  }
  return { rows: [] };
};
pool.end = async () => {};

const app = require('../app');
const as = (req, who) => req.set('Authorization', `Bearer ${who}`);

beforeEach(() => { audit.length = 0; updates.length = 0; resetRows(); contentCache.clear(); });

test('moderators can read the admin support lists; learners cannot', async () => {
  const mod = await as(request(app).get('/api/admin/support/help'), 'mod');
  assert.equal(mod.status, 200);
  assert.equal(mod.body.articles[0].slug, 'what-is-verifai');
  const msgs = await as(request(app).get('/api/admin/support/messages?status=new&category=bug'), 'mod');
  assert.equal(msgs.status, 200);
  assert.equal(msgs.body.total, 1);
  const learner = await as(request(app).get('/api/admin/support/help'), 'learner');
  assert.equal(learner.status, 403);
});

test('only admins can edit content: a moderator write is refused and nothing changes', async () => {
  const res = await as(request(app).put('/api/admin/support/help/1'), 'mod').send({ title: 'Changed' });
  assert.equal(res.status, 403);
  assert.equal(updates.length, 0);
  assert.equal(audit.length, 0);
});

test('an admin edit is audited with actor, target and a diff summary, and is live on the public API immediately', async () => {
  // Prime the public cache with the old content.
  const before = await request(app).get('/api/support/help/what-is-verifai');
  assert.equal(before.body.article.title, 'What VerifAI is');

  const res = await as(request(app).put('/api/admin/support/help/1'), 'admin')
    .send({ title: 'What VerifAI is, in short', published: true, body_md: '## Hi\nA clearer intro.' });
  assert.equal(res.status, 200);
  assert.deepEqual(res.body.changed, ['title What VerifAI is→What VerifAI is, in short', 'body_md 20→22 chars']);

  assert.equal(audit.length, 1);
  const [actor, targetUserId, targetEmail, action, reason] = audit[0];
  assert.equal(actor, 'admin@example.com');
  assert.equal(action, 'support_content_update');
  assert.match(reason, /article #1 \(what-is-verifai\)/);
  assert.match(reason, /body_md 20→22 chars/);
  assert.doesNotMatch(reason, /clearer intro/, 'the new text is not copied into the audit log');
  assert.equal(targetUserId, null);
  assert.equal(targetEmail, null);

  // Content cache was invalidated: the very next public read sees the edit.
  const after = await request(app).get('/api/support/help/what-is-verifai');
  assert.equal(after.body.article.title, 'What VerifAI is, in short');
  assert.equal(after.body.version, '2026-10-28T10:00:00Z');
});

test('unpublishing and publishing are edits too (and are audited)', async () => {
  const res = await as(request(app).put('/api/admin/support/help/1'), 'admin').send({ published: false });
  assert.equal(res.status, 200);
  assert.deepEqual(res.body.changed, ['published true→false']);
  assert.match(audit[0][4], /published true→false/);
});

test('an edit that changes nothing does not touch updated_at or the audit log', async () => {
  const res = await as(request(app).put('/api/admin/support/help/1'), 'admin').send({ title: 'What VerifAI is' });
  assert.equal(res.status, 200);
  assert.deepEqual(res.body.changed, []);
  assert.equal(updates.length, 0);
  assert.equal(audit.length, 0);
});

test('validation: unknown category, empty body, bad types and missing rows', async () => {
  const bad = await as(request(app).put('/api/admin/support/help/1'), 'admin').send({ category: 'nonsense' });
  assert.equal(bad.status, 400);
  assert.equal(bad.body.code, 'invalid_field');
  const none = await as(request(app).put('/api/admin/support/help/1'), 'admin').send({ slug: 'cannot-change-slug' });
  assert.equal(none.status, 400);
  assert.equal(none.body.code, 'no_changes');
  const type = await as(request(app).put('/api/admin/support/help/1'), 'admin').send({ published: 'yes' });
  assert.equal(type.status, 400);
  const missing = await as(request(app).put('/api/admin/support/help/999'), 'admin').send({ title: 'x' });
  assert.equal(missing.status, 404);
});

test('ticket status change: audited by reference, sets resolved_at, never copies the message', async () => {
  const res = await as(request(app).put('/api/admin/support/messages/9'), 'admin')
    .send({ status: 'resolved', internal_note: 'Replied by email.' });
  assert.equal(res.status, 200);
  assert.deepEqual(res.body.changed, ['status new→resolved', 'internal note updated']);
  const update = updates.find((u) => u.s.startsWith('UPDATE support_messages'));
  assert.match(update.s, /resolved_at = now\(\)/);

  const [actor, targetUserId, targetEmail, action, reason] = audit[0];
  assert.equal(actor, 'admin@example.com');
  assert.equal(action, 'support_message_update');
  assert.equal(targetUserId, 42);
  assert.equal(targetEmail, null, 'no email address in the audit trail');
  assert.match(reason, /VF-ABCD2345: status new→resolved; internal note updated/);
  assert.doesNotMatch(reason, /Replied by email|A message body/);
});

test('ticket updates are admin-only and validate the status', async () => {
  const mod = await as(request(app).put('/api/admin/support/messages/9'), 'mod').send({ status: 'resolved' });
  assert.equal(mod.status, 403);
  const bad = await as(request(app).put('/api/admin/support/messages/9'), 'admin').send({ status: 'closed' });
  assert.equal(bad.status, 400);
  assert.equal(bad.body.code, 'invalid_status');
  const badFilter = await as(request(app).get('/api/admin/support/messages?status=closed'), 'mod');
  assert.equal(badFilter.status, 400);
});
