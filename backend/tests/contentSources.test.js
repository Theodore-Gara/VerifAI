const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({ verifyIdToken: async () => ({ uid: 'test-uid' }) });

const pool = require('../db/pool');

const USER = { id: 7, industry_track_id: 1 };
const LESSON = { id: 1, code: 'finance-read-the-numbers', title: 'Reading AI-written financial summaries critically', summary: 'Sum', estimated_minutes: 8, level: 1, competency: 'Verification', is_original: false };
const SOURCE = {
  id: '11111111-1111-1111-1111-111111111111',
  title: 'Financial Management for Small Businesses',
  author: 'Lindon J. Robison', publisher: 'Michigan State University Libraries',
  edition: '2nd OER Edition', source_url: 'https://openbooks.lib.msu.edu/financialmanagement/',
  license: 'CC_BY_4', license_url: 'https://creativecommons.org/licenses/by/4.0/',
  industry: 'FINANCE', checked_on: '2026-10-12', notes: null,
};
const OWASP = {
  id: '22222222-2222-2222-2222-222222222222',
  title: 'OWASP Cheat Sheet Series', author: 'OWASP Foundation', publisher: 'OWASP',
  edition: null, source_url: 'https://cheatsheetseries.owasp.org',
  license: 'CC_BY_SA_4', license_url: 'https://creativecommons.org/licenses/by-sa/4.0/',
  industry: 'IT_SOFTWARE', checked_on: '2026-10-12', notes: null,
};

let nextLessonRow = { id: 1, code: 'finance-read-the-numbers', title: 'Reading...', summary: 'Sum', estimated_minutes: 8, level: 1, competency: 'Verification', seen: false, last_viewed_at: null };
let progressRow = { sections_completed: 1, activities_completed: 0, assessment_best_score: 0, status: 'in_progress', last_viewed_at: '2026-10-12T00:00:00.000Z' };
let shareAlike = false;

pool.query = async (sql, values = []) => {
  const s = sql.replace(/\s+/g, ' ').trim();
  if (s.includes('FROM users WHERE firebase_uid')) return { rows: [USER] };
  if (s.startsWith('INSERT INTO lab_lesson_progress')) return { rows: [] };
  if (s.includes('FROM content_sources WHERE id')) return { rows: values[0] === SOURCE.id ? [SOURCE] : [] };
  if (s.includes('FROM content_sources')) return { rows: [SOURCE, OWASP] };
  if (s.includes('FROM lesson_attributions')) {
    return { rows: [{ credit_line: '"Financial Management for Small Businesses" (2nd OER Edition) by Lindon J. Robison, licensed under CC BY 4.0. Changes: Condensed to a short workplace lesson and added a South African rand example.', source_url: SOURCE.source_url, license_url: SOURCE.license_url, title: SOURCE.title, license: 'CC_BY_4', use_type: 'adapted' }] };
  }
  if (s.includes('FROM lessons_needing_share_alike')) return { rows: [{ share_alike: shareAlike }] };
  if (s.includes('FROM lesson_sources ls') && s.includes('JOIN content_sources')) {
    return { rows: [{ ...SOURCE, use_type: 'adapted', changes_made: 'Condensed.' }] };
  }
  if (s.includes('FROM lesson_sources ls') && s.includes('JOIN lab_lessons')) {
    return { rows: [{ id: 1, code: 'finance-read-the-numbers', title: LESSON.title, use_type: 'adapted', changes_made: 'Condensed.' }] };
  }
  if (s.includes('ORDER BY seen ASC')) {
    return { rows: nextLessonRow ? [nextLessonRow] : [] };
  }
  if (s.includes('FROM lab_lessons l')) return { rows: [{ ...LESSON, sort_order: 110, sections_count: 3, activities_count: 2, questions_count: 2, sections_completed: 1, activities_completed: 0, assessment_best_score: 0, status: 'in_progress', last_viewed_at: '2026-10-12T00:00:00.000Z', seen: true }] };
  if (s.includes('FROM lab_lessons WHERE code')) return { rows: [LESSON] };
  if (s.includes('FROM lab_lesson_sections')) return { rows: [{ id: 1, heading: 'h', body: 'b', sort_order: 1 }] };
  if (s.includes('FROM lab_activities')) return { rows: [{ id: 1, kind: 'reflection', title: 't', instructions: 'i', task_id: null, sort_order: 1 }] };
  if (s.includes('FROM lab_questions')) return { rows: [{ id: 1, prompt: 'p', options: ['a', 'b'], sort_order: 1 }] };
  if (s.includes('FROM lab_lesson_progress')) return { rows: [progressRow] };
  return { rows: [] };
};
pool.end = async () => {};

