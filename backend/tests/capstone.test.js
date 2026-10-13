const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({ verifyIdToken: async () => ({ uid: 'test-uid' }) });

const pool = require('../db/pool');

const ASSESSMENT = {
  id: 1, code: 'responsible-ai-capstone', title: 'Responsible AI at work — capstone',
  summary: 'Scenario-based.', time_limit_seconds: 900, pass_score: 60, max_attempts: 3,
  xp_reward: 100, token_reward: 5, achievement_code: 'capstone-responsible-ai',
};
const START_QUESTIONS = [
  { id: 10, type: 'multiple_choice', scenario: 's', prompt: 'p', payload: { options: ['A', 'B', 'C'] }, sort_order: 1 },
];
const SUBMIT_QUESTIONS = [
  { id: 10, type: 'multiple_choice', correct: { answer_index: 1 }, explanation: 'B is right.', points: 2 },
];

let usedCount = 0;
let attempt = { id: 5, presentation: { order: [10], options: { 10: [2, 0, 1] } }, started_at: new Date().toISOString(), submitted_at: null };
let priorPass = false;
let achievementExists = true;

pool.query = async (sql) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('FROM users WHERE firebase_uid')) return { rows: [{ id: 7, industry_track_id: 1 }] };
  if (s.includes('FROM lab_capstone_assessments WHERE code')) return { rows: [ASSESSMENT] };
  if (s.includes('FROM lab_capstone_assessments c')) return { rows: [{ ...ASSESSMENT, question_count: 4, attempts_used: usedCount, best_score: priorPass ? 80 : null }] };
  if (s.includes('COUNT(*)::int AS used')) return { rows: [{ used: usedCount }] };
  if (s.includes('SELECT id, type, scenario, prompt, payload, sort_order FROM lab_capstone_questions')) return { rows: START_QUESTIONS };
  if (s.includes('SELECT id, type, correct, explanation, points FROM lab_capstone_questions')) return { rows: SUBMIT_QUESTIONS };
  if (s.startsWith('INSERT INTO lab_capstone_attempts')) return { rows: [{ id: 5, started_at: new Date().toISOString() }] };
  if (s.includes('SELECT id, presentation, started_at, submitted_at FROM lab_capstone_attempts')) return { rows: [attempt] };
  return { rows: [] };
};
const fakeClient = {
  async query(sql) {
    const s = sql.replace(/\s+/g, ' ').trim();
    if (['BEGIN', 'COMMIT', 'ROLLBACK'].includes(s)) return { rows: [] };
    if (s.includes('SELECT 1 FROM lab_capstone_attempts')) return { rows: priorPass ? [{ '?column?': 1 }] : [] };
    if (s.includes('INSERT INTO user_achievements')) return { rows: achievementExists ? [{ achievement_id: 1 }] : [] };
    if (s.startsWith('INSERT INTO user_progress')) return { rows: [{ xp: 0, level: 1 }] };
    if (s.startsWith('INSERT INTO reward_token_events')) return { rowCount: 1, rows: [] };
    if (s.includes('UPDATE user_progress') && s.includes('SET tokens')) return { rowCount: 1, rows: [] };
    if (s.includes('UPDATE user_progress') && s.includes('SET xp')) return { rows: [{ xp: 100, level: 1, tokens: 5 }] };
    if (s.includes('UPDATE lab_capstone_attempts SET answers')) return { rows: [] };
    if (s.includes('COUNT(*)::int AS used')) return { rows: [{ used: usedCount + 1 }] };
    if (s.includes('FROM skill_scores')) return { rows: [] };
    if (s.includes('COUNT(*)::int AS total FROM interview_questions')) return { rows: [{ total: 0 }] };
    if (s.includes('FROM lab_capstone_attempts') && s.includes('GROUP BY')) return { rows: [{ graded: 1, average: 100 }] };
    if (s.includes('UPDATE user_progress') && s.includes('readiness_score')) return { rows: [] };
    return { rows: [] };
  },
  release() {},
};
pool.connect = async () => fakeClient;
pool.end = async () => {};

const app = require('../app');
const auth = (req) => req.set('Authorization', 'Bearer test-token');

test('GET /api/lab/assessments lists capstones with attempts remaining', async () => {
  usedCount = 0;
  const response = await auth(request(app).get('/api/lab/assessments'));
  assert.equal(response.status, 200);
  assert.equal(response.body.assessments[0].code, 'responsible-ai-capstone');
  assert.equal(response.body.assessments[0].attempts_remaining, 3);
  assert.equal(response.body.assessments[0].question_count, 4);
});

test('POST start returns a timed attempt and shuffled questions without answers', async () => {
  usedCount = 0;
  const response = await auth(request(app).post('/api/lab/assessments/responsible-ai-capstone/start')).send({});
  assert.equal(response.status, 201);
  assert.equal(response.body.attempt_id, 5);
  assert.equal(response.body.questions.length, 1);
  assert.equal(response.body.questions[0].payload.options.length, 3);
  assert.equal('correct' in response.body.questions[0], false);
  const span = new Date(response.body.expires_at) - new Date(response.body.started_at);
  assert.equal(Math.round(span / 1000), 900);
});

test('POST start refuses once attempts are exhausted', async () => {
  usedCount = 3;
  const response = await auth(request(app).post('/api/lab/assessments/responsible-ai-capstone/start')).send({});
  assert.equal(response.status, 409);
  usedCount = 0;
});

test('POST submit remaps shuffled options, grades and awards XP + tokens + badge', async () => {
  usedCount = 0;
  priorPass = false;
  attempt = { id: 5, presentation: { order: [10], options: { 10: [2, 0, 1] } }, started_at: new Date().toISOString(), submitted_at: null };
  // Presented index 2 maps back to original index 1, which is correct.
  const response = await auth(request(app).post('/api/lab/assessments/responsible-ai-capstone/submit')).send({ attempt_id: 5, answers: { 10: 2 } });
  assert.equal(response.status, 200);
  assert.equal(response.body.result.score, 100);
  assert.equal(response.body.result.passed, true);
  assert.equal(response.body.xp_earned, 100);
  assert.equal(response.body.tokens_earned, 5);
  assert.equal(response.body.achievement, 'capstone-responsible-ai');
});

test('POST submit marks a timed-out attempt failed and withholds rewards', async () => {
  priorPass = false;
  attempt = { id: 5, presentation: { order: [10], options: { 10: [2, 0, 1] } }, started_at: new Date(Date.now() - 20 * 60 * 1000).toISOString(), submitted_at: null };
  const response = await auth(request(app).post('/api/lab/assessments/responsible-ai-capstone/submit')).send({ attempt_id: 5, answers: { 10: 2 } });
  assert.equal(response.status, 200);
  assert.equal(response.body.result.timed_out, true);
  assert.equal(response.body.result.passed, false);
  assert.equal(response.body.xp_earned, 0);
});

test('POST submit rejects an already-submitted attempt', async () => {
  attempt = { id: 5, presentation: { order: [10], options: {} }, started_at: new Date().toISOString(), submitted_at: new Date().toISOString() };
  const response = await auth(request(app).post('/api/lab/assessments/responsible-ai-capstone/submit')).send({ attempt_id: 5, answers: { 10: 2 } });
  assert.equal(response.status, 409);
});

test('POST submit rejects answers that are not an object', async () => {
  const response = await auth(request(app).post('/api/lab/assessments/responsible-ai-capstone/submit')).send({ attempt_id: 5, answers: [2] });
  assert.equal(response.status, 400);
});
