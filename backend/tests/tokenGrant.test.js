const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');

const firebase = require('../db/firebase');
firebase.getFirebaseAuth = () => ({ verifyIdToken: async () => ({ uid: 'test-uid' }) });

const pool = require('../db/pool');

const DECISIONS = [
  { id: 11, kind: 'decision', label: 'Use AI', score: 50 },
  { id: 12, kind: 'decision', label: 'Use AI with human review', score: 25 },
];
const REASONS = [{ id: 14, kind: 'reason', label: 'A. Routine, low-risk.', score: 50 }];

const ledger = [];

const fakeClient = {
  async query(sql, values = []) {
    const s = sql.replace(/\s+/g, ' ').trim();
    if (['BEGIN', 'COMMIT', 'ROLLBACK'].includes(s)) return { rows: [] };
    if (s.includes('FROM users WHERE firebase_uid')) return { rows: [{ id: 7, industry_track_id: 1 }] };
    if (s.includes('FROM tasks WHERE id') && s.includes('FOR SHARE')) return { rows: [{ id: 5, feature: 'judgement', track_id: 1 }] };
    if (s.includes('FROM task_options')) return { rows: [...DECISIONS, ...REASONS] };
    if (s.includes('FROM judgement_tasks')) return { rows: [{ title: 'Month-End Agenda', feedback: 'Good call.' }] };
    if (s.includes('INSERT INTO task_attempts')) return { rows: [{ id: 1, task_id: 5, score: 100, passed: true, practice: false, xp_earned: 70, submitted_at: 'now' }] };
    if (s.includes('AS passed') && s.includes('AS total')) return { rows: [{ passed: 1, total: 4 }] };
    if (s.includes('INSERT INTO skill_scores')) return { rows: [{ dimension: 'AI Judgement', score: 100, attempts_count: 1 }] };
    // The user is 10 XP short of level 2 before this attempt.
    if (s.includes('INSERT INTO user_progress')) return { rows: [{ id: 1, xp: 240, level: 1, streak: 0, last_activity_date: null, tier: 'Novice', tier_tasks_completed: 0 }] };
    if (s.includes('INSERT INTO reward_token_events')) {
      ledger.push(values);
      return { rowCount: 1, rows: [] };
    }
    if (s.includes('UPDATE user_progress SET tokens')) return { rowCount: 1, rows: [] };
    if (s.includes('UPDATE user_progress') && s.includes('SET xp')) {
      return { rows: [{ xp: 310, level: 2, streak: 1, last_activity_date: '2026-10-12', tier: 'Novice', tier_tasks_completed: 1, readiness_score: 100, tokens: 10 }] };
    }
    if (s.includes('readiness_score')) return { rows: [] };
    if (s.includes('SUM(xp_earned)')) return { rows: [{ attempts: 1, xp: 310 }] };
    if (s.includes('MAX(score)')) return { rows: [{ best_dimension: 100 }] };
    if (s.includes('FROM skill_scores')) return { rows: [{ dimension: 'AI Judgement', score: 100 }] };
    if (s.includes('COUNT(*)::int AS total FROM interview_questions')) return { rows: [{ total: 0 }] };
    if (s.includes('FROM achievements')) return { rows: [] };
    return { rows: [] };
  },
  release() {},
};
pool.query = fakeClient.query.bind(fakeClient);
pool.connect = async () => fakeClient;
pool.end = async () => {};

const app = require('../app');

test('a level-up submission credits reward tokens once and reports the new balance', async () => {
  ledger.length = 0;
  const response = await request(app)
    .post('/api/tasks/5/attempt')
    .set('Authorization', 'Bearer test-token')
    .send({ decision_option_id: 11, reason_option_id: 14 });

  assert.equal(response.status, 201);
  assert.equal(response.body.progress.level, 2);
  assert.equal(response.body.progress.tokens, 10);
  assert.deepEqual(ledger, [[7, 10, 'level_up', 'level-2']]);
});
