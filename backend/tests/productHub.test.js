const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');

// Route to documented defaults and provide a fake key before app load.
process.env.NVIDIA_API_KEY = 'test-key';
delete process.env.NVIDIA_MODEL;
delete process.env.NVIDIA_MODEL_ANALYSIS;
delete process.env.NVIDIA_MODEL_CHAT;
delete process.env.NVIDIA_MODEL_LIGHT;
delete process.env.NVIDIA_MODEL_FALLBACK;
// Keep the suite hermetic: no real Tavily calls during tests.
delete process.env.TAVILY_API_KEY;

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({
  verifyIdToken: async () => ({ uid: 'test-uid', email: 'test@example.com', name: 'Test User' }),
});

const pool = require('../db/pool');

const USER = { id: 7, industry_track_id: 1 };
const USER_WITH_TRACK = { id: 7, industry_track_id: 1, track_name: 'Finance' };
const WALLET = { xp: 2450, level: 10, tokens: 50 };
const REWARDS = [
  { id: 1, code: 'coffee', title: 'Coffee break', subtitle: 's', cost_tokens: 10, image_asset: 'reward_coffee.png', note: 'n' },
  { id: 2, code: 'm365', title: 'Microsoft 365 boost', subtitle: 's', cost_tokens: 30, image_asset: 'reward_m365.png', note: 'n' },
];
const LESSON = { id: 1, code: 'ai-fundamentals', title: 'AI fundamentals', summary: 'Sum', estimated_minutes: 8, level: 1 };
const VERIFICATION_ROW = {
  id: 1, kind: 'document', document_name: null, overall_status: 'insufficient_evidence',
  items_requiring_review: 1, sources_confirmed: 0, summary: 'Needs review.',
  report: { overall_status: 'insufficient_evidence' }, created_at: '2026-10-12T00:00:00.000Z',
};

let lockedTokens = 50;
const queries = [];
const fetchLog = [];

pool.query = async (sql, values = []) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  queries.push({ sql: s, values });
  if (s.includes('FROM users u') && s.includes('track_name')) return { rows: [USER_WITH_TRACK] };
  if (s.includes('FROM users WHERE firebase_uid')) return { rows: [USER] };
  if (s.includes('INSERT INTO verification_analyses')) return { rows: [VERIFICATION_ROW] };
  if (s.includes('FROM verification_analyses')) return { rows: [VERIFICATION_ROW] };
  if (s.includes('FROM lab_lessons WHERE code')) return { rows: [LESSON] };
  if (s.includes('FROM lab_lessons l')) {
    return { rows: [{ ...LESSON, sort_order: 10, sections_count: 3, activities_count: 2, questions_count: 3, sections_completed: 0, activities_completed: 0, assessment_best_score: 0, status: 'not_started' }] };
  }
  if (s.includes('FROM lab_lesson_sections')) return { rows: [{ id: 1, heading: 'What a model does', body: 'b', sort_order: 1 }] };
  if (s.includes('FROM lab_activities')) return { rows: [{ id: 1, kind: 'reflection', title: 'Reflect', instructions: 'i', task_id: null, sort_order: 1 }] };
  if (s.includes('FROM lab_questions') && s.includes('correct_index')) {
    return { rows: [
      { id: 1, options: ['a', 'b', 'c'], correct_index: 1, explanation: 'e' },
      { id: 2, options: ['a', 'b'], correct_index: 0, explanation: 'e2' },
    ] };
  }
  if (s.includes('FROM lab_questions')) return { rows: [{ id: 1, prompt: 'p', options: ['a', 'b', 'c'], sort_order: 1 }] };
  if (s.includes('FROM lab_lesson_progress')) return { rows: [{ sections_completed: 1, activities_completed: 0, assessment_best_score: 0, status: 'in_progress', updated_at: 'now' }] };
  if (s.includes('FROM rewards')) return { rows: REWARDS };
  if (s.includes('FROM user_progress WHERE user_id')) return { rows: [WALLET] };
  if (s.includes('FROM user_avatars')) return { rows: [{ mime: 'image/png', bytes: Buffer.from('avatarbytes') }] };
  if (s.includes('INSERT INTO user_avatars')) return { rows: [{ mime: 'image/png', updated_at: 'now', bytes: 11 }] };
  return { rows: [] };
};
pool.end = async () => {};

