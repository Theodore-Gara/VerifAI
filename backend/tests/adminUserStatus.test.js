// The admin portal sends action verbs (suspend / ban / activate) while the
// users.status column only accepts 'active', 'suspended' and 'banned'. Passing
// the verb straight through violated users_status_check and 500'd the request.

const assert = require('node:assert/strict');
const { test, beforeEach } = require('node:test');
const request = require('supertest');

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({
  verifyIdToken: async () => ({ uid: 'admin-uid', email: 'admin@example.com', admin: true }),
});

const pool = require('../db/pool');
const statusUpdates = [];
pool.query = async (sql, values = []) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.startsWith('UPDATE users SET status')) {
    statusUpdates.push(values[0]);
    return {
      rows: [{
        id: values[2],
        email: 'learner@example.com',
        firebase_uid: 'learner-uid',
        status: values[0],
        status_reason: values[1],
      }],
    };
  }
  return { rows: [] };
};
pool.end = async () => {};

const app = require('../app');

const setStatus = (action) => request(app)
  .post('/api/admin/users/7/status')
  .set('Authorization', 'Bearer admin')
  .send({ action });

beforeEach(() => { statusUpdates.length = 0; });

test('status actions write the values users_status_check allows', async () => {
  for (const [action, expected] of [
    ['suspend', 'suspended'],
    ['ban', 'banned'],
    ['activate', 'active'],
  ]) {
    const res = await setStatus(action);
    assert.equal(res.status, 200, `${action} failed: ${JSON.stringify(res.body)}`);
    assert.equal(res.body.user.status, expected);
    assert.equal(statusUpdates.at(-1), expected);
  }
});

test('an unknown status action is rejected before it reaches the database', async () => {
  const res = await setStatus('delete');
  assert.equal(res.status, 400);
  assert.equal(statusUpdates.length, 0);
});
