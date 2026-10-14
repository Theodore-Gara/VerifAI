// Readiness is the weighted mean of a learner's skill scores, interview
// coverage and lab capstone results, on a 0-100 scale. Weights are renormalised
// over whichever components currently have data, so a learner is never
// penalised for a component they have not reached yet.
//
// Readiness is the single source of truth for a learner's tier: it is written
// live on every scored attempt and the tier is derived from the current score
// (see services/tiers.js). Each skill score is coverage of that feature's tasks
// (passed tasks / tasks available), so readiness climbs as the learner covers
// more of each module rather than jumping high on a single good attempt.
const { tierForScore } = require('./tiers');

const READINESS_WEIGHTS = {
  Verification: 0.3,
  'AI Judgement': 0.3,
  'Risk & Governance': 0.2,
  'Prompt Design': 0.1,
  Interview: 0.1,
  Learning: 0.2,
};

async function refreshReadiness(client, userId, trackId) {
  const scores = await client.query(
    `SELECT dimension, score FROM skill_scores WHERE user_id = $1`,
    [userId],
  );
  const parts = [];
  for (const row of scores.rows) {
    const weight = READINESS_WEIGHTS[row.dimension];
    if (weight) parts.push({ weight, score: Number(row.score) });
  }

  const total = await client.query(
    `SELECT COUNT(*)::int AS total FROM interview_questions WHERE track_id = $1`,
    [trackId],
  );
  if (total.rows[0].total > 0) {
    const practised = await client.query(
      `SELECT COUNT(*)::int AS n
       FROM interview_practice ip
       JOIN interview_questions q ON q.id = ip.question_id
       WHERE ip.user_id = $1 AND q.track_id = $2`,
      [userId, trackId],
    );
    const interviewScore = Math.round((100 * practised.rows[0].n) / total.rows[0].total);
    parts.push({ weight: READINESS_WEIGHTS.Interview, score: interviewScore });
  }

  // Learning: the average of the learner's best passed capstone score.
  const learning = await client.query(
    `SELECT COUNT(*)::int AS graded, COALESCE(AVG(best), 0)::int AS average
     FROM (
       SELECT assessment_id, MAX(score) AS best
       FROM lab_capstone_attempts
       WHERE user_id = $1 AND passed = TRUE
       GROUP BY assessment_id
     ) t`,
    [userId],
  );
  if (learning.rows[0] && learning.rows[0].graded > 0) {
    parts.push({ weight: READINESS_WEIGHTS.Learning, score: Number(learning.rows[0].average) });
  }

  if (!parts.length) return;
  const sumWeight = parts.reduce((s, p) => s + p.weight, 0);
  const value = Math.round(parts.reduce((s, p) => s + p.weight * p.score, 0) / sumWeight);
  const readiness = Math.max(0, Math.min(100, value));

  await client.query(
    `UPDATE user_progress
     SET readiness_score = $1, tier = $2
     WHERE user_id = $3`,
    [readiness, tierForScore(readiness), userId],
  );
}

module.exports = { READINESS_WEIGHTS, refreshReadiness };
