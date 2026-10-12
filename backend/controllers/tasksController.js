const pool = require('../db/pool');
const { positiveIntegerParam, requiredString } = require('../middleware/validate');
const {
  scoreOptions,
  scoreCriteria,
  scoreFlawLines,
  FIX_POINTS,
  REASON_POINTS,
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

// Streak days are anchored to this timezone, NOT the database server clock
// (which is usually UTC). A SAST user active at 00:30 local must roll into the
// new local day even though UTC still shows the previous date.
const STREAK_TIMEZONE = process.env.STREAK_TIMEZONE || 'Africa/Johannesburg';

const FEATURES = new Set(Object.keys(FEATURE_DIMENSION));

// API `dimension` display names (case-insensitive) -> feature key.
const DIMENSION_FEATURE = {
  verification: 'verification',
  'ai judgement': 'judgement',
  'risk & governance': 'risk_governance',
  'prompt design': 'prompt_design',
};

// Resolves ?feature= / ?dimension= into one feature key. `byId` is true when
// the caller named a dimension explicitly, which drops the difficulty ordering
// (the caller is asking for a specific mode, not the level-adaptive default).
function resolveFeature(query) {
  const rawFeature = query.feature == null ? null : String(query.feature).toLowerCase().trim();
  const rawDimension = query.dimension == null ? null : String(query.dimension).toLowerCase().trim();

  if (rawFeature != null && !FEATURES.has(rawFeature)) return { error: 'Unknown feature.' };
  if (rawDimension != null && !DIMENSION_FEATURE[rawDimension]) return { error: 'Unknown dimension.' };

  let feature = rawFeature;
  if (rawDimension != null) {
    const mapped = DIMENSION_FEATURE[rawDimension];
    if (feature != null && feature !== mapped) return { error: 'feature and dimension do not match.' };
    feature = mapped;
  }

  return { feature: feature || 'verification', byId: rawDimension != null };
}

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
// GET /api/tasks/next?feature=verification | ?dimension=AI%20Judgement
// ---------------------------------------------------------------------------
async function getNextTask(req, res, next) {
  try {
    const { feature, byId, error } = resolveFeature(req.query);
    if (error) {
      return res.status(400).json({ error, request_id: req.requestId });
    }

    // Optional ?difficulty= pins the next task to one band (used by the app's
    // "Continue" action to stay on the same difficulty). Verification only.
    const rawDifficulty = req.query.difficulty == null ? null : String(req.query.difficulty).toLowerCase().trim();
    if (rawDifficulty != null && !['easy', 'medium', 'hard'].includes(rawDifficulty)) {
      return res.status(400).json({ error: 'Unknown difficulty.', request_id: req.requestId });
    }
    const difficulty = rawDifficulty;

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

    // Shared "not already attempted" guard. The user-id placeholder differs
    // between the two branches below (the verification query puts the track at
    // $1 and the user at $2, while the judgement/risk query adds a leading
    // `feature` parameter), so it is passed in rather than hardcoded.
    const seenFilter = (userParam) => `NOT EXISTS (
      SELECT 1 FROM task_attempts ta
      WHERE ta.user_id = ${userParam} AND ta.task_id = t.id AND ta.practice = FALSE
    )`;

    let task;
    if (feature === 'verification') {
      const params = [user.industry_track_id, user.id];
      let order = 't.id ASC';
      if (!byId) {
        const difficulties = preferredDifficulties(Number(user.level));
        params.push(difficulties[0], difficulties[1], difficulties[2]);
        order = `CASE v.difficulty
           WHEN $3 THEN 0 WHEN $4 THEN 1 WHEN $5 THEN 2 ELSE 3
         END, t.id ASC`;
      }
      let difficultyFilter = '';
      if (difficulty) {
        params.push(difficulty);
        difficultyFilter = ` AND v.difficulty = $${params.length}`;
      }
      const result = await pool.query(
        `SELECT t.id, v.format, v.title, v.scenario, v.embedded_flaw, v.difficulty, v.ai_output_lines
         FROM tasks t
         JOIN verification_tasks v ON v.task_id = t.id
         WHERE t.feature = 'verification' AND t.track_id = $1 AND ${seenFilter('$2')}${difficultyFilter}
         ORDER BY ${order}
         LIMIT 1`,
        params
      );
      let row = result.rows[0];
      let isRepeat = false;
      // A pinned band with no unseen tasks left rotates the tasks already
      // attempted in that band (least-recently attempted first), so the card
      // keeps working as practice until new tasks are added.
      if (!row && difficulty) {
        const rotateResult = await pool.query(
          `SELECT t.id, v.format, v.title, v.scenario, v.embedded_flaw, v.difficulty, v.ai_output_lines,
                  COALESCE(MAX(ta.submitted_at), to_timestamp(0)) AS last_submitted
           FROM tasks t
           JOIN verification_tasks v ON v.task_id = t.id
           LEFT JOIN task_attempts ta ON ta.task_id = t.id AND ta.user_id = $2
           WHERE t.feature = 'verification' AND t.track_id = $1 AND v.difficulty = $3
           GROUP BY t.id, v.format, v.title, v.scenario, v.embedded_flaw, v.difficulty, v.ai_output_lines
           ORDER BY last_submitted ASC, t.id ASC
           LIMIT 1`,
          [user.industry_track_id, user.id, difficulty]
        );
        row = rotateResult.rows[0] || null;
        isRepeat = !!row;
      }
      if (row && row.format === 'line_text') {
        task = {
          id: row.id,
          feature: 'verification',
          format: 'line_text',
          title: row.title,
          scenario: row.scenario,
          difficulty: row.difficulty,
          ai_output_lines: row.ai_output_lines,
        };
      } else if (row) {
        const options = await pool.query(
          `SELECT id, label FROM task_options WHERE task_id = $1 AND kind = 'answer' ORDER BY sort_order`,
          [row.id]
        );
        task = {
          id: row.id,
          feature: 'verification',
          format: 'choice',
          title: row.title,
          scenario: row.scenario,
          embedded_flaw: row.embedded_flaw,
          difficulty: row.difficulty,
          options: options.rows,
        };
      }
      if (isRepeat) task = { ...task, is_repeat: true };
    } else {
      const table = feature === 'judgement' ? 'judgement_tasks' : 'risk_governance_tasks';
      const result = await pool.query(
        `SELECT t.id, t.feature, f.title, f.scenario
         FROM tasks t
         JOIN ${table} f ON f.task_id = t.id
         WHERE t.feature = $1 AND t.track_id = $2 AND ${seenFilter('$3')}
         ORDER BY t.id ASC
         LIMIT 1`,
        [feature, user.industry_track_id, user.id]
      );
      let row = result.rows[0];
      let isRepeat = false;
      // No unseen tasks left: rotate the track's tasks (least-recently attempted
      // first) so the card keeps working as practice.
      if (!row) {
        const rotateResult = await pool.query(
          `SELECT t.id, t.feature, f.title, f.scenario,
                  COALESCE(MAX(ta.submitted_at), to_timestamp(0)) AS last_submitted
           FROM tasks t
           JOIN ${table} f ON f.task_id = t.id
           LEFT JOIN task_attempts ta ON ta.task_id = t.id AND ta.user_id = $3
           WHERE t.feature = $1 AND t.track_id = $2
           GROUP BY t.id, t.feature, f.title, f.scenario
           ORDER BY last_submitted ASC, t.id ASC
           LIMIT 1`,
          [feature, user.industry_track_id, user.id]
        );
        row = rotateResult.rows[0] || null;
        isRepeat = !!row;
      }
      if (row) {
        const options = await pool.query(
          `SELECT id, kind, label FROM task_options WHERE task_id = $1 ORDER BY kind, sort_order`,
          [row.id]
        );
        task = {
          id: row.id,
          feature: row.feature,
          title: row.title,
          scenario: row.scenario,
          options: options.rows,
        };
        if (isRepeat) task.is_repeat = true;
      }
    }

    if (!task) {
      return res.status(200).json({
        task: null,
        message: 'No unseen tasks are currently available for your selected track.',
        request_id: req.requestId,
      });
    }

    // The app's DailyTask requires `dimension`; `feature` is the schema key.
    task.dimension = FEATURE_DIMENSION[feature];

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
         reason_option_id, selected_lines, task_title, score, passed, practice, feedback, xp_earned)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
       RETURNING id, task_id, score, passed, practice, xp_earned, submitted_at`,
      [
        user.id, task.id, scored.answer, scored.rationale, scored.answerOptionId,
        scored.decisionOptionId, scored.reasonOptionId, scored.selectedLines, content.title,
        scored.score, passed, practice, content.feedback, xpEarned,
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
        flaw_lines: content.flawLines ?? null,
        expected_answer: content.expectedAnswer ?? null,
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
      `SELECT format, title, scenario, embedded_flaw, expected_answer, feedback, difficulty,
              ai_output_lines, flaw_lines, fix_keywords, reason_keywords
       FROM verification_tasks WHERE task_id = $1`,
      [task.id]
    );
    const row = r.rows[0] || {};
    if (row.format === 'line_text') {
      return {
        format: 'line_text',
        title: row.title,
        feedback: row.feedback,
        difficulty: row.difficulty,
        aiOutputLines: row.ai_output_lines,
        flawLines: row.flaw_lines,
        expectedAnswer: row.expected_answer,
        fixKeywords: row.fix_keywords,
        reasonKeywords: row.reason_keywords,
      };
    }
    const answerOptions = options.filter((o) => o.kind === 'answer');
    const correct = answerOptions.find((o) => o.score >= 100);
    return {
      format: 'choice',
      title: row.title,
      feedback: row.feedback,
      difficulty: row.difficulty,
      expectedAnswer: row.expected_answer,
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
    if (content.format === 'line_text') {
      const selected = Array.isArray(body.selected_lines) ? body.selected_lines.map(Number) : [];
      if (!selected.length) throw new Error('Select the flawed line(s) first.');
      const fix = String(body.fix == null ? '' : body.fix);
      const reason = String(body.reason == null ? '' : body.reason);
      const flawScore = scoreFlawLines(selected, content.flawLines);
      const fixResult = scoreCriteria(fix, content.fixKeywords, FIX_POINTS);
      const reasonResult = scoreCriteria(reason, content.reasonKeywords, REASON_POINTS);
      return {
        score: flawScore + fixResult.score + reasonResult.score,
        selectedLines: selected,
        answer: fix,
        rationale: reason,
        answerOptionId: null,
        decisionOptionId: null,
        reasonOptionId: null,
      };
    }
    if (body.answer_option_id != null) {
      const id = positiveIntegerParam(body.answer_option_id, 'answer option id');
      const option = content.options.find((o) => o.id === id);
      if (!option) throw new Error('Selected option does not belong to this task.');
      return { score: option.score, answerOptionId: id, answer: null, rationale: null, decisionOptionId: null, reasonOptionId: null, selectedLines: null };
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
    // Optional: an omitted or blank rationale is stored as NULL.
    const rationaleRaw = body.rationale == null ? '' : String(body.rationale).trim();
    const rationale = rationaleRaw.length ? rationaleRaw.slice(0, 5000) : null;
  return {
    score: scoreOptions([decision.score, reason.score]),
    decisionOptionId: decisionId,
    reasonOptionId: reasonId,
    rationale,
    answer: null,
    answerOptionId: null,
    selectedLines: null,
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
      `SELECT (NOW() AT TIME ZONE $2)::date AS today,
              (NOW() AT TIME ZONE $2)::date - last_activity_date AS day_gap
       FROM user_progress WHERE id = $1`,
      [progress.id, STREAK_TIMEZONE]
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
     SET xp = $1, level = $2, streak = $3,
         last_activity_date = (NOW() AT TIME ZONE $7)::date,
         tier = $4, tier_tasks_completed = $5, updated_at = CURRENT_TIMESTAMP
     WHERE user_id = $6
     RETURNING xp, level, streak, last_activity_date, tier, tier_tasks_completed, readiness_score`,
    [newXp, newLevel, newStreak, tier, tierCount, user.id, STREAK_TIMEZONE]
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
    `SELECT COUNT(DISTINCT task_id) FILTER (WHERE passed)::int AS attempts,
            COALESCE(SUM(xp_earned), 0)::int AS xp
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

// ---------------------------------------------------------------------------
// GET /api/tasks/history?limit=&offset=&feature=&passed=
// The user's scored attempts (practice excluded), newest first.
// ---------------------------------------------------------------------------
const HISTORY_DEFAULT_LIMIT = 20;
const HISTORY_MAX_LIMIT = 50;

function clampInt(raw, fallback, min, max) {
  const parsed = Number.parseInt(raw, 10);
  if (!Number.isInteger(parsed)) return fallback;
  return Math.min(max, Math.max(min, parsed));
}

async function getHistory(req, res, next) {
  try {
    const limit = clampInt(req.query.limit, HISTORY_DEFAULT_LIMIT, 1, HISTORY_MAX_LIMIT);
    const offset = clampInt(req.query.offset, 0, 0, 100000);

    const feature = req.query.feature == null ? null : String(req.query.feature).toLowerCase().trim();
    if (feature != null && !FEATURES.has(feature)) {
      return res.status(400).json({ error: 'Unknown feature.', request_id: req.requestId });
    }

    let passedFilter = null;
    if (req.query.passed != null) {
      const value = String(req.query.passed).toLowerCase();
      if (value === 'true') passedFilter = true;
      else if (value === 'false') passedFilter = false;
      else return res.status(400).json({ error: 'passed must be true or false.', request_id: req.requestId });
    }

    const userResult = await pool.query(
      `SELECT id FROM users WHERE firebase_uid = $1`,
      [req.firebaseUser.uid]
    );
    if (!userResult.rows.length) {
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }

    const params = [userResult.rows[0].id];
    let where = 'WHERE ta.user_id = $1 AND ta.practice = FALSE';
    if (feature) {
      params.push(feature);
      where += ` AND t.feature = $${params.length}`;
    }
    if (passedFilter !== null) {
      params.push(passedFilter);
      where += ` AND ta.passed = $${params.length}`;
    }

    const totalResult = await pool.query(
      `SELECT COUNT(*)::int AS total
       FROM task_attempts ta
       JOIN tasks t ON t.id = ta.task_id
       ${where}`,
      params
    );

    params.push(limit, offset);
    const rows = await pool.query(
      `SELECT ta.id, ta.task_id, t.feature, ta.task_title AS title, ta.score,
              ta.passed, ta.xp_earned, ta.submitted_at, ta.feedback,
              ta.answer, ta.rationale, ta.selected_lines
       FROM task_attempts ta
       JOIN tasks t ON t.id = ta.task_id
       ${where}
       ORDER BY ta.submitted_at DESC, ta.id DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    return res.status(200).json({
      attempts: rows.rows,
      total: totalResult.rows[0].total,
      limit,
      offset,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  getNextTask,
  submitAttempt,
  getHistory,
  awardAchievements,
  refreshReadiness,
  scoreByFeature,
  updateProgress,
};
