const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');

process.env.NVIDIA_API_KEY = 'test-key';
process.env.TAVILY_API_KEY = 'test-key';

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({ verifyIdToken: async () => ({ uid: 'test-uid' }) });

const pool = require('../db/pool');
const { veraSystem } = require('../services/llm/prompts');

const USER = { id: 7, industry_track_id: 1 };
let lastQuery = null;

pool.query = async (sql, values = []) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('find_user_by_uid')) return { rows: [USER] };

  lastQuery = { s, values };

  if (s.startsWith('SELECT check_in_date::text AS date, mood, note, updated_at')) {
    return { rows: [{ date: '2026-10-19', mood: 'Calm', note: 'Busy but okay.', updated_at: 'now' }] };
  }
  if (s.startsWith('INSERT INTO wellness_mood_checkins')) {
    return { rows: [{ date: values[1] || '2026-10-19', mood: values[2], note: values[3], updated_at: 'now' }] };
  }
  if (s.startsWith('DELETE FROM wellness_journal_entries')) {
    return { rows: [] };
  }
  if (s.startsWith('SELECT entry_date::text AS date, content, updated_at')) {
    return { rows: [{ date: '2026-10-19', content: 'A quiet day.', updated_at: 'now' }] };
  }
  if (s.startsWith('INSERT INTO wellness_journal_entries')) {
    return { rows: [{ date: values[1] || '2026-10-19', content: values[2], updated_at: 'now' }] };
  }
  if (s.startsWith('UPDATE wellness_journal_entries SET deleted_at = now()')) {
    return { rows: [{ date: values[1] }] };
  }
  if (s.startsWith('UPDATE wellness_journal_entries SET deleted_at = NULL')) {
    return { rows: [{ date: values[1], content: 'A quiet day.' }] };
  }
  if (s.startsWith('SELECT activity, COUNT(*)::int AS count, MAX(at)')) {
    return { rows: [{ activity: 'breathing', count: 3, last_at: 'now' }, { activity: 'step_outside', count: 1, last_at: 'now' }] };
  }
  if (s.startsWith('INSERT INTO wellness_activities')) {
    return { rows: [{ id: 1, activity: values[1], completed_at: 'now' }] };
  }
  return { rows: [] };
};
pool.end = async () => {};

const app = require('../app');
const auth = (req) => req.set('Authorization', 'Bearer test-token');

test('wellness endpoints require a token', async () => {
  const response = await request(app).get('/api/wellness/mood');
  assert.equal(response.status, 401);
});

test('GET /api/wellness/mood returns the learner\'s check-ins', async () => {
  const response = await auth(request(app).get('/api/wellness/mood'));
  assert.equal(response.status, 200);
  assert.equal(response.body.checkins[0].mood, 'Calm');
  assert.deepEqual(lastQuery.values, [USER.id, 30]);
});

test('PUT /api/wellness/mood rejects an unknown mood', async () => {
  const response = await auth(request(app).put('/api/wellness/mood')).send({ mood: 'Furious' });
  assert.equal(response.status, 400);
});

test('PUT /api/wellness/mood rejects a malformed date', async () => {
  const response = await auth(request(app).put('/api/wellness/mood')).send({ mood: 'Calm', date: '19/10/2026' });
  assert.equal(response.status, 400);
});

test('PUT /api/wellness/mood upserts one check-in per day', async () => {
  const response = await auth(request(app).put('/api/wellness/mood')).send({ mood: 'Great', date: '2026-10-19' });
  assert.equal(response.status, 200);
  assert.equal(response.body.checkin.mood, 'Great');
  assert.match(lastQuery.s, /ON CONFLICT \(user_id, check_in_date\) DO UPDATE/);
  assert.deepEqual(lastQuery.values, [USER.id, '2026-10-19', 'Great', null, false]);
});

