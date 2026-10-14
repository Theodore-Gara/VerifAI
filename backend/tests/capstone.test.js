const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');
const { markQuestion, rubricAward } = require('../services/capstoneMarking');

// --- Unit: marking ---------------------------------------------------------
test('numeric marks within tolerance (parts summed)', () => {
  const q = { type: 'numeric', marking: 'auto', marks: 5, correct: { parts: [{ answer: 507178, tolerance: 100, marks: 2 }, { answer: 27178, tolerance: 100, marks: 3 }] } };
  assert.equal(markQuestion(q, [507100, 27178]).awarded, 5);
  assert.equal(markQuestion(q, [400000, 27178]).awarded, 3);
});

test('multi_select scores +2 per correct, -1 per wrong, floor 0', () => {
  const q = { type: 'multi_select', marking: 'auto', marks: 4, correct: { indices: [0, 2] } };
  assert.equal(markQuestion(q, [0, 2]).awarded, 4);
  assert.equal(markQuestion(q, [0, 2, 1]).awarded, 3);
  assert.equal(markQuestion(q, [1, 3]).awarded, 0);
});

test('extended_response is returned as pending, never auto-marked', () => {
  const q = { type: 'extended_response', marking: 'rubric', marks: 8, correct: null };
  assert.equal(markQuestion(q, 'anything').pending, true);
});

test('rubricAward caps the sum at the question marks', () => {
  assert.equal(rubricAward({ marks: 8 }, [2, 2, 2, 1, 1]), 8);
  assert.equal(rubricAward({ marks: 8 }, 6), 6);
  assert.equal(rubricAward({ marks: 8 }, null), 0);
});

// --- Endpoint --------------------------------------------------------------
const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({ verifyIdToken: async () => ({ uid: 'test-uid' }) });

const pool = require('../db/pool');

process.env.NVIDIA_API_KEY = 'test-key';
global.fetch = async () => ({
  ok: true,
  json: async () => ({
    choices: [{ message: { content: JSON.stringify({ criteria: [{ criterion: 'Clear recommendation', marks_awarded: 6, comment: 'ok' }], total_awarded: 6, feedback: 'Solid.' }) } }],
    usage: {},
  }),
});

const ASSESSMENT = {
  id: 1, code: 'cap-fin', title: 'Finance Capstone', summary: 'Scenario.',
  scenario: { title: 'Mokoena Print Studio', background: 'b', facts: ['f'] },
  instructions: ['Answer ALL questions.'],
  total_marks: 25, grade_bands: [{ label: 'Distinction', min_percent: 75 }],
  time_limit_seconds: 2400, pass_score: 60, max_attempts: 3,
  xp_reward: 70, token_reward: 15, achievement_code: 'capstone-finance',
};
const START_QUESTIONS = [
  { id: 10, type: 'multiple_choice', section: 'Section A · Application', scenario: null, prompt: 'p', payload: { options: ['A', 'B', 'C'] }, code_lines: null, word_limit: null, competency: 'c', cognitive_level: 'apply', marks: 25, marking: 'auto', sort_order: 1 },
  { id: 12, type: 'multiple_choice', section: 'Section B · Scenario', scenario: null, prompt: 'p2', payload: { options: ['D', 'E'] }, code_lines: null, word_limit: null, competency: 'c', cognitive_level: 'apply', marks: 50, marking: 'auto', sort_order: 2 },
];
const AUTO_QUESTIONS = [{ id: 10, type: 'multiple_choice', correct: { answer_index: 1 }, explanation: 'B.', marks: 25, marking: 'auto' }];
const RUBRIC_QUESTIONS = [
  { id: 10, type: 'multiple_choice', correct: { answer_index: 1 }, explanation: 'B.', marks: 17, marking: 'auto' },
  { id: 11, type: 'extended_response', correct: null, explanation: null, marks: 8, marking: 'rubric' },
];
const MARK_QUESTIONS = [{ id: 11, type: 'extended_response', marks: 8, marking: 'rubric' }];

let usedCount = 0;
let attempt = { id: 5, presentation: { order: [10], options: { 10: [2, 0, 1] } }, started_at: new Date().toISOString(), submitted_at: null };
let gradedQuestions = AUTO_QUESTIONS;
let priorPass = false;

