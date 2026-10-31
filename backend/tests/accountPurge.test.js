const assert = require('node:assert/strict');
const { test } = require('node:test');

const firebase = require('../db/firebase');
let firebaseDeleted = [];
firebase.getFirebaseAuth = () => ({ deleteUser: async (uid) => { firebaseDeleted.push(uid); } });

const pool = require('../db/pool');

function install({ failOn = null } = {}) {
  const log = [];
  const client = {
    async query(sql, values = []) {
      const s = sql.replace(/\s+/g, ' ').trim();
      log.push({ s, values });
      if (failOn && s.includes(failOn)) throw new Error('boom');
      if (s.startsWith('DELETE FROM users')) return { rows: [{ id: values[0] }] };
      return { rows: [] };
    },
    release() { log.push({ s: 'RELEASE' }); },
  };
  pool.connect = async () => client;
  pool.query = async (sql, values = []) => {
    const s = sql.replace(/\s+/g, ' ').trim();
    if (s.includes('FROM users') && s.includes('firebase_uid')) {
      return { rows: [{ id: 7, email: 'Learner@Example.com', firebase_uid: 'fb-7' }] };
    }
    log.push({ s: `POOL ${s}`, values });
    return { rows: [] };
  };
  return log;
}

const { purgeAccount } = require('../services/accountPurge');

test('deleting an account removes its support rows in the same transaction as the profile', async () => {
  firebaseDeleted = [];
  const log = install();
  const result = await purgeAccount({ userId: 7 });
  assert.equal(result.hadProfile, true);
  assert.equal(result.firebaseDeleted, true);

  const statements = log.map((l) => l.s);
  const begin = statements.indexOf('BEGIN');
  const commit = statements.indexOf('COMMIT');
  assert.ok(begin >= 0 && commit > begin);
  const inside = statements.slice(begin, commit);
  assert.ok(inside.some((s) => s.startsWith('DELETE FROM support_events WHERE user_id = $1')));
  assert.ok(inside.some((s) => s.startsWith('DELETE FROM support_messages')));
  assert.ok(inside.some((s) => s.startsWith('DELETE FROM users')));
  // Support rows go before the account row, all between BEGIN and COMMIT.
  assert.ok(inside.findIndex((s) => s.includes('support_messages')) < inside.findIndex((s) => s.startsWith('DELETE FROM users')));
  assert.ok(statements.includes('RELEASE'));
  assert.deepEqual(firebaseDeleted, ['fb-7']);
});

test('anonymous tickets that used the account email are removed too', async () => {
  const log = install();
  await purgeAccount({ userId: 7 });
  const messages = log.find((l) => l.s.startsWith('DELETE FROM support_messages'));
  assert.match(messages.s, /user_id IS NULL .*lower\(email\) = lower\(\$2\)/);
  assert.deepEqual(messages.values, [7, 'Learner@Example.com']);
});

test('a failure rolls everything back and the Firebase identity is left alone', async () => {
  firebaseDeleted = [];
  const log = install({ failOn: 'DELETE FROM support_messages' });
  await assert.rejects(() => purgeAccount({ userId: 7 }), /boom/);
  const statements = log.map((l) => l.s);
  assert.ok(statements.includes('ROLLBACK'));
  assert.ok(!statements.includes('COMMIT'));
  assert.ok(statements.includes('RELEASE'));
  assert.deepEqual(firebaseDeleted, [], 'identity is only deleted after the database delete succeeded');
});
