const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');
const { gradeActivity } = require('../services/activityGrading');

// --- Unit: grading per type ------------------------------------------------
test('gradeActivity: multiple_choice compares the option index', () => {
  const correct = { answer_index: 2 };
  assert.equal(gradeActivity('multiple_choice', correct, 2), true);
  assert.equal(gradeActivity('multiple_choice', correct, 0), false);
  assert.equal(gradeActivity('multiple_choice', correct, '2'), false);
});

test('gradeActivity: true_false requires a boolean', () => {
  assert.equal(gradeActivity('true_false', { answer: false }, false), true);
  assert.equal(gradeActivity('true_false', { answer: false }, true), false);
});

test('gradeActivity: fill_blank is case-insensitive across accepted answers', () => {
  const correct = { accepted: ['n', 'number of periods'] };
  assert.equal(gradeActivity('fill_blank', correct, '  N '), true);
  assert.equal(gradeActivity('fill_blank', correct, 'NUMBER OF PERIODS'), true);
  assert.equal(gradeActivity('fill_blank', correct, 'r'), false);
  assert.equal(gradeActivity('fill_blank', correct, ''), false);
});

test('gradeActivity: matching needs every pair correct', () => {
  const correct = { mapping: { A: '1', B: '2' } };
  assert.equal(gradeActivity('matching', correct, { A: '1', B: '2' }), true);
  assert.equal(gradeActivity('matching', correct, { A: '1', B: '3' }), false);
  assert.equal(gradeActivity('matching', correct, { A: '1' }), false);
});

test('gradeActivity: ordering needs the exact sequence', () => {
  const correct = { order: ['a', 'b', 'c'] };
  assert.equal(gradeActivity('ordering', correct, ['a', 'b', 'c']), true);
  assert.equal(gradeActivity('ordering', correct, ['b', 'a', 'c']), false);
  assert.equal(gradeActivity('ordering', correct, ['a', 'b']), false);
});

// --- Endpoint: attempt awards XP once --------------------------------------
const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({ verifyIdToken: async () => ({ uid: 'test-uid' }) });

const pool = require('../db/pool');

const LESSON = { id: 1, code: 'finance-read-the-numbers', title: 'Reading...', summary: 'Sum', estimated_minutes: 8, level: 1, competency: 'Verification', is_original: false };
const ACTIVITY = { id: 3, lesson_id: 1, type: 'multiple_choice', correct: { answer_index: 2 }, explanation: 'Third option is right.', xp_reward: 10 };

let priorAttempt = false;
let activityMissing = false;
let xpAwardCalls = 0;

pool.query = async (sql) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('FROM users WHERE firebase_uid')) return { rows: [{ id: 7, industry_track_id: 1 }] };
  if (s.includes('FROM lab_activities a') && s.includes('JOIN lab_lessons')) return { rows: activityMissing ? [] : [ACTIVITY] };
  if (s.includes('FROM lab_lessons WHERE code')) return { rows: [LESSON] };
  if (s.includes('FROM lab_activities a')) return { rows: [{ id: 3, type: 'multiple_choice', prompt: 'p', payload: { options: ['a', 'b', 'c'] }, sort_order: 1, xp_reward: 10, passed: priorAttempt, attempted: priorAttempt }] };
  if (s.includes('INSERT INTO lab_lesson_progress')) return { rows: [] };
  if (s.includes('FROM lab_lesson_sections') || s.includes('FROM lab_questions')) return { rows: [] };
  if (s.includes('FROM lab_lesson_progress')) return { rows: [{ sections_completed: 0, activities_completed: 0, assessment_best_score: 0, status: 'in_progress', last_viewed_at: null }] };
  if (s.includes('FROM lesson_sources') || s.includes('FROM lesson_attributions') || s.includes('FROM lessons_needing_share_alike')) return { rows: [] };
  return { rows: [] };
};
const fakeClient = {
  async query(sql) {
    const s = sql.replace(/\s+/g, ' ').trim();
    if (['BEGIN', 'COMMIT', 'ROLLBACK'].includes(s)) return { rows: [] };
    if (s.includes('SELECT 1 FROM lab_activity_attempts')) return { rows: priorAttempt ? [{ '?column?': 1 }] : [] };
    if (s.includes('INSERT INTO lab_activity_attempts')) return { rows: [] };
    if (s.startsWith('INSERT INTO user_progress')) return { rows: [{ xp: 40, level: 1 }] };
    if (s.startsWith('INSERT INTO reward_token_events')) return { rowCount: 1, rows: [] };
    if (s.includes('UPDATE user_progress') && s.includes('SET tokens')) return { rowCount: 1, rows: [] };
    if (s.includes('UPDATE user_progress') && s.includes('SET xp')) { xpAwardCalls += 1; return { rows: [{ xp: 50, level: 1, tokens: 10 }] }; }
    return { rows: [] };
  },
  release() {},
};
pool.connect = async () => fakeClient;
pool.end = async () => {};