const fakeClient = {
  async query(sql, values = []) {
    const s = sql.replace(/\s+/g, ' ').trim();
    queries.push({ sql: s, values });
    if (['BEGIN', 'COMMIT', 'ROLLBACK'].includes(s)) return { rows: [] };
    if (s.includes('FROM rewards WHERE code')) return { rows: REWARDS.filter((r) => r.code === values[0]) };
    if (s.includes('FROM user_progress WHERE user_id') && s.includes('FOR UPDATE')) return { rows: [{ tokens: lockedTokens }] };
    if (s.includes('INSERT INTO reward_redemptions')) return { rows: [{ id: 1, reward_id: 1, cost_tokens: 10, status: 'confirmed', created_at: 'now' }] };
    if (s.includes('UPDATE user_progress SET tokens = tokens -')) return { rows: [] };
    if (s.includes('INSERT INTO reward_token_events')) return { rowCount: 1, rows: [] };
    if (s.includes('INSERT INTO lab_assessment_attempts')) return { rows: [] };
    if (s.includes('INSERT INTO lab_lesson_progress')) return { rows: [{ sections_completed: 0, activities_completed: 0, assessment_best_score: 100, status: 'completed', updated_at: 'now' }] };
    if (s.includes('UPDATE lab_lesson_progress p')) return { rows: [] };
    if (s.includes('FROM lab_questions')) return { rows: [{ id: 1, options: ['a', 'b', 'c'], correct_index: 1, explanation: 'e' }, { id: 2, options: ['a', 'b'], correct_index: 0, explanation: 'e2' }] };
    if (s.includes('FROM user_progress WHERE user_id')) return { rows: [WALLET] };
    return { rows: [] };
  },
  release() {},
};
pool.connect = async () => fakeClient;

global.fetch = async (url, options) => {
  const body = JSON.parse(options.body);
  fetchLog.push(body);
  const system = body.messages[0].content;
  const content = system.includes('verification analyst')
    ? JSON.stringify({
        overall_status: 'insufficient_evidence',
        items_requiring_review: [{ claim: 'Revenue grew 15%', concern: 'No source cited' }],
        sources_confirmed: 0,
        summary: 'Needs human review.',
      })
    : 'Here is a helpful hint.';
  return { ok: true, json: async () => ({ choices: [{ message: { content } }], usage: {} }) };
};

const app = require('../app');

const auth = (req) => req.set('Authorization', 'Bearer test-token');

test('POST /api/verification/analyze stores metadata + report and never the raw input', async () => {
  fetchLog.length = 0;
  queries.length = 0;
  const response = await auth(request(app).post('/api/verification/analyze')).send({
    kind: 'document',
    document_name: 'q3.pdf',
    content: 'A confidential paragraph that must not be persisted.',
  });

  assert.equal(response.status, 201);
  assert.equal(response.body.analysis.overall_status, 'insufficient_evidence');
  assert.equal(fetchLog[0].model, 'nvidia/nemotron-3.5-super-vl-120b-a12b');

  const insert = queries.find((q) => q.sql.startsWith('INSERT INTO verification_analyses'));
  assert.ok(insert);
  assert.equal(insert.sql.includes('input_content'), false);
  assert.equal(insert.values.some((v) => String(v).includes('confidential paragraph')), false);
});

test('POST /api/verification/analyze rejects an unknown kind', async () => {
  const response = await auth(request(app).post('/api/verification/analyze')).send({ kind: 'rumour', content: 'x' });
  assert.equal(response.status, 400);
});

test('GET /api/lab/lessons returns the catalog with progress', async () => {
  const response = await auth(request(app).get('/api/lab/lessons'));
  assert.equal(response.status, 200);
  assert.equal(response.body.lessons.length, 1);
  assert.equal(response.body.lessons[0].code, 'ai-fundamentals');
});