test('PUT /api/wellness/mood saves an optional note', async () => {
  const response = await auth(request(app).put('/api/wellness/mood')).send({ mood: 'Calm', note: '  Slow morning.  ' });
  assert.equal(response.status, 200);
  // An omitted date is filed against the server's configured day (not the UTC
  // CURRENT_DATE, and not the device clock).
  const serverToday = new Intl.DateTimeFormat('en-CA', {
    timeZone: process.env.STREAK_TIMEZONE || 'Africa/Johannesburg',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date());
  assert.deepEqual(lastQuery.values, [USER.id, serverToday, 'Calm', 'Slow morning.', true]);

  const tooLong = await auth(request(app).put('/api/wellness/mood')).send({ mood: 'Calm', note: 'x'.repeat(201) });
  assert.equal(tooLong.status, 400);
});

test('PUT /api/wellness/journal validates the entry', async () => {
  const empty = await auth(request(app).put('/api/wellness/journal')).send({ content: '   ' });
  assert.equal(empty.status, 400);

  const tooLong = await auth(request(app).put('/api/wellness/journal')).send({ content: 'x'.repeat(1201) });
  assert.equal(tooLong.status, 400);
});

test('PUT /api/wellness/journal upserts the day\'s entry', async () => {
  const response = await auth(request(app).put('/api/wellness/journal')).send({ content: 'Slept badly, but went for a walk.' });
  assert.equal(response.status, 200);
  assert.equal(response.body.entry.content, 'Slept badly, but went for a walk.');
  assert.match(lastQuery.s, /ON CONFLICT \(user_id, entry_date\) DO UPDATE/);
});

test('GET /api/wellness/journal returns past entries', async () => {
  const response = await auth(request(app).get('/api/wellness/journal'));
  assert.equal(response.status, 200);
  assert.equal(response.body.entries[0].content, 'A quiet day.');
  assert.equal(lastQuery.values[0], USER.id);
  assert.match(lastQuery.s, /deleted_at IS NULL/);
});

test('DELETE /api/wellness/journal/:date soft-deletes the day', async () => {
  const response = await auth(request(app).delete('/api/wellness/journal/2026-10-19'));
  assert.equal(response.status, 200);
  assert.equal(response.body.deleted, true);
  assert.match(lastQuery.s, /SET deleted_at = now\(\)/);

  const bad = await auth(request(app).delete('/api/wellness/journal/19-10-2026'));
  assert.equal(bad.status, 400);
});

test('POST /api/wellness/journal/:date/restore undoes a delete', async () => {
  const response = await auth(request(app).post('/api/wellness/journal/2026-10-19/restore'));
  assert.equal(response.status, 200);
  assert.equal(response.body.restored, true);
  assert.match(lastQuery.s, /SET deleted_at = NULL/);
});

test('POST /api/wellness/activities rejects an unknown activity', async () => {
  const response = await auth(request(app).post('/api/wellness/activities')).send({ activity: 'run' });
  assert.equal(response.status, 400);
});

test('POST /api/wellness/activities logs a completion', async () => {
  const response = await auth(request(app).post('/api/wellness/activities')).send({ activity: 'breathing' });
  assert.equal(response.status, 201);
  assert.equal(response.body.activity.activity, 'breathing');
  assert.deepEqual(lastQuery.values, [USER.id, 'breathing']);
});

test('GET /api/wellness/activities totals the window', async () => {
  const response = await auth(request(app).get('/api/wellness/activities?days=7'));
  assert.equal(response.status, 200);
  assert.equal(response.body.days, 7);
  assert.equal(response.body.total, 4);
  assert.deepEqual(lastQuery.values, [USER.id, 7]);
});

test('journal counts are derived from live entries, not activity rows', async () => {
  await auth(request(app).get('/api/wellness/activities?days=7'));
  assert.match(lastQuery.s, /UNION ALL/);
  assert.match(lastQuery.s, /activity <> 'journal'/);
  assert.match(lastQuery.s, /deleted_at IS NULL/);
});

test('Vera\'s prompt carries wellness data and privacy guidance', () => {
  const prompt = veraSystem({
    wellness: {
      moods: [
        { date: '2026-10-19', mood: 'Calm', note: 'Slow morning', today: true },
        { date: '2026-10-18', mood: 'Tired', note: null },
      ],
      activities: [{ activity: 'breathing', count: 2 }],
      journalEntries30d: 1,
    },
  });
  assert.match(prompt, /Today's mood check-in: Calm \(note: "Slow morning"\)\./);
  assert.match(prompt, /breathing exercises: 2/);
  assert.match(prompt, /journal entries: 1/);
  assert.match(prompt, /last 30 days/);
  assert.match(prompt, /not a therapist/);
  assert.match(prompt, /must never claim to have read it/);
});