pool.query = async (sql) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('FROM users WHERE firebase_uid')) return { rows: [{ id: 7, industry_track_id: 1 }] };
  if (s.includes('FROM lab_capstone_assessments WHERE code')) return { rows: [ASSESSMENT] };
  if (s.includes('FROM lab_capstone_assessments c')) return { rows: [{ ...ASSESSMENT, question_count: 6, attempts_used: usedCount, best_score: priorPass ? 80 : null }] };
  if (s.includes('COUNT(*)::int AS used')) return { rows: [{ used: usedCount }] };
  if (s.includes('SELECT id, answers, auto_marks, status FROM lab_capstone_attempts')) return { rows: [{ id: 5, answers: { 11: 'my answer' }, auto_marks: 17, status: 'pending_marking' }] };
  if (s.includes('SELECT id, type, prompt, marks, marking, rubric, model_answer FROM lab_capstone_questions')) {
    return { rows: [{ id: 11, type: 'extended_response', prompt: 'Write a note.', marks: 8, marking: 'rubric', rubric: [{ criterion: 'Clear recommendation', marks: 2 }], model_answer: 'Model.' }] };
  }
  if (s.includes('SELECT a.id, a.auto_marks')) return { rows: [{ id: 5, auto_marks: 17, timed_out: false, status: 'pending_marking', user_id: 7, owner_track: 1 }] };
  if (s.includes('SELECT id, type, correct, explanation, marks, marking FROM lab_capstone_questions')) return { rows: gradedQuestions };
  if (s.includes('SELECT id, type, marks, marking FROM lab_capstone_questions')) return { rows: MARK_QUESTIONS };
  if (s.includes('FROM lab_capstone_questions')) return { rows: START_QUESTIONS };
  if (s.startsWith('INSERT INTO lab_capstone_attempts')) return { rows: [{ id: 5, started_at: new Date().toISOString() }] };
  if (s.includes('SELECT id, presentation, started_at, submitted_at FROM lab_capstone_attempts')) return { rows: [attempt] };
  if (s.includes('MAX(score) AS best_score')) return { rows: [{ best_score: priorPass ? 80 : null }] };
  return { rows: [] };
};
const fakeClient = {
  async query(sql) {
    const s = sql.replace(/\s+/g, ' ').trim();
    if (['BEGIN', 'COMMIT', 'ROLLBACK'].includes(s)) return { rows: [] };
    if (s.includes('SELECT 1 FROM lab_capstone_attempts')) return { rows: priorPass ? [{ '?column?': 1 }] : [] };
    if (s.includes('INSERT INTO user_achievements')) return { rows: [{ achievement_id: 1 }] };
    if (s.startsWith('INSERT INTO user_progress')) return { rows: [{ xp: 0, level: 1 }] };
    if (s.startsWith('INSERT INTO reward_token_events')) return { rowCount: 1, rows: [] };
    if (s.includes('UPDATE user_progress') && s.includes('SET tokens')) return { rowCount: 1, rows: [] };
    if (s.includes('UPDATE user_progress') && s.includes('SET xp')) return { rows: [{ xp: 70, level: 1, tokens: 15 }] };
    if (s.includes('UPDATE lab_capstone_attempts')) return { rows: [] };
    if (s.includes('COUNT(*)::int AS used')) return { rows: [{ used: usedCount + 1 }] };
    if (s.includes('FROM skill_scores')) return { rows: [] };
    if (s.includes('COUNT(*)::int AS total FROM interview_questions')) return { rows: [{ total: 0 }] };
    if (s.includes('FROM lab_capstone_attempts') && s.includes('GROUP BY')) return { rows: [{ graded: 1, average: 100 }] };
    if (s.includes('readiness_score')) return { rows: [] };
    return { rows: [] };
  },
  release() {},
};
pool.connect = async () => fakeClient;
pool.end = async () => {};

const app = require('../app');
const auth = (req) => req.set('Authorization', 'Bearer test-token');

test('GET /api/lab/assessments lists capstones with attempts and view_only', async () => {
  usedCount = 0;
  const response = await auth(request(app).get('/api/lab/assessments'));
  assert.equal(response.status, 200);
  assert.equal(response.body.assessments[0].attempts_remaining, 3);
  assert.equal(response.body.assessments[0].view_only, false);
  assert.equal(response.body.assessments[0].total_marks, 25);
});

test('POST start returns a 40-minute timed attempt with the scenario and no answers', async () => {
  usedCount = 0;
  const response = await auth(request(app).post('/api/lab/assessments/cap-fin/start')).send({});
  assert.equal(response.status, 201);
  assert.equal(response.body.scenario.title, 'Mokoena Print Studio');
  assert.equal(response.body.total_marks, 25);
  const span = new Date(response.body.expires_at) - new Date(response.body.started_at);
  assert.equal(Math.round(span / 1000), 2400);
  assert.equal('correct' in response.body.questions[0], false);
  assert.equal('rubric' in response.body.questions[0], false);
});

