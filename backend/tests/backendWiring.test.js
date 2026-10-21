const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');

process.env.NVIDIA_API_KEY = 'test-key';
process.env.TAVILY_API_KEY = 'test-key';

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({ verifyIdToken: async () => ({ uid: 'test-uid' }) });

const pool = require('../db/pool');

const REPORT = { overall_status: 'human_review_required', items_requiring_review: [{ claim: 'x', concern: 'y' }], sources_confirmed: 1, summary: 'Needs review.' };
const CAP_REPORT = { headline: 'Solid effort', strengths: ['Good structure'], focus: ['Cite sources'], report: 'You did well overall but should cite sources next time.' };

pool.query = async (sql, values = []) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('find_user_by_uid')) return { rows: [{ id: 7, industry_track_id: 1 }] };
  if (s.startsWith('INSERT INTO verification_analyses')) {
    return { rows: [{ id: 1, kind: values[1], document_name: values[2], overall_status: REPORT.overall_status, items_requiring_review: 1, sources_confirmed: 1, summary: REPORT.summary, report: REPORT, created_at: 'now' }] };
  }
  // History now reads the shared user_activity view.
  if (s.includes('FROM user_activity')) {
    return { rows: [
      { type: 'capstone', id: 3, title: 'Finance Capstone', feature: null, score: 92, passed: true, xp_earned: 70, created_at: '2026-10-13T10:00:00Z' },
      { type: 'task', id: 2, title: 'Verify the summary', feature: 'verification', score: 100, passed: true, xp_earned: 50, created_at: '2026-10-12T10:00:00Z' },
      { type: 'activity', id: 1, title: 'What is a token?', feature: null, score: null, passed: true, xp_earned: 10, created_at: '2026-10-11T10:00:00Z' },
    ] };
  }
  // Capstone analysis
  if (s.includes('FROM lab_capstone_assessments WHERE code')) return { rows: [{ id: 1, code: 'cap-fin', title: 'Finance Capstone', summary: 's', total_marks: 25, time_limit_seconds: 2400, pass_score: 60, max_attempts: 3, xp_reward: 70, token_reward: 15, achievement_code: 'capstone-finance' }] };
  if (s.includes('FROM lab_capstone_attempts WHERE id = $1 AND assessment_id = $2')) {
    return { rows: [{ id: 5, user_id: 7, answers: { 10: 1 }, presentation: { order: [10], options: {} }, auto_marks: 25, marks_awarded: 25, score: 100, passed: true, status: 'marked', timed_out: false, analysis: null, submitted_at: 'now' }] };
  }
  if (s.includes('SELECT id, type, prompt, marks, marking, correct FROM lab_capstone_questions')) {
    return { rows: [{ id: 10, type: 'multiple_choice', prompt: 'Pick', marks: 25, marking: 'auto', correct: { answer_index: 1 } }] };
  }
  if (s.startsWith('UPDATE lab_capstone_attempts SET analysis')) return { rows: [] };
  return { rows: [] };
};
pool.end = async () => {};

global.fetch = async (url, options) => {
  const u = String(url);
  if (u.includes('tavily')) {
    return { ok: true, json: async () => ({ results: [{ title: 'Citation source', url: 'https://cit.example', content: 'section 22 of POPIA' }] }) };
  }
  if (u.includes('example.com')) {
    return { ok: true, status: 200, text: async () => '<html><head><style>x{}</style></head><body><h1>Client contract</h1><script>bad()</script><p>Confidential terms apply.</p></body></html>' };
  }
  // NVIDIA
  const body = JSON.parse(options.body);
  const system = body.messages[0].content;
  const content = system.includes('performance report') ? JSON.stringify(CAP_REPORT) : JSON.stringify(REPORT);
  return { ok: true, json: async () => ({ choices: [{ message: { content } }], usage: {} }) };
};

const app = require('../app');
const auth = (req) => req.set('Authorization', 'Bearer test-token');

test('POST /api/verification/analyze resolves document, link, citation, text and context', async () => {
  const response = await auth(request(app).post('/api/verification/analyze')).send({
    kind: 'document',
    context: 'Extra background the user typed',
    sources: [
      { type: 'document', name: 'notes.txt', mime: 'text/plain', base64: Buffer.from('Key facts here').toString('base64') },
      { type: 'url', url: 'https://example.com/page' },
      { type: 'citation', text: 'POPIA section 22' },
      { type: 'text', text: 'A pasted claim' },
    ],
  });
  assert.equal(response.status, 201);
  assert.equal(response.body.inputs.length, 5);
  assert.deepEqual(response.body.inputs.map((i) => i.type), ['context', 'document', 'url', 'citation', 'text']);
  assert.equal(response.body.analysis.document_name, 'notes.txt');
  assert.ok(response.body.sources.some((s) => s.url === 'https://cit.example'));
  assert.equal(response.body.web_searched, true);
});

test('POST /api/verification/analyze rejects an unknown source type', async () => {
  const response = await auth(request(app).post('/api/verification/analyze')).send({ kind: 'claim', sources: [{ type: 'video', text: 'x' }] });
  assert.equal(response.status, 400);
});

test('POST /api/verification/analyze requires some input', async () => {
  const response = await auth(request(app).post('/api/verification/analyze')).send({ kind: 'claim' });
  assert.equal(response.status, 400);
});

test('POST capstone analysis returns Vera report and caches it', async () => {
  const response = await auth(request(app).post('/api/lab/assessments/cap-fin/attempts/5/analysis')).send({});
  assert.equal(response.status, 200);
  assert.equal(response.body.analysis.headline, 'Solid effort');
  assert.equal(response.body.cached, false);
});

test('GET /api/history merges tasks, activities and capstones newest first', async () => {
  const response = await auth(request(app).get('/api/history?limit=10'));
  assert.equal(response.status, 200);
  assert.equal(response.body.entries.length, 3);
  assert.deepEqual(response.body.entries.map((e) => e.type), ['capstone', 'task', 'activity']);
});
