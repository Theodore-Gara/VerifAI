const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({
  verifyIdToken: async (token) => token === 'admin'
    ? { uid: 'a1', email: 'admin@example.com', admin_role: 'admin' }
    : { uid: 'l1', email: 'learner@example.com' },
});

const pool = require('../db/pool');

const message = {
  id: 9,
  public_ref: 'VF-ABCD2345',
  user_id: 42,
  name: 'Learner',
  email: 'learner@example.com',
  subject: 'A problem',
  message: 'The original message',
  category: 'bug',
  app_version: '2.0.0',
  status: 'new',
  internal_note: null,
  resolved_at: null,
  last_reply_at: null,
  user_last_read_at: null,
  admin_last_read_at: null,
  created_at: '2026-11-01T10:00:00Z',
  updated_at: '2026-11-01T10:00:00Z',
};

const insertedReplies = [];
const audits = [];

pool.query = async (sql, values = []) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('SELECT status, is_admin FROM users')) {
    return { rows: [{ status: 'active', is_admin: false }] };
  }
  if (s.includes('FROM users WHERE firebase_uid')) {
    return { rows: [{ id: 1, email: 'admin@example.com', display_name: 'Admin' }] };
  }
  if (s.startsWith('SELECT') && s.includes('FROM support_messages WHERE id = $1')) {
    return { rows: [message] };
  }
  if (s.startsWith('SELECT') && s.includes('FROM support_message_replies')) {
    return { rows: insertedReplies };
  }
  if (s.startsWith('UPDATE support_messages')) {
    return {
      rows: [{
        ...message,
        status: values[1],
        last_reply_at: '2026-11-02T10:00:00Z',
        admin_last_read_at: '2026-11-02T10:00:00Z',
      }],
    };
  }
  if (s.includes('INSERT INTO moderation_events')) {
    audits.push(values);
    return { rows: [] };
  }
  return { rows: [] };
};

pool.connect = async () => ({
  async query(sql, values = []) {
    const s = sql.replace(/\s+/g, ' ').trim();
    if (s === 'BEGIN' || s === 'COMMIT' || s === 'ROLLBACK') return { rows: [] };
    if (s.includes('INSERT INTO support_message_replies')) {
      const row = {
        id: 1,
        message_id: 9,
        author_type: 'admin',
        author_user_id: 1,
        author_email: 'admin@example.com',
        body: values[3],
        created_at: '2026-11-02T10:00:00Z',
      };
      insertedReplies.push(row);
      return { rows: [row] };
    }
    if (s.startsWith('UPDATE support_messages')) {
      return {
        rows: [{
          ...message,
          status: values[1],
          last_reply_at: '2026-11-02T10:00:00Z',
          admin_last_read_at: '2026-11-02T10:00:00Z',
        }],
      };
    }
    return { rows: [] };
  },
  release() {},
});
pool.end = async () => {};

const app = require('../app');

test('admin replies create a thread and set the ticket in progress', async () => {
  insertedReplies.length = 0;
  audits.length = 0;
  const response = await request(app)
    .post('/api/admin/support/messages/9/replies')
    .set('Authorization', 'Bearer admin')
    .send({ body: 'We are looking into this.' });

  assert.equal(response.status, 201);
  assert.equal(response.body.reply.author_type, 'admin');
  assert.equal(response.body.reply.body, 'We are looking into this.');
  assert.equal(response.body.message.status, 'in_progress');
  assert.equal(insertedReplies.length, 1);
  assert.ok(audits.length >= 1);
});

test('a learner cannot use the admin reply endpoint', async () => {
  const response = await request(app)
    .post('/api/admin/support/messages/9/replies')
    .set('Authorization', 'Bearer learner')
    .send({ body: 'Let me reply.' });
  assert.equal(response.status, 403);
});