test('start returns questions in section order with their section labels', async () => {
  usedCount = 0;
  const response = await auth(request(app).post('/api/lab/assessments/cap-fin/start')).send({});
  assert.equal(response.status, 201);
  assert.deepEqual(response.body.questions.map((q) => q.id), [10, 12]);
  assert.equal(response.body.questions[0].section, 'Section A · Application');
  assert.equal(response.body.questions[1].section, 'Section B · Scenario');
});

test('GET /api/lab/assessments/:code is view_only after three attempts', async () => {
  usedCount = 3;
  const response = await auth(request(app).get('/api/lab/assessments/cap-fin'));
  assert.equal(response.status, 200);
  assert.equal(response.body.assessment.view_only, true);
  assert.ok(response.body.questions.length >= 1);
  usedCount = 0;
});

test('POST start refuses once attempts are exhausted', async () => {
  usedCount = 3;
  const response = await auth(request(app).post('/api/lab/assessments/cap-fin/start')).send({});
  assert.equal(response.status, 409);
  usedCount = 0;
});

test('auto-only paper finalises on submit and awards 70 XP + 15 tokens + badge', async () => {
  usedCount = 0;
  priorPass = false;
  gradedQuestions = AUTO_QUESTIONS;
  attempt = { id: 5, presentation: { order: [10], options: { 10: [2, 0, 1] } }, started_at: new Date().toISOString(), submitted_at: null };
  const response = await auth(request(app).post('/api/lab/assessments/cap-fin/submit')).send({ attempt_id: 5, answers: { 10: 2 } });
  assert.equal(response.status, 200);
  assert.equal(response.body.result.pending_marking, false);
  assert.equal(response.body.result.score, 100);
  assert.equal(response.body.result.passed, true);
  assert.equal(response.body.xp_earned, 70);
  assert.equal(response.body.tokens_earned, 15);
  assert.equal(response.body.achievement, 'capstone-finance');
});

test('a paper with a rubric question is held for marking', async () => {
  gradedQuestions = RUBRIC_QUESTIONS;
  attempt = { id: 5, presentation: { order: [10], options: { 10: [2, 0, 1] } }, started_at: new Date().toISOString(), submitted_at: null };
  const response = await auth(request(app).post('/api/lab/assessments/cap-fin/submit')).send({ attempt_id: 5, answers: { 10: 2, 11: 'my answer' } });
  assert.equal(response.status, 202);
  assert.equal(response.body.result.pending_marking, true);
  assert.equal(response.body.result.auto_marks, 17);
  assert.equal(response.body.xp_earned, undefined);
});

test('marking a pending rubric paper finalises the score and awards', async () => {
  priorPass = false;
  const response = await auth(request(app).post('/api/lab/assessments/cap-fin/attempts/5/mark')).send({ marks: { 11: 6 }, marked_by: 'reviewer@verifai' });
  assert.equal(response.status, 200);
  assert.equal(response.body.result.marks_awarded, 23);
  assert.equal(response.body.result.score, 92);
  assert.equal(response.body.result.passed, true);
  assert.equal(response.body.xp_earned, 70);
});

test('a first pass on the third attempt still awards (prior failures do not block it)', async () => {
  priorPass = false; // two failed attempts exist but none passed
  gradedQuestions = AUTO_QUESTIONS;
  attempt = { id: 5, presentation: { order: [10], options: { 10: [2, 0, 1] } }, started_at: new Date().toISOString(), submitted_at: null };
  const response = await auth(request(app).post('/api/lab/assessments/cap-fin/submit')).send({ attempt_id: 5, answers: { 10: 2 } });
  assert.equal(response.body.result.passed, true);
  assert.equal(response.body.xp_earned, 70);
});

test('a timed-out attempt fails and withholds rewards', async () => {
  priorPass = false;
  gradedQuestions = AUTO_QUESTIONS;
  attempt = { id: 5, presentation: { order: [10], options: { 10: [2, 0, 1] } }, started_at: new Date(Date.now() - 60 * 60 * 1000).toISOString(), submitted_at: null };
  const response = await auth(request(app).post('/api/lab/assessments/cap-fin/submit')).send({ attempt_id: 5, answers: { 10: 2 } });
  assert.equal(response.body.result.timed_out, true);
  assert.equal(response.body.result.passed, false);
  assert.equal(response.body.xp_earned, 0);
});

test('POST ai-mark suggests rubric marks without finalising the attempt', async () => {
  const response = await auth(request(app).post('/api/lab/assessments/cap-fin/attempts/5/ai-mark')).send({});
  assert.equal(response.status, 200);
  assert.equal(response.body.suggested_marks, 6);
  assert.equal(response.body.auto_marks, 17);
  assert.equal(response.body.projected_score, Math.round((100 * 23) / 25));
  assert.equal(response.body.ai_suggestion['11'].total_awarded, 6);
  assert.match(response.body.note, /human spot-check/);
});