const app = require('../app');
const auth = (req) => req.set('Authorization', 'Bearer test-token');

test('GET /api/lab/sources lists the source catalogue with licence metadata', async () => {
  const response = await auth(request(app).get('/api/lab/sources'));
  assert.equal(response.status, 200);
  assert.equal(response.body.sources.length, 2);
  assert.equal(response.body.sources[0].license, 'CC_BY_4');
  assert.ok(response.body.sources[0].license_url);
  assert.ok(response.body.sources[0].checked_on);
});

test('GET /api/lab/library groups sources by industry', async () => {
  const response = await auth(request(app).get('/api/lab/library'));
  assert.equal(response.status, 200);
  assert.equal(response.body.groups.length, 2);
  assert.equal(response.body.groups[0].industry, 'FINANCE');
  assert.equal(response.body.groups[1].industry, 'IT_SOFTWARE');
});

test('GET /api/lab/sources/:id returns the source and the lessons using it', async () => {
  const response = await auth(request(app).get(`/api/lab/sources/${SOURCE.id}`));
  assert.equal(response.status, 200);
  assert.equal(response.body.source.title, 'Financial Management for Small Businesses');
  assert.equal(response.body.lessons[0].use_type, 'adapted');
});

test('GET /api/lab/sources/:id rejects a non-uuid id', async () => {
  const response = await auth(request(app).get('/api/lab/sources/not-a-uuid'));
  assert.equal(response.status, 400);
});

test('GET /api/lab/lessons/:code includes sources, attributions and a share-alike flag', async () => {
  shareAlike = true;
  const response = await auth(request(app).get('/api/lab/lessons/finance-read-the-numbers'));
  assert.equal(response.status, 200);
  assert.equal(response.body.lesson.sources.length, 1);
  assert.match(response.body.lesson.attributions[0].credit_line, /licensed under CC BY 4\.0/);
  assert.equal(response.body.lesson.share_alike, true);
  assert.equal('correct_index' in response.body.lesson.questions[0], false);
});

test('GET /api/lab/lessons/next prefers unseen content', async () => {
  nextLessonRow = { id: 2, code: 'finance-verify-a-forecast', title: 'Verifying an AI revenue forecast', summary: 'Sum', estimated_minutes: 7, level: 1, competency: 'AI Judgement', seen: false, last_viewed_at: null };
  const response = await auth(request(app).get('/api/lab/lessons/next'));
  assert.equal(response.status, 200);
  assert.equal(response.body.lesson.code, 'finance-verify-a-forecast');
  assert.equal(response.body.revisited, false);
});

test('GET /api/lab/lessons/next rotates a seen lesson back in for revisiting', async () => {
  nextLessonRow = { id: 1, code: 'finance-read-the-numbers', title: 'Reading...', summary: 'Sum', estimated_minutes: 8, level: 1, competency: 'Verification', seen: true, last_viewed_at: '2026-10-01T00:00:00.000Z' };
  const response = await auth(request(app).get('/api/lab/lessons/next?include_seen=true'));
  assert.equal(response.status, 200);
  assert.equal(response.body.lesson.code, 'finance-read-the-numbers');
  assert.equal(response.body.revisited, true);
});

test('GET /api/lab/lessons/next returns nothing when all content is seen and revisits are excluded', async () => {
  nextLessonRow = null;
  const response = await auth(request(app).get('/api/lab/lessons/next?include_seen=false'));
  assert.equal(response.status, 200);
  assert.equal(response.body.lesson, null);
});
