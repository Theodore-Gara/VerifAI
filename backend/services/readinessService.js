// Readiness is the weighted mean of a learner's skill scores, interview
// coverage and lab capstone results, on a 0-100 scale.
//
// The denominator is the sum of the weights of every component the learner's
// *track* actually offers, not the components they happen to have data for.
// Dividing by "what exists today" meant finishing one module scored
// 100/Advanced, and it made readiness *fall* the moment a second module was
// started. With a fixed denominator per track, coverage genuinely counts and
// the score can only move up as evidence arrives.
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
  // The five lookups are independent, so they run together rather than as a
  // serial chain (node-postgres queues them on the one connection).
  const [scores, available, interview, learning] = await Promise.all([
    client.query(`SELECT dimension, score FROM skill_scores WHERE user_id = $1`, [userId]),
    client.query(
      `SELECT feature, COUNT(*)::int AS n
       FROM tasks
       WHERE track_id = $1 AND published
       GROUP BY feature`,
      [trackId],
    ),
    client.query(
      `SELECT
         (SELECT COUNT(*)::int FROM interview_questions WHERE track_id = $2) AS total,
         (SELECT COUNT(*)::int
            FROM interview_practice ip
            JOIN interview_questions q ON q.id = ip.question_id
           WHERE ip.user_id = $1 AND q.track_id = $2) AS practised`,
      [userId, trackId],
    ),
    client.query(
      `SELECT
         (SELECT COUNT(*)::int FROM lab_capstone_assessments
           WHERE track_id = $2 AND active) AS offered,
         COALESCE((
           SELECT AVG(best) FROM (
             SELECT assessment_id, MAX(score) AS best
             FROM lab_capstone_attempts
             WHERE user_id = $1 AND passed = TRUE
             GROUP BY assessment_id
           ) t
         ), 0)::int AS average`,
      [userId, trackId],
    ),
  ]);

  const parts = [];
  const scoredDimensions = new Set();
  for (const row of scores.rows) {
    const weight = READINESS_WEIGHTS[row.dimension];
    if (!weight) continue;
    parts.push({ weight, score: Number(row.score) });
    scoredDimensions.add(row.dimension);
  }
  // A module the track offers but the learner has not touched counts as zero
  // coverage. Only offerings are scored — otherwise an empty module would
  // silently cap a learner below 100 for content nobody can attempt.
  const OFFERED = {
    verification: 'Verification',
    judgement: 'AI Judgement',
    risk_governance: 'Risk & Governance',
    prompt_design: 'Prompt Design',
  };
  for (const row of available.rows) {
    const dimension = OFFERED[row.feature];
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

  if (!parts.length) return;

  const totalWeight = parts.reduce((sum, part) => sum + part.weight, 0);
  const value = Math.round(parts.reduce((sum, part) => sum + part.weight * part.score, 0) / totalWeight);
  const readiness = Math.max(0, Math.min(100, value));

  // Upsert: a learner's first scored attempt has no user_progress row yet (sync
  // creates one, but rows can predate that), and a plain UPDATE silently threw
  // the readiness away, leaving every new account at 0 / Novice.
  await client.query(
    `INSERT INTO user_progress (user_id, readiness_score, tier)
     VALUES ($1, $2, $3)
     ON CONFLICT (user_id) DO UPDATE
     SET readiness_score = EXCLUDED.readiness_score, tier = EXCLUDED.tier`,
    [userId, readiness, tierForScore(readiness)],
  );
}

module.exports = { READINESS_WEIGHTS, refreshReadiness };
