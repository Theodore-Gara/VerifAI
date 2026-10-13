// Builds the learner profile Vera uses to personalise coaching: progress,
// skill scores (strengths and weak areas), recent task outcomes, lab progress,
// capstone results and stored memories. Read-only aggregation over existing
// tables; nothing is duplicated.

async function buildUserContext(executor, userId) {
  const progressResult = await executor.query(
    `SELECT COALESCE(xp, 0)::int AS xp, COALESCE(level, 1)::int AS level,
            COALESCE(streak, 0)::int AS streak, COALESCE(tokens, 0)::int AS tokens,
            COALESCE(readiness_score, 0)::int AS readiness_score
     FROM user_progress WHERE user_id = $1`,
    [userId],
  );
  const progress = progressResult.rows[0] || { xp: 0, level: 1, streak: 0, tokens: 0, readiness_score: 0 };

  const skillsResult = await executor.query(
    `SELECT dimension, score, attempts_count FROM skill_scores WHERE user_id = $1 ORDER BY score ASC`,
    [userId],
  );
  const skills = skillsResult.rows;
  const weak = skills.filter((s) => Number(s.score) < 60).slice(0, 3);
  const strengths = [...skills].sort((a, b) => Number(b.score) - Number(a.score)).filter((s) => Number(s.score) >= 70).slice(0, 3);

  const recentResult = await executor.query(
    `SELECT t.feature, ta.passed, ta.score, ta.submitted_at
     FROM task_attempts ta JOIN tasks t ON t.id = ta.task_id
     WHERE ta.user_id = $1 AND ta.practice = FALSE
     ORDER BY ta.submitted_at DESC, ta.id DESC LIMIT 8`,
    [userId],
  );
  const recent = recentResult.rows;
  const failuresByFeature = {};
  for (const row of recent) {
    if (!row.passed) failuresByFeature[row.feature] = (failuresByFeature[row.feature] || 0) + 1;
  }

  const lessonsResult = await executor.query(
    `SELECT l.title, p.status, p.assessment_best_score
     FROM lab_lesson_progress p JOIN lab_lessons l ON l.id = p.lesson_id
     WHERE p.user_id = $1 ORDER BY p.updated_at DESC LIMIT 8`,
    [userId],
  );
  const lessons = lessonsResult.rows;

  const capstoneResult = await executor.query(
    `SELECT c.title, a.score, a.passed, a.status
     FROM lab_capstone_attempts a JOIN lab_capstone_assessments c ON c.id = a.assessment_id
     WHERE a.user_id = $1 AND a.submitted_at IS NOT NULL
     ORDER BY a.submitted_at DESC LIMIT 5`,
    [userId],
  );
  const capstones = capstoneResult.rows;

  return { progress, skills, weak, strengths, recent, failuresByFeature, lessons, capstones };
}

// Compact text injected into Vera's system prompt.
function describeContext(ctx) {
  const lines = [];
  const p = ctx.progress;
  lines.push(`Level ${p.level}, ${p.xp} XP, ${p.streak}-day streak, ${p.tokens} reward tokens, readiness ${p.readiness_score}%.`);
  if (ctx.skills.length) lines.push(`Skill scores: ${ctx.skills.map((s) => `${s.dimension} ${s.score}`).join(', ')}.`);
  if (ctx.weak.length) lines.push(`Weak areas (below 60): ${ctx.weak.map((s) => s.dimension).join(', ')}.`);
  if (ctx.strengths.length) lines.push(`Strengths (70+): ${ctx.strengths.map((s) => s.dimension).join(', ')}.`);
  if (ctx.recent.length) {
    const passed = ctx.recent.filter((r) => r.passed).length;
    lines.push(`Recent tasks: ${passed} of the last ${ctx.recent.length} passed.`);
  }
  const failed = Object.entries(ctx.failuresByFeature);
  if (failed.length) lines.push(`Recent failures by skill: ${failed.map(([f, n]) => `${f} (${n})`).join(', ')}.`);
  if (ctx.lessons.length) lines.push(`Lab lessons: ${ctx.lessons.map((l) => `${l.title} [${l.status}]`).join('; ')}.`);
  if (ctx.capstones.length) lines.push(`Capstones: ${ctx.capstones.map((c) => `${c.title} ${c.score ?? '-'} (${c.status})`).join('; ')}.`);
  return lines.join('\n');
}

// Deterministic, cost-free tips derived from the profile (Vera expands on these
// in chat).
function buildTips(ctx) {
  const tips = [];
  if (ctx.weak.length) {
    tips.push({
      title: 'Focus your practice',
      body: `Your ${ctx.weak[0].dimension} score is under 60. Work through another ${ctx.weak[0].dimension} task and read the feedback closely to lift it.`,
    });
  }
  const failedFeature = Object.entries(ctx.failuresByFeature).sort((a, b) => b[1] - a[1])[0];
  if (failedFeature) {
    tips.push({
      title: 'Learn from recent misses',
      body: `You have missed a few ${failedFeature[0]} tasks lately. Ask Vera to walk through one of the scenarios step by step.`,
    });
  }
  if (ctx.strengths.length) {
    tips.push({
      title: 'Build on a strength',
      body: `${ctx.strengths[0].dimension} is one of your strongest skills. Try a harder band to keep growing.`,
    });
  }
  const inProgress = ctx.lessons.find((l) => l.status !== 'completed');
  if (inProgress) {
    tips.push({ title: 'Finish what you started', body: `Pick up "${inProgress.title}" and complete its activities and assessment.` });
  }
  const capstonePending = ctx.capstones.find((c) => c.status === 'pending_marking');
  if (capstonePending) {
    tips.push({ title: 'Awaiting marking', body: `Your "${capstonePending.title}" capstone is with the marker. Review the model answer in the meantime.` });
  }
  if (!tips.length) {
    tips.push({ title: 'Get started', body: 'Complete a task or open a lesson so Vera can tailor advice to you.' });
  }
  return tips.slice(0, 4);
}

module.exports = { buildUserContext, describeContext, buildTips };
