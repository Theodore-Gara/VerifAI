// Readiness is the weighted mean of a learner's skill scores, interview
// coverage and lab capstone results. Weights are renormalised over whichever
// components currently have data, so a learner is never penalised for a
// component they have not reached yet. Stored monotonically via GREATEST.
const READINESS_WEIGHTS = {
  Verification: 0.3,
  'AI Judgement': 0.3,
  'Risk & Governance': 0.2,
  'Prompt Design': 0.1,
  Interview: 0.1,
  Learning: 0.1,
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

  await client.query(
    `UPDATE user_progress
     SET readiness_score = GREATEST(readiness_score, $1)
     WHERE user_id = $2`,
    [Math.max(0, Math.min(100, value)), userId],
  );
}

module.exports = { READINESS_WEIGHTS, refreshReadiness };
