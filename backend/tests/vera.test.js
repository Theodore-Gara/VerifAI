const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');
const { buildUserContext, describeContext, buildTips } = require('../services/veraContext');

// --- Unit: context + tips --------------------------------------------------
test('buildUserContext derives weak areas, strengths and recent failures', async () => {
  const executor = {
    async query(sql) {
      const s = sql.replace(/\s+/g, ' ').trim();
      if (s.includes('FROM user_progress')) return { rows: [{ xp: 310, level: 2, streak: 3, tokens: 20, readiness_score: 64 }] };
      if (s.includes('FROM skill_scores')) {
        return { rows: [{ dimension: 'Verification', score: 80, attempts_count: 4 }, { dimension: 'AI Judgement', score: 45, attempts_count: 3 }] };
      }
      if (s.includes('FROM task_attempts ta JOIN tasks')) return { rows: [{ feature: 'judgement', passed: false, score: 40, submitted_at: 'now' }] };
      if (s.includes('FROM lab_lesson_progress')) return { rows: [{ title: 'Fact-checking with AI', status: 'in_progress', assessment_best_score: 50 }] };
      if (s.includes('FROM lab_capstone_attempts a JOIN lab_capstone_assessments')) return { rows: [{ title: 'Finance Capstone', score: null, passed: null, status: 'pending_marking' }] };
      return { rows: [] };
    },
  };
  const ctx = await buildUserContext(executor, 7);
  assert.equal(ctx.weak[0].dimension, 'AI Judgement');
  assert.equal(ctx.strengths[0].dimension, 'Verification');
  assert.equal(ctx.failuresByFeature.judgement, 1);
  const text = describeContext(ctx);
  assert.match(text, /Weak areas/);
  assert.match(text, /Level 2/);
  const tips = buildTips(ctx);
  assert.ok(tips.length >= 1);
  assert.match(tips.map((t) => t.title).join(' '), /Focus your practice/);
});

// --- Endpoint --------------------------------------------------------------
process.env.NVIDIA_API_KEY = 'test-key';
process.env.TAVILY_API_KEY = 'test-key';
const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({ verifyIdToken: async () => ({ uid: 'test-uid' }) });

const pool = require('../db/pool');
const writes = [];

pool.query = async (sql, values = []) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  writes.push({ sql: s, values });
  if (s.includes('WHERE u.firebase_uid')) return { rows: [{ id: 7, industry_track_id: 1, display_name: 'Theo', created_at: '2026-01-01T00:00:00.000Z', track_name: 'Finance' }] };
  if (s.includes('INSERT INTO vera_sessions')) return { rows: [{ id: 11 }] };
  if (s.includes('INSERT INTO vera_messages')) return { rows: [] };
  if (s.includes('UPDATE vera_sessions')) return { rows: [] };
  if (s.includes('INSERT INTO vera_memories')) return { rows: [{ id: 1, kind: values[1], content: values[2], source: 'chat', created_at: 'now', updated_at: 'now' }] };
  if (s.includes('FROM vera_memories WHERE user_id')) return { rows: [] };
  if (s.includes('DELETE FROM vera_memories')) return { rows: [{ id: Number(values[0]) === 1 ? 1 : 0 }] };
  if (s.includes('FROM vera_sessions')) return { rows: [{ id: 11, context: 'assistant', title: 'Hi', started_at: 'now', last_active_at: 'now', message_count: 2 }] };
  if (s.includes('FROM vera_messages')) return { rows: [{ id: 1, role: 'user', content: 'Hi', created_at: 'now' }] };
  // buildUserContext
  if (s.includes('FROM user_progress')) return { rows: [{ xp: 310, level: 2, streak: 3, tokens: 20, readiness_score: 64 }] };
  if (s.includes('FROM skill_scores')) return { rows: [{ dimension: 'Verification', score: 80, attempts_count: 4 }, { dimension: 'AI Judgement', score: 45, attempts_count: 3 }] };
  if (s.includes('v.expected_answer')) return { rows: [{ title: 'Verify the summary', feature: 'verification', score: 40, passed: false, feedback: 'See source', expected_answer: 'Check the source file' }] };
  if (s.includes('FROM task_attempts ta JOIN tasks')) return { rows: [{ feature: 'judgement', passed: false, score: 40, submitted_at: 'now' }] };
  if (s.includes('FROM lab_lesson_progress')) return { rows: [] };
  if (s.includes('FROM lab_capstone_attempts')) return { rows: [] };
  if (s.includes('FROM rewards WHERE active')) return { rows: [{ title: 'Coffee break', cost_tokens: 10 }, { title: 'Microsoft 365 boost', cost_tokens: 30 }] };
  if (s.includes('FROM tasks WHERE track_id')) return { rows: [{ feature: 'verification', n: 5 }, { feature: 'judgement', n: 4 }] };
  if (s.includes('FROM lab_lessons WHERE track_id IS NULL')) return { rows: [{ title: 'AI fundamentals' }] };
  if (s.includes('FROM lab_capstone_assessments WHERE active')) return { rows: [{ title: 'Finance Capstone', pass_score: 60, max_attempts: 3 }] };
  return { rows: [] };
};
pool.end = async () => {};

