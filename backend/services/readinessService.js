// Readiness is the weighted mean of a learner's skill scores, interview
// coverage and lab capstone results, on a 0-100 scale.
//
// BF-6: readiness is per industry track. The weighted inputs are the *track's*
// skill scores and offerings, and the result is written to
// user_track_progress.readiness_score (with readiness_best as the high-water
// mark the roadmap needs). user_progress keeps the global XP/level/streak/
// tokens and its readiness/tier columns are updated only as a mirror of the
// active track, for older code paths.
//
// The denominator is the sum of the weights of every component the learner's
// track actually offers, not the components they happen to have data for.
// Dividing by "what exists today" meant finishing one module scored
// 100/Advanced, and it made readiness *fall* the moment a second module was
// started. With a fixed denominator per track, coverage genuinely counts and
// the score can only move up as evidence arrives.
const { tierForScore } = require('./tiers');
const { contentCache } = require('../utils/ttlCache');

const READINESS_WEIGHTS = {
  Verification: 0.3,
  'AI Judgement': 0.3,
  'Risk & Governance': 0.2,
  'Prompt Design': 0.1,
  Interview: 0.1,
  Learning: 0.2,
};

async function refreshReadiness(client, userId, trackId) {
  // One statement for every non-static input.
  const inputs = await client.query(
    `/* readiness_inputs */
     SELECT
       COALESCE((SELECT json_agg(json_build_object('dimension', dimension, 'score', score))
                   FROM skill_scores
                  WHERE user_id = $1 AND track_id = $2), '[]'::json) AS scores,
       COALESCE((SELECT json_agg(json_build_object('feature', feature))
                   FROM (SELECT feature FROM tasks
                          WHERE track_id = $2 AND published
                          GROUP BY feature) f), '[]'::json) AS available,
       (SELECT COUNT(*)::int FROM lab_capstone_assessments
         WHERE track_id = $2 AND active) AS capstone_offered,
       COALESCE((SELECT AVG(best)::int FROM (
          SELECT assessment_id, MAX(score) AS best
          FROM lab_capstone_attempts
          WHERE user_id = $1 AND passed = TRUE
          GROUP BY assessment_id
        ) t), 0) AS capstone_average,
       (SELECT COUNT(*)::int
          FROM interview_practice ip
          JOIN interview_questions q ON q.id = ip.question_id
         WHERE ip.user_id = $1 AND q.track_id = $2) AS interview_practised,
       (SELECT COUNT(DISTINCT ta.task_id)::int
          FROM task_attempts ta
          JOIN tasks t ON t.id = ta.task_id
         WHERE ta.user_id = $1 AND ta.passed = TRUE AND ta.practice = FALSE
           AND t.track_id = $2) AS tasks_completed,
       (SELECT readiness_score FROM user_track_progress
         WHERE user_id = $1 AND track_id = $2) AS current_readiness,
       (SELECT readiness_best FROM user_track_progress
         WHERE user_id = $1 AND track_id = $2) AS current_best,
       (SELECT last_activity_date FROM user_progress WHERE user_id = $1) AS last_activity_date,
       (SELECT industry_track_id FROM users WHERE id = $1) AS active_track_id`,
    [userId, trackId],
  );
  const row = inputs.rows[0] || {};
  const scores = { rows: row.scores || [] };
  const available = { rows: row.available || [] };

  // Track question counts are static content, so they are cached rather than
  // recounted on every graded attempt.
  const interviewTotal = await contentCache.wrap(`interview-total:${trackId}`, async () => {
    const result = await client.query(
      `SELECT COUNT(*)::int AS total FROM interview_questions WHERE track_id = $1`,
      [trackId],
    );
    return Number(result.rows[0] && result.rows[0].total) || 0;
  });
  const interview = { rows: [{ total: interviewTotal, practised: Number(row.interview_practised) || 0 }] };
  const learning = { rows: [{ offered: Number(row.capstone_offered) || 0, average: Number(row.capstone_average) || 0 }] };

  const parts = [];
  const scoredDimensions = new Set();
  for (const scoreRow of scores.rows) {
    const weight = READINESS_WEIGHTS[scoreRow.dimension];
    if (!weight) continue;
    parts.push({ weight, score: Number(scoreRow.score) });
    scoredDimensions.add(scoreRow.dimension);
  }
  // A module the track offers but the learner has not touched counts as zero
  // coverage. Only offerings are scored - otherwise an empty module would
  // silently cap a learner below 100 for content nobody can attempt.
  const OFFERED = {
    verification: 'Verification',
    judgement: 'AI Judgement',
    risk_governance: 'Risk & Governance',
    prompt_design: 'Prompt Design',
  };
  for (const offered of available.rows) {
    const dimension = OFFERED[offered.feature];
    const weight = READINESS_WEIGHTS[dimension];
    if (!weight || scoredDimensions.has(dimension)) continue;
    parts.push({ weight, score: 0 });
  }

  const interviewTotals = interview.rows[0] || { total: 0, practised: 0 };
  if (interviewTotals.total > 0) {
    const score = Math.round((100 * interviewTotals.practised) / interviewTotals.total);
    parts.push({ weight: READINESS_WEIGHTS.Interview, score });
  }

  const learningRow = learning.rows[0] || {};
  if (Number(learningRow.offered) > 0) {
    parts.push({ weight: READINESS_WEIGHTS.Learning, score: Number(learningRow.average) });
  }

  let readiness = 0;
  if (parts.length) {
    const totalWeight = parts.reduce((sum, part) => sum + part.weight, 0);
    const value = Math.round(parts.reduce((sum, part) => sum + part.weight * part.score, 0) / totalWeight);
    readiness = Math.max(0, Math.min(100, value));
  }

  const best = Math.max(readiness, Number(row.current_best) || 0);
  const tier = tierForScore(readiness);
  const tasksCompleted = Number(row.tasks_completed) || 0;

  // One upsert writes the track row and keeps the high-water mark. A failed
  // retake can lower the live score but never readiness_best.
  await client.query(
    `INSERT INTO user_track_progress
       (user_id, track_id, readiness_score, readiness_best, tier, tasks_completed, last_activity_date)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     ON CONFLICT (user_id, track_id) DO UPDATE SET
       readiness_score = EXCLUDED.readiness_score,
       readiness_best = GREATEST(user_track_progress.readiness_best, EXCLUDED.readiness_best),
       tier = EXCLUDED.tier,
       tasks_completed = EXCLUDED.tasks_completed,
       last_activity_date = COALESCE(EXCLUDED.last_activity_date, user_track_progress.last_activity_date),
       updated_at = CURRENT_TIMESTAMP`,
    [userId, trackId, readiness, best, tier, tasksCompleted, row.last_activity_date || null],
  );

  // Deprecated mirror for older code paths. Only the active track may set it.
  if (Number(row.active_track_id) === Number(trackId)) {
    await client.query(
      `UPDATE user_progress
          SET readiness_score = $2, tier = $3, updated_at = CURRENT_TIMESTAMP
        WHERE user_id = $1
          AND (readiness_score <> $2 OR tier <> $3)`,
      [userId, readiness, tier],
    );
  }

  return readiness;
}

module.exports = { READINESS_WEIGHTS, refreshReadiness };
