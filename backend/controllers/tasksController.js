const pool = require('../db/pool');
const { positiveIntegerParam, requiredString } = require('../middleware/validate');
const {
  scoreAnswer,
  scoreOptions,
  calculateXp,
  calculateLevel,
} = require('../services/scoringService');

// feature key -> skill_scores.dimension (display name)
const FEATURE_DIMENSION = {
  verification: 'Verification',
  judgement: 'AI Judgement',
  risk_governance: 'Risk & Governance',
  prompt_design: 'Prompt Design',
};

const PASS_THRESHOLD = {
  verification: 60,
  judgement: 50,
  risk_governance: 50,
  prompt_design: 60,
};

// Readiness weights. Prompt Design joins when built; renormalised over whatever
// skills currently have data.
const READINESS_WEIGHTS = {
  Verification: 0.3,
  'AI Judgement': 0.3,
  'Risk & Governance': 0.2,
  'Prompt Design': 0.1,
  Interview: 0.1,
};

const TIERS = [
  { name: 'Novice', required: 5 },
  { name: 'Developing', required: 10 },
  { name: 'Proficient', required: 15 },
  { name: 'Advanced', required: 20 },
];

const FEATURES = new Set(Object.keys(FEATURE_DIMENSION));

async function getCurrentUser(client, firebaseUid) {
  const result = await client.query(
    `SELECT id, industry_track_id FROM users WHERE firebase_uid = $1`,
    [firebaseUid]
  );
  return result.rows[0] || null;
}

function preferredDifficulties(level) {
  if (level <= 1) return ['easy', 'medium'];
  if (level <= 3) return ['medium', 'easy', 'hard'];
  return ['hard', 'medium', 'easy'];
}