test('GET /api/lab/lessons/:code withholds the answer key', async () => {
  const response = await auth(request(app).get('/api/lab/lessons/ai-fundamentals'));
  assert.equal(response.status, 200);
  assert.equal(response.body.lesson.questions.length, 1);
  assert.equal('correct_index' in response.body.lesson.questions[0], false);
  assert.equal('explanation' in response.body.lesson.questions[0], false);
});

test('POST /api/lab/lessons/:code/assessment grades server-side and reveals explanations', async () => {
  const response = await auth(request(app).post('/api/lab/lessons/ai-fundamentals/assessment')).send({ answers: [1, 0] });
  assert.equal(response.status, 201);
  assert.equal(response.body.result.total, 2);
  assert.equal(response.body.result.correct_count, 2);
  assert.equal(response.body.result.score, 100);
  assert.equal(response.body.result.passed, true);
  assert.equal(response.body.questions[0].correct_index, 1);
});

test('POST /api/lab/lessons/:code/assessment rejects a wrong number of answers', async () => {
  const response = await auth(request(app).post('/api/lab/lessons/ai-fundamentals/assessment')).send({ answers: [1] });
  assert.equal(response.status, 400);
});

test('GET /api/rewards returns the catalog with affordability and a token wallet', async () => {
  const response = await auth(request(app).get('/api/rewards'));
  assert.equal(response.status, 200);
  assert.equal(response.body.wallet.tokens, 50);
  assert.equal(response.body.wallet.next_level_xp, 5200);
  assert.equal(response.body.rewards.every((r) => typeof r.can_afford === 'boolean'), true);
});

test('POST /api/rewards/:code/redeem spends tokens and never touches XP', async () => {
  lockedTokens = 50;
  queries.length = 0;
  const response = await auth(request(app).post('/api/rewards/coffee/redeem')).send({});
  assert.equal(response.status, 201);
  assert.equal(response.body.redemption.cost_tokens, 10);

  const spend = queries.find((q) => q.sql.startsWith('UPDATE user_progress SET tokens = tokens -'));
  assert.ok(spend);
  assert.deepEqual(spend.values, [10, 7]);
  assert.equal(queries.some((q) => q.sql.includes('SET xp')), false);
});

test('POST /api/rewards/:code/redeem refuses when tokens are short', async () => {
  lockedTokens = 5;
  const response = await auth(request(app).post('/api/rewards/m365/redeem')).send({});
  assert.equal(response.status, 409);
  assert.equal(response.body.cost_tokens, 30);
});

test('POST /api/assistant/chat works without a task_id (general assistant)', async () => {
  fetchLog.length = 0;
  const response = await auth(request(app).post('/api/assistant/chat')).send({
    messages: [{ role: 'user', content: 'How do I verify a claim?' }],
  });
  assert.equal(response.status, 200);
  assert.equal(response.body.reply, 'Here is a helpful hint.');
  assert.equal(fetchLog[0].model, 'nvidia/nemotron-3.5-super-vl-120b-a12b');
  assert.equal(fetchLog[0].messages[0].content.includes('verification analyst'), false);
});

test('POST /api/users/avatar stores an image and GET returns it', async () => {
  // ~50KB payload proves the path-scoped parser raised the avatar body limit
  // above the 32kb global one.
  const upload = await auth(request(app).post('/api/users/avatar')).send({
    mime: 'image/png',
    image_base64: Buffer.alloc(50000, 1).toString('base64'),
  });
  assert.equal(upload.status, 200);
  assert.equal(upload.body.avatar.mime, 'image/png');

  const fetchAvatar = await auth(request(app).get('/api/users/avatar'));
  assert.equal(fetchAvatar.status, 200);
  assert.equal(fetchAvatar.headers['content-type'], 'image/png');
});

test('POST /api/users/avatar rejects a non-image mime', async () => {
  const response = await auth(request(app).post('/api/users/avatar')).send({
    mime: 'application/pdf',
    image_base64: Buffer.from('x').toString('base64'),
  });
  assert.equal(response.status, 400);
});
