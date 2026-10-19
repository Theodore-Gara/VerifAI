// Builds the learner profile Vera uses to personalise coaching: progress,
// skill scores (strengths and weak areas), recent task outcomes, lab progress,
// capstone results and stored memories. Read-only aggregation over existing
// tables; nothing is duplicated.

const { nextTier } = require('./tiers');

async function buildUserContext(executor, userId) {
  const progressResult = await executor.query(
    `SELECT COALESCE(xp, 0)::int AS xp, COALESCE(level, 1)::int AS level,
            COALESCE(streak, 0)::int AS streak, COALESCE(tokens, 0)::int AS tokens,
            COALESCE(readiness_score, 0)::int AS readiness_score,
            COALESCE(tier, 'Novice') AS tier
     FROM user_progress WHERE user_id = $1`,
    [userId],
  );
  const progress = progressResult.rows[0] || { xp: 0, level: 1, streak: 0, tokens: 0, readiness_score: 0, tier: 'Novice' };

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

// Leaderboard context: user's global and track rank, plus nearby peers.
async function buildLeaderboardContext(executor, userId, industryTrackId) {
  const meResult = await executor.query(
    `SELECT COALESCE(xp, 0)::int AS xp, COALESCE(readiness_score, 0)::int AS readiness_score
     FROM user_progress WHERE user_id = $1`,
    [userId],
  );
  const me = meResult.rows[0] || { xp: 0, readiness_score: 0 };

  const globalRankResult = await executor.query(
    `SELECT (COUNT(*)::int + 1) AS global_rank
     FROM users u
     LEFT JOIN user_progress p ON p.user_id = u.id
     WHERE (COALESCE(p.xp, 0), COALESCE(p.readiness_score, 0), u.id) > ($1, $2, $3)`,
    [me.xp, me.readiness_score, userId],
  );

  let trackRank = null;
  let trackTotal = null;
  if (industryTrackId) {
    const trackResult = await executor.query(
      `SELECT (COUNT(*)::int + 1) AS track_rank
       FROM users u
       LEFT JOIN user_progress p ON p.user_id = u.id
       WHERE u.industry_track_id = $1
         AND (COALESCE(p.xp, 0), COALESCE(p.readiness_score, 0), u.id) > ($2, $3, $4)`,
      [industryTrackId, me.xp, me.readiness_score, userId],
    );
    trackRank = trackResult.rows[0]?.track_rank;

    const trackTotalResult = await executor.query(
      `SELECT COUNT(*)::int AS track_total
       FROM users WHERE industry_track_id = $1`,
      [industryTrackId],
    );
    trackTotal = trackTotalResult.rows[0]?.track_total || 0;
  }

  let peers = [];
  if (industryTrackId) {
    const peersResult = await executor.query(
      `SELECT u.display_name, COALESCE(p.xp, 0) AS xp,
              COALESCE(p.readiness_score, 0) AS readiness_score,
              COALESCE(p.tier, 'Novice') AS tier,
              ROW_NUMBER() OVER (ORDER BY COALESCE(p.xp, 0) DESC, COALESCE(p.readiness_score, 0) DESC, u.id ASC) AS rank
       FROM users u
       LEFT JOIN user_progress p ON p.user_id = u.id
       WHERE u.industry_track_id = $1
       ORDER BY rank ASC
       LIMIT 20`,
      [industryTrackId],
    );
    peers = peersResult.rows;
  }

  return { globalRank: globalRankResult.rows[0]?.global_rank, trackRank, trackTotal, peers };
}

// Token context: current balance and recent earning/spending history.
async function buildTokenContext(executor, userId) {
  const progressResult = await executor.query(
    `SELECT COALESCE(tokens, 0)::int AS tokens FROM user_progress WHERE user_id = $1`,
    [userId],
  );
  const tokens = progressResult.rows[0]?.tokens ?? 0;

  const eventsResult = await executor.query(
    `SELECT delta, reason, ref, created_at
     FROM reward_token_events
     WHERE user_id = $1
     ORDER BY created_at DESC, id DESC
     LIMIT 10`,
    [userId],
  );
  const events = eventsResult.rows;

  return { tokens, events };
}

// Wellness context: recent mood check-ins, this week's self-care activity
// counts and how many journal entries exist. Journal content is deliberately
// never loaded — it stays private to the learner.
async function buildWellnessContext(executor, userId) {
  const moodResult = await executor.query(
    `SELECT check_in_date::text AS date, mood, (check_in_date = CURRENT_DATE) AS today
     FROM wellness_mood_checkins
     WHERE user_id = $1
     ORDER BY check_in_date DESC
     LIMIT 7`,
    [userId],
  );

  const activityResult = await executor.query(
    `SELECT activity, COUNT(*)::int AS count
     FROM wellness_activities
     WHERE user_id = $1 AND completed_at >= now() - interval '7 days'
     GROUP BY activity`,
    [userId],
  );

  const journalResult = await executor.query(
    `SELECT COUNT(*)::int AS count
     FROM wellness_journal_entries
     WHERE user_id = $1 AND entry_date >= CURRENT_DATE - 6`,
    [userId],
  );

  return {
    moods: moodResult.rows,
    activities: activityResult.rows,
    journalEntriesThisWeek: journalResult.rows[0]?.count ?? 0,
  };
}

// Compact text injected into Vera's system prompt.
function describeContext(ctx) {
  const lines = [];
  const p = ctx.progress;
  const tier = p.tier || 'Novice';
  lines.push(`Tier ${tier} at ${p.readiness_score}% readiness, Level ${p.level}, ${p.xp} XP, ${p.streak}-day streak, ${p.tokens} reward tokens.`);
  const next = nextTier(tier);
  if (next) lines.push(`Next tier: ${next.name} at ${next.min}% readiness.`);
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

// App-wide knowledge: what tasks, lessons, capstones and rewards exist, so Vera
// can answer "which reward should I go for?" and point the learner at content.
async function buildAppKnowledge(executor, userId, trackId) {
  const rewards = await executor.query(
    `SELECT title, cost_tokens FROM rewards WHERE active = TRUE ORDER BY sort_order`,
  );
  const features = await executor.query(
    `SELECT feature, COUNT(*)::int AS n FROM tasks WHERE track_id = $1 GROUP BY feature ORDER BY feature`,
    [trackId],
  );
  const lessons = await executor.query(
    `SELECT title FROM lab_lessons WHERE track_id IS NULL OR track_id = $1 ORDER BY sort_order`,
    [trackId],
  );
  const capstones = await executor.query(
    `SELECT title, pass_score, max_attempts FROM lab_capstone_assessments
     WHERE active = TRUE AND (track_id IS NULL OR track_id = $1) ORDER BY sort_order`,
    [trackId],
  );
  const tokensResult = await executor.query(
    `SELECT COALESCE(tokens, 0)::int AS tokens FROM user_progress WHERE user_id = $1`,
    [userId],
  );
  const tokens = tokensResult.rows[0]?.tokens ?? 0;

  const lines = [];
  if (rewards.rows.length) {
    lines.push(`Rewards (token cost): ${rewards.rows.map((r) => `${r.title} ${r.cost_tokens}`).join(', ')}. Learner has ${tokens} tokens.`);
  }
  if (features.rows.length) {
    lines.push(`Task types in this module: ${features.rows.map((f) => `${f.feature} (${f.n})`).join(', ')}.`);
  }
  if (lessons.rows.length) lines.push(`Lessons: ${lessons.rows.map((l) => l.title).join('; ')}.`);
  if (capstones.rows.length) {
    lines.push(`Capstones: ${capstones.rows.map((c) => `${c.title} (pass ${c.pass_score}, ${c.max_attempts} attempts)`).join('; ')}.`);
  }
  return lines.join('\n');
}

// The learner's own attempts, WITH the correct answers, so the general
// assistant can tell them the answer if they ask. The task-scoped tutor and
// coach stay gated; this is only for Vera.
async function buildAttemptAnswers(executor, userId) {
  const result = await executor.query(
    `SELECT ta.task_title AS title, t.feature, ta.score, ta.passed, ta.feedback, v.expected_answer,
            (SELECT string_agg(o.label, ' | ') FROM task_options o
              WHERE o.task_id = t.id AND o.kind = 'decision'
                AND o.score = (SELECT MAX(o2.score) FROM task_options o2 WHERE o2.task_id = t.id AND o2.kind = 'decision')) AS best_decision,
            (SELECT string_agg(o.label, ' | ') FROM task_options o
              WHERE o.task_id = t.id AND o.kind = 'reason'
                AND o.score = (SELECT MAX(o2.score) FROM task_options o2 WHERE o2.task_id = t.id AND o2.kind = 'reason')) AS best_reason
     FROM task_attempts ta
     JOIN tasks t ON t.id = ta.task_id
     LEFT JOIN verification_tasks v ON v.task_id = t.id
     WHERE ta.user_id = $1 AND ta.practice = FALSE
     ORDER BY ta.submitted_at DESC, ta.id DESC
     LIMIT 5`,
    [userId],
  );
  return result.rows.map((row) => {
    const answer = row.expected_answer
      || [row.best_decision, row.best_reason].filter(Boolean).join(' / ')
      || '(see feedback)';
    return `- [${row.feature}] "${row.title}" scored ${row.score} (${row.passed ? 'passed' : 'failed'}). Correct answer: ${answer}`;
  });
}

module.exports = { buildUserContext, describeContext, buildTips, buildAppKnowledge, buildAttemptAnswers, buildLeaderboardContext, buildTokenContext, buildWellnessContext };