const app = require('../app');
const auth = (req) => req.set('Authorization', 'Bearer test-token');

test('lesson detail exposes activities without the answer key', async () => {
  priorAttempt = false;
  const response = await auth(request(app).get('/api/lab/lessons/finance-read-the-numbers'));
  assert.equal(response.status, 200);
  assert.equal(response.body.lesson.activities.length, 1);
  assert.equal('correct' in response.body.lesson.activities[0], false);
  assert.equal('answer_index' in response.body.lesson.activities[0], false);
  assert.equal(response.body.lesson.activities[0].passed, false);
  assert.equal(response.body.lesson.activities[0].attempted, false);
});

test('first correct attempt awards the activity XP', async () => {
  priorAttempt = false;
  xpAwardCalls = 0;
  const response = await auth(request(app).post('/api/lab/activities/3/attempt')).send({ response: 2 });
  assert.equal(response.status, 200);
  assert.equal(response.body.result.passed, true);
  assert.equal(response.body.result.practice, false);
  assert.equal(response.body.result.xp_earned, 10);
  assert.equal(response.body.explanation, 'Third option is right.');
  assert.equal(xpAwardCalls, 1);
});

test('a repeat pass is practice and earns no XP', async () => {
  priorAttempt = true;
  xpAwardCalls = 0;
  const response = await auth(request(app).post('/api/lab/activities/3/attempt')).send({ response: 2 });
  assert.equal(response.status, 200);
  assert.equal(response.body.result.passed, true);
  assert.equal(response.body.result.practice, true);
  assert.equal(response.body.result.xp_earned, 0);
  assert.equal(xpAwardCalls, 0);
});

test('a correct answer after a wrong first attempt is practice (no XP)', async () => {
  priorAttempt = true; // a wrong first attempt already recorded
  xpAwardCalls = 0;
  const response = await auth(request(app).post('/api/lab/activities/3/attempt')).send({ response: 2 });
  assert.equal(response.status, 200);
  assert.equal(response.body.result.correct, true);
  assert.equal(response.body.result.practice, true);
  assert.equal(response.body.result.xp_earned, 0);
  assert.equal(xpAwardCalls, 0);
});

test('an incorrect attempt passes nothing and earns no XP', async () => {
  priorAttempt = false;
  xpAwardCalls = 0;
  const response = await auth(request(app).post('/api/lab/activities/3/attempt')).send({ response: 0 });
  assert.equal(response.status, 200);
  assert.equal(response.body.result.correct, false);
  assert.equal(response.body.result.xp_earned, 0);
  assert.equal(xpAwardCalls, 0);
});

test('an activity outside the selected track is not found', async () => {
  activityMissing = true;
  const response = await auth(request(app).post('/api/lab/activities/999/attempt')).send({ response: 1 });
  assert.equal(response.status, 404);
  activityMissing = false;
});
