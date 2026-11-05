const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({ verifyIdToken: async () => ({ uid: 'test-uid' }) });

const pool = require('../db/pool');

const FIXTURES = {
  1: { name: 'Finance', readiness: 72, tier: 'Proficient', skills: [{ dimension: 'Verification', score: 72, attempts_count: 3 }], completed: 4 },
  2: { name: 'Legal', readiness: 0, tier: 'Novice', skills: [], completed: 0 },
};
let activeTrack = 1;
const queries = [];

pool.query = async (sql, values = []) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  queries.push({ sql: s, values });
  if (s.includes('find_user_by_uid')) return { rows: [{ id: 7, industry_track_id: activeTrack }] };
  if (s.includes('COALESCE(tp.readiness_score')) {
    const fixture = FIXTURES[activeTrack];
    return {
      rows: [{
        user_id: 7, xp: 420, level: 4, streak: 6, tokens: 25, last_activity_date: null,
        readiness_score: fixture.readiness, tier: fixture.tier,
        skill_scores: fixture.skills, completed_tasks: fixture.completed,
      }],
    };
  }
  if (s.includes('FROM user_activity')) {
    const track = values[5];
    return {
      rows: [
        { type: 'task', id: 1, title: 'Finance task', track_id: 1 },
        { type: 'task', id: 2, title: 'Legal task', track_id: 2 },
      ].filter((row) => track === 'all' || row.track_id === activeTrack),
    };
  }
  return { rows: [] };
};
pool.end = async () => {};

const app = require('../app');
const auth = (req) => req.set('Authorization', 'Bearer test-token');

test('progress reads the active track and its skill rows only', async () => {
  activeTrack = 2;
  queries.length = 0;
  const response = await auth(request(app).get('/api/progress/me'));

  assert.equal(response.status, 200);
  assert.equal(response.body.progress.readiness_score, 0);
  assert.equal(response.body.progress.tier, 'Novice');
  assert.deepEqual(response.body.progress.skill_scores, []);
  assert.equal(response.body.progress.completed_tasks, 0);

  const sql = queries.find((entry) => entry.sql.includes('COALESCE(tp.readiness_score'));
  assert.match(sql.sql, /tp\.track_id = u\.industry_track_id/);
  assert.match(sql.sql, /ss\.track_id = u\.industry_track_id/);
  assert.match(sql.sql, /t\.track_id = u\.industry_track_id/);
});

test('switching back restores the old track progress', async () => {
  activeTrack = 1;
  const response = await auth(request(app).get('/api/progress/me'));
  assert.equal(response.body.progress.readiness_score, 72);
  assert.equal(response.body.progress.tier, 'Proficient');
  assert.equal(response.body.progress.skill_scores.length, 1);
});

test('history defaults to the active track and ?track=all restores the full timeline', async () => {
  activeTrack = 2;

  const current = await auth(request(app).get('/api/history'));
  assert.equal(current.status, 200);
  assert.equal(current.body.track, 'current');
  assert.deepEqual(current.body.entries.map((e) => e.title), ['Legal task']);
  const sql = queries.filter((entry) => entry.sql.includes('FROM user_activity')).at(-1);
  assert.match(sql.sql, /\$6::text = 'all'/);
  assert.match(sql.sql, /track_id = \(SELECT industry_track_id FROM users WHERE id = \$1\)/);

  const all = await auth(request(app).get('/api/history?track=all'));
  assert.equal(all.body.track, 'all');
  assert.deepEqual(all.body.entries.map((e) => e.title), ['Finance task', 'Legal task']);

  const bad = await auth(request(app).get('/api/history?track=finance'));
  assert.equal(bad.status, 400);
  assert.match(bad.body.error, /current or all/);
});