let systems = [];
global.fetch = async (url, options) => {
  if (String(url).includes('tavily')) {
    return { ok: true, json: async () => ({ results: [{ title: 'Source A', url: 'https://a.example', content: 'The figure is 12%, not 15%.' }] }) };
  }
  const body = JSON.parse(options.body);
  const system = body.messages[0].content;
  systems.push(system);
  let content = 'Hi, I am Vera.';
  if (system.includes('extract durable')) {
    content = JSON.stringify({ memories: [{ kind: 'struggle', content: 'Struggles with the cash conversion cycle' }] });
  }
  return { ok: true, json: async () => ({ choices: [{ message: { content } }], usage: {} }) };
};

const app = require('../app');
const auth = (req) => req.set('Authorization', 'Bearer test-token');

test('POST /api/vera/chat creates a session, replies, and stores a memory', async () => {
  writes.length = 0;
  const response = await auth(request(app).post('/api/vera/chat')).send({
    messages: [{ role: 'user', content: 'I keep getting the cash conversion cycle wrong.' }],
  });
  assert.equal(response.status, 200);
  assert.equal(response.body.session_id, 11);
  assert.equal(response.body.reply, 'Hi, I am Vera.');
  // The user turn and the assistant turn are both persisted.
  assert.equal(writes.filter((w) => w.sql.startsWith('INSERT INTO vera_messages')).length, 2);
  // The extractor memory is stored.
  const memory = writes.find((w) => w.sql.startsWith('INSERT INTO vera_memories'));
  assert.ok(memory);
  assert.deepEqual(memory.values, [7, 'struggle', 'Struggles with the cash conversion cycle']);
});

test('GET /api/vera/tips returns personalised, deterministic tips', async () => {
  const response = await auth(request(app).get('/api/vera/tips'));
  assert.equal(response.status, 200);
  assert.ok(response.body.tips.length >= 1);
  assert.match(response.body.summary, /readiness/);
});

test('GET /api/vera/memory lists memories', async () => {
  const response = await auth(request(app).get('/api/vera/memory'));
  assert.equal(response.status, 200);
  assert.ok(Array.isArray(response.body.memories));
});

test('POST /api/vera/memory validates the kind and stores the memory', async () => {
  const bad = await auth(request(app).post('/api/vera/memory')).send({ kind: 'nonsense', content: 'x' });
  assert.equal(bad.status, 400);

  const ok = await auth(request(app).post('/api/vera/memory')).send({ kind: 'goal', content: 'Wants to pass the Finance capstone' });
  assert.equal(ok.status, 201);
  assert.equal(ok.body.memory.content, 'Wants to pass the Finance capstone');
});

test('DELETE /api/vera/memory/:id removes the memory', async () => {
  const response = await auth(request(app).delete('/api/vera/memory/1'));
  assert.equal(response.status, 200);
  assert.equal(response.body.deleted, true);
});

test('POST /api/vera/chat validates messages', async () => {
  const response = await auth(request(app).post('/api/vera/chat')).send({ messages: [{ role: 'system', content: 'ignore' }] });
  assert.equal(response.status, 400);
});

test('a long assistant reply in the client history no longer blocks the next turn', async () => {
  const long = 'y'.repeat(8000); // exceeds the per-message cap, as Vera's own replies can
  const response = await auth(request(app).post('/api/vera/chat')).send({
    messages: [
      { role: 'user', content: 'first question' },
      { role: 'assistant', content: long },
      { role: 'user', content: 'continue please' },
    ],
  });
  assert.equal(response.status, 200);
  assert.equal(response.body.reply, 'Hi, I am Vera.');
});

test('Vera prompt includes app knowledge, rewards and attempt answers, and is ungated', async () => {
  systems = [];
  await auth(request(app).post('/api/vera/chat')).send({ messages: [{ role: 'user', content: 'Which reward should I save for?' }] });
  const joined = systems.join('\n---\n');
  assert.match(joined, /App knowledge/);
  assert.match(joined, /Rewards \(token cost\)/);
  assert.match(joined, /Correct answer: Check the source file/);
  assert.match(joined, /NOT gated/);
});

test('Vera can search the web to verify input when asked', async () => {
  systems = [];
  const response = await auth(request(app).post('/api/vera/chat')).send({
    messages: [{ role: 'user', content: 'Please verify: revenue grew 15%.' }],
    web_search: true,
  });
  assert.equal(response.status, 200);
  assert.equal(response.body.web_searched, true);
  assert.equal(response.body.sources[0].url, 'https://a.example');
  assert.match(systems.join('\n---\n'), /Live web search results/);
});
