// Admin actions that must leave a trace in the moderation audit trail:
// data exports, support inbox reads and portal sign-ins.
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

const audit = [];
let exportRows;

beforeEach(() => {
  audit.length = 0;
  contentCache.clear();
  exportRows = [
    { id: 1, email: 'a@example.com', display_name: 'A', status: 'active', track: 'Finance', created_at: '2026-01-01', admin_role: null, xp: 10, level: 1, streak: 0, readiness_score: 50, tier: 'Novice', attempts: 1, passed: 1 },
  ];
});

pool.query = async (sql, values = []) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('INSERT INTO moderation_events')) { audit.push(values); return { rows: [] }; }
  if (s.includes('SELECT role FROM admin_accounts')) return { rows: [] };
  if (s.includes('FROM industry_tracks')) return { rows: [] };
  if (s.includes('FROM task_attempts')) {
    return { rows: exportRows.map((r) => ({ ...r, task_id: 1, task_title: 'T', feature: 'verification', track: 'Finance', score: 80, passed: true, practice: false, xp_earned: 40, submitted_at: '2026-01-01' })) };
  }
  if (s.includes('FROM users')) {
    return { rows: exportRows.map((r) => ({ ...r, track: 'Finance' })) };
  }
  if (s.includes('FROM task_attempts ta JOIN tasks')) {
    return { rows: [{ track: 'Finance', users: 1, active_30d: 1, avg_readiness: 50, tasks: 1, attempts: 1, passed: 1 }] };
  }
  if (s.includes('UPDATE support_messages SET admin_last_read_at')) {
    return { rows: [{ id: 9, admin_last_read_at: new Date(), user_email: 'n@example.com' }] };
  }
  return { rows: [] };
};
pool.end = async () => {};

const app = require('../app');
const as = (req, who) => req.set('Authorization', `Bearer ${who}`);

test('an admin portal sign-in is audited', async () => {
  const res = await as(request(app).post('/api/admin/session'), 'admin');
  assert.equal(res.status, 200);
  assert.equal(res.body.role, 'admin');

  assert.equal(audit.length, 1);
  const [actor, targetUserId, targetEmail, action, reason] = audit[0];
  assert.equal(actor, 'admin@example.com');
  assert.equal(action, 'admin_signin');
  assert.match(reason, /admin portal/);
  assert.equal(targetUserId, null);
  assert.equal(targetEmail, null);
});

test('a learner cannot open an admin session', async () => {
  const res = await as(request(app).post('/api/admin/session'), 'learner');
  assert.equal(res.status, 403);
  assert.equal(audit.length, 0);
});

test('marking a support ticket read is audited', async () => {
  const res = await as(request(app).post('/api/admin/support/messages/9/read'), 'mod');
  assert.equal(res.status, 200);

  assert.equal(audit.length, 1);
  const [actor, , targetEmail, action, reason] = audit[0];
  assert.equal(actor, 'mod@example.com');
  assert.equal(action, 'support_ticket_read');
  assert.equal(targetEmail, 'n@example.com');
  assert.match(reason, /#9/);
});

test('downloading learner data is audited with the row count', async () => {
  const res = await as(request(app).get('/api/admin/export/users.csv'), 'admin');
  assert.equal(res.status, 200);

  assert.equal(audit.length, 1);
  const [actor, , , action, reason] = audit[0];
  assert.equal(actor, 'admin@example.com');
  assert.equal(action, 'export_users_csv');
  assert.match(reason, /1 learner records/);
});

test('downloading attempt data is audited', async () => {
  const res = await as(request(app).get('/api/admin/export/attempts.csv'), 'admin');
  assert.equal(res.status, 200);

  assert.equal(audit.length, 1);
  const [, , , action] = audit[0];
  assert.equal(action, 'export_attempts_csv');
});

test('a moderator cannot export learner data', async () => {
  const res = await as(request(app).get('/api/admin/export/users.csv'), 'mod');
  assert.equal(res.status, 403);
  assert.equal(audit.length, 0);
});