// ---------------------------------------------------------------------------
// GET /api/tasks/next?feature=verification
// ---------------------------------------------------------------------------
async function getNextTask(req, res, next) {
  try {
    const feature = String(req.query.feature || 'verification').toLowerCase();
    if (!FEATURES.has(feature)) {
      return res.status(400).json({ error: 'Unknown feature.', request_id: req.requestId });
    }

    const userResult = await pool.query(
      `SELECT u.id, u.industry_track_id, COALESCE(p.level, 1) AS level
       FROM users u
       LEFT JOIN user_progress p ON p.user_id = u.id
       WHERE u.firebase_uid = $1`,
      [req.firebaseUser.uid]
    );

    if (!userResult.rows.length) {
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }

    const user = userResult.rows[0];
    if (!user.industry_track_id) {
      return res.status(400).json({ error: 'Select an industry track before requesting a task.', request_id: req.requestId });
    }

    const seenFilter = `NOT EXISTS (
      SELECT 1 FROM task_attempts ta
      WHERE ta.user_id = $2 AND ta.task_id = t.id AND ta.practice = FALSE
    )`;

    let task;
    if (feature === 'verification') {
      const difficulties = preferredDifficulties(Number(user.level));
      const result = await pool.query(
        `SELECT t.id, t.feature, v.title, v.scenario, v.embedded_flaw, v.difficulty
         FROM tasks t
         JOIN verification_tasks v ON v.task_id = t.id
         WHERE t.feature = 'verification' AND t.track_id = $1 AND ${seenFilter}
         ORDER BY CASE v.difficulty
           WHEN $3 THEN 0 WHEN $4 THEN 1 WHEN $5 THEN 2 ELSE 3
         END, t.id ASC
         LIMIT 1`,
        [user.industry_track_id, user.id, difficulties[0], difficulties[1], difficulties[2]]
      );
      task = result.rows[0];
      if (task) {
        const options = await pool.query(
          `SELECT id, label FROM task_options WHERE task_id = $1 AND kind = 'answer' ORDER BY sort_order`,
          [task.id]
        );
        task.options = options.rows;
      }
    } else {
      const table = feature === 'judgement' ? 'judgement_tasks' : 'risk_governance_tasks';
      const result = await pool.query(
        `SELECT t.id, t.feature, f.title, f.scenario
         FROM tasks t
         JOIN ${table} f ON f.task_id = t.id
         WHERE t.feature = $1 AND t.track_id = $2 AND ${seenFilter}
         ORDER BY t.id ASC
         LIMIT 1`,
        [feature, user.industry_track_id, user.id]
      );
      task = result.rows[0];
      if (task) {
        const options = await pool.query(
          `SELECT id, kind, label FROM task_options WHERE task_id = $1 ORDER BY kind, sort_order`,
          [task.id]
        );
        task.options = options.rows;
      }
    }

    if (!task) {
      return res.status(200).json({
        task: null,
        message: 'No unseen tasks are currently available for your selected track.',
        request_id: req.requestId,
      });
    }

    return res.status(200).json({ task, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// POST /api/tasks/:id/attempt
// ---------------------------------------------------------------------------
async function submitAttempt(req, res, next) {
  let client = null;

  try {
    const taskId = positiveIntegerParam(req.params.id, 'task id');
    client = await pool.connect();
    await client.query('BEGIN');

    const user = await getCurrentUser(client, req.firebaseUser.uid);
    if (!user) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }

    const taskResult = await client.query(
      `SELECT id, feature, track_id FROM tasks WHERE id = $1 FOR SHARE`,
      [taskId]
    );
    if (!taskResult.rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Task not found.', request_id: req.requestId });
    }

    const task = taskResult.rows[0];
    if (!user.industry_track_id) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Select an industry track before submitting a task.', request_id: req.requestId });
    }
    if (Number(task.track_id) !== Number(user.industry_track_id)) {
      await client.query('ROLLBACK');
      return res.status(403).json({ error: 'Task is not available for the selected industry track.', request_id: req.requestId });
    }

    const content = await loadTaskContent(client, task);
    const practice = req.body.practice === true;

    let scored;
    try {
      scored = scoreByFeature(task.feature, content, req.body);
    } catch (err) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: err.message, request_id: req.requestId });
    }

    const passed = scored.score >= PASS_THRESHOLD[task.feature];
    const xpEarned = practice ? 0 : calculateXp(scored.score, content.difficulty);

    const attemptResult = await client.query(
      `INSERT INTO task_attempts
        (user_id, task_id, answer, rationale, answer_option_id, decision_option_id,
         reason_option_id, task_title, score, passed, practice, feedback, xp_earned)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
       RETURNING id, task_id, score, passed, practice, xp_earned, submitted_at`,
      [
        user.id, task.id, scored.answer, scored.rationale, scored.answerOptionId,
        scored.decisionOptionId, scored.reasonOptionId, content.title, scored.score,
        passed, practice, content.feedback, xpEarned,
      ]
    );

    let progress = null;
    let skillScore = null;
    let newlyEarned = [];

    if (!practice) {
      skillScore = await updateSkillScore(client, user.id, FEATURE_DIMENSION[task.feature], scored.score);
      progress = await updateProgress(client, user, xpEarned, passed);
      await refreshReadiness(client, user.id, user.industry_track_id);
      newlyEarned = await awardAchievements(client, user.id);
    }

    await client.query('COMMIT');

    return res.status(201).json({
      attempt: attemptResult.rows[0],
      result: {
        score: scored.score,
        passed,
        feedback: content.feedback,
        xp_earned: xpEarned,
        practice,
        correct_option_id: content.correctOptionId ?? null,
        correct_decision_id: content.correctDecisionId ?? null,
        correct_reason_id: content.correctReasonId ?? null,
      },
      skill_score: skillScore,
      progress,
      newly_earned_achievements: newlyEarned,
      request_id: req.requestId,
    });
  } catch (err) {
    if (client) await client.query('ROLLBACK').catch(() => {});
    return next(err);
  } finally {
    if (client) client.release();
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function loadTaskContent(client, task) {
  const optionsResult = await client.query(
    `SELECT id, kind, label, score FROM task_options WHERE task_id = $1 ORDER BY kind, sort_order`,
    [task.id]
  );
  const options = optionsResult.rows;

  if (task.feature === 'verification') {
    const r = await client.query(
      `SELECT title, scenario, embedded_flaw, expected_answer, feedback, difficulty, keywords
       FROM verification_tasks WHERE task_id = $1`,
      [task.id]
    );
    const row = r.rows[0] || {};
    const answerOptions = options.filter((o) => o.kind === 'answer');
    const correct = answerOptions.find((o) => o.score >= 100);
    return {
      title: row.title,
      feedback: row.feedback,
      difficulty: row.difficulty,
      expectedAnswer: row.expected_answer,
      keywords: row.keywords,
      options: answerOptions,
      correctOptionId: correct ? correct.id : null,
    };
  }

  if (task.feature === 'judgement' || task.feature === 'risk_governance') {
    const table = task.feature === 'judgement' ? 'judgement_tasks' : 'risk_governance_tasks';
    const r = await client.query(`SELECT title, feedback FROM ${table} WHERE task_id = $1`, [task.id]);
    const row = r.rows[0] || {};
    const decisions = options.filter((o) => o.kind === 'decision');
    const reasons = options.filter((o) => o.kind === 'reason');
    const bestDecision = decisions.reduce((a, b) => (b.score > (a?.score ?? -1) ? b : a), null);
    const bestReason = reasons.reduce((a, b) => (b.score > (a?.score ?? -1) ? b : a), null);
    return {
      title: row.title,
      feedback: row.feedback,
      difficulty: 'medium',
      decisions,
      reasons,
      correctDecisionId: bestDecision ? bestDecision.id : null,
      correctReasonId: bestReason ? bestReason.id : null,
    };
  }

  throw new Error('Prompt Design tasks are not supported yet.');
}

function scoreByFeature(feature, content, body) {
  if (feature === 'verification') {
    if (body.answer_option_id != null) {
      const id = positiveIntegerParam(body.answer_option_id, 'answer option id');
      const option = content.options.find((o) => o.id === id);
      if (!option) throw new Error('Selected option does not belong to this task.');
      return { score: option.score, answerOptionId: id, answer: null, rationale: null, decisionOptionId: null, reasonOptionId: null };
    }
    if (content.keywords && content.keywords.length && body.answer != null) {
      const answer = requiredString(body.answer, 'answer', 10000);
      const result = scoreAnswer(answer, content.keywords.join(', '));
      return { score: result.score, answer, answerOptionId: null, rationale: null, decisionOptionId: null, reasonOptionId: null };
    }
    throw new Error('An answer option is required for this task.');
  }

  // judgement / risk_governance
  const decisionId = positiveIntegerParam(body.decision_option_id, 'decision option id');
  const reasonId = positiveIntegerParam(body.reason_option_id, 'reason option id');
  const decision = content.decisions.find((o) => o.id === decisionId);
  const reason = content.reasons.find((o) => o.id === reasonId);
  if (!decision) throw new Error('Selected decision does not belong to this task.');
  if (!reason) throw new Error('Selected reason does not belong to this task.');
  const rationale = body.rationale == null ? null : requiredString(body.rationale, 'rationale', 5000);
  return {
    score: scoreOptions([decision.score, reason.score]),
    decisionOptionId: decisionId,
    reasonOptionId: reasonId,
    rationale,
    answer: null,
    answerOptionId: null,
  };
}

async function updateSkillScore(client, userId, dimension, score) {
  const result = await client.query(
    `INSERT INTO skill_scores (user_id, dimension, score, attempts_count, updated_at)
     VALUES ($1, $2, $3, 1, CURRENT_TIMESTAMP)
     ON CONFLICT (user_id, dimension)
     DO UPDATE SET
       score = ROUND(((skill_scores.score * skill_scores.attempts_count) + EXCLUDED.score)::numeric / (skill_scores.attempts_count + 1)),
       attempts_count = skill_scores.attempts_count + 1,
       updated_at = CURRENT_TIMESTAMP
     RETURNING dimension, score, attempts_count`,
    [userId, dimension, score]
  );
  return result.rows[0];
}

async function updateProgress(client, user, xpEarned, passed) {
  const progressResult = await client.query(
    `INSERT INTO user_progress (user_id, xp, level, streak, last_activity_date)
     VALUES ($1, 0, 1, 0, NULL)
     ON CONFLICT (user_id) DO UPDATE SET user_id = EXCLUDED.user_id
     RETURNING id, xp, level, streak, last_activity_date, tier, tier_tasks_completed`,
    [user.id]
  );
  const progress = progressResult.rows[0];

  let newStreak = progress.streak;
  if (!progress.last_activity_date) {
    newStreak = 1;
  } else {
    const dateResult = await client.query(
      `SELECT CURRENT_DATE AS today, CURRENT_DATE - last_activity_date AS day_gap
       FROM user_progress WHERE id = $1`,
      [progress.id]
    );
    const dayGap = dateResult.rows[0].day_gap;
    if (Number(dayGap) === 0) newStreak = progress.streak;
    else if (Number(dayGap) === 1) newStreak = progress.streak + 1;
    else newStreak = 1;
  }

  const newXp = Number(progress.xp) + xpEarned;
  const newLevel = calculateLevel(newXp);

  let tier = progress.tier || 'Novice';
  let tierCount = progress.tier_tasks_completed || 0;
  if (passed) {
    const idx = TIERS.findIndex((t) => t.name === tier);
    tierCount += 1;
    if (idx >= 0 && idx < TIERS.length - 1 && tierCount >= TIERS[idx].required) {
      tier = TIERS[idx + 1].name;
      tierCount = 0;
    }
  }

  const updated = await client.query(
    `UPDATE user_progress
     SET xp = $1, level = $2, streak = $3, last_activity_date = CURRENT_DATE,
         tier = $4, tier_tasks_completed = $5, updated_at = CURRENT_TIMESTAMP
     WHERE user_id = $6
     RETURNING xp, level, streak, last_activity_date, tier, tier_tasks_completed, readiness_score`,
    [newXp, newLevel, newStreak, tier, tierCount, user.id]
  );
  return updated.rows[0];
}

// Weighted mean of the skill scores (+ interview coverage), stored monotonically.
async function refreshReadiness(client, userId, trackId) {
  const scores = await client.query(
    `SELECT dimension, score FROM skill_scores WHERE user_id = $1`,
    [userId]
  );
  const parts = [];
  for (const row of scores.rows) {
    const weight = READINESS_WEIGHTS[row.dimension];
    if (weight) parts.push({ weight, score: Number(row.score) });
  }

  const total = await client.query(
    `SELECT COUNT(*)::int AS total FROM interview_questions WHERE track_id = $1`,
    [trackId]
  );
  if (total.rows[0].total > 0) {
    const practised = await client.query(
      `SELECT COUNT(*)::int AS n
       FROM interview_practice ip
       JOIN interview_questions q ON q.id = ip.question_id
       WHERE ip.user_id = $1 AND q.track_id = $2`,
      [userId, trackId]
    );
    const interviewScore = Math.round((100 * practised.rows[0].n) / total.rows[0].total);
    parts.push({ weight: READINESS_WEIGHTS.Interview, score: interviewScore });
  }

  if (!parts.length) return;
  const sumWeight = parts.reduce((s, p) => s + p.weight, 0);
  const value = Math.round(parts.reduce((s, p) => s + p.weight * p.score, 0) / sumWeight);

  await client.query(
    `UPDATE user_progress
     SET readiness_score = GREATEST(readiness_score, $1)
     WHERE user_id = $2`,
    [Math.max(0, Math.min(100, value)), userId]
  );
}

async function awardAchievements(client, userId) {
  const stats = await client.query(
    `SELECT COUNT(*)::int AS attempts, COALESCE(SUM(xp_earned), 0)::int AS xp
     FROM task_attempts WHERE user_id = $1 AND practice = FALSE`,
    [userId]
  );
  const dimension = await client.query(
    `SELECT COALESCE(MAX(score), 0)::int AS best_dimension
     FROM skill_scores WHERE user_id = $1`,
    [userId]
  );

  const values = stats.rows[0];
  const bestDimension = dimension.rows[0].best_dimension;
  const eligible = await client.query(
    `SELECT id, code, name, description
     FROM achievements
     WHERE ((code = 'first-task' AND $2 >= 1)
        OR (code = 'five-tasks' AND $2 >= 5)
        OR (code = 'ten-tasks' AND $2 >= 10)
        OR (code = 'xp-500' AND $3 >= 500)
        OR (code = 'dimension-80' AND $4 >= 80))
     AND NOT EXISTS (
       SELECT 1 FROM user_achievements ua WHERE ua.user_id = $1 AND ua.achievement_id = achievements.id
     )`,
    [userId, values.attempts, values.xp, bestDimension]
  );

  const newlyEarned = [];
  for (const achievement of eligible.rows) {
    const inserted = await client.query(
      `INSERT INTO user_achievements (user_id, achievement_id)
       VALUES ($1, $2) ON CONFLICT DO NOTHING RETURNING achievement_id`,
      [userId, achievement.id]
    );
    if (inserted.rows.length) newlyEarned.push(achievement);
  }
  return newlyEarned;
}

module.exports = { getNextTask, submitAttempt, awardAchievements };
