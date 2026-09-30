const pool = require('../db/pool');
const { positiveIntegerParam, requiredString } = require('../middleware/validate');
const { scoreAnswer, calculateXp, calculateLevel } = require('../services/scoringService');

async function getCurrentUser(client, firebaseUid) {
  const result = await client.query(
    `SELECT id, industry_track_id
     FROM users
     WHERE firebase_uid = $1`,
    [firebaseUid]
  );
  return result.rows[0] || null;
}

function preferredDifficulties(level) {
  if (level <= 1) return ['easy', 'medium'];
  if (level <= 3) return ['medium', 'easy', 'hard'];
  return ['hard', 'medium', 'easy'];
}

async function getNextTask(req, res, next) {
  try {
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

    const difficulties = preferredDifficulties(Number(user.level));
    const result = await pool.query(
      `SELECT t.id, t.track_id, t.title, t.scenario, t.dimension, t.difficulty
       FROM tasks t
       WHERE t.track_id = $1
         AND NOT EXISTS (
           SELECT 1 FROM task_attempts ta
           WHERE ta.user_id = $2 AND ta.task_id = t.id
         )
       ORDER BY CASE t.difficulty
         WHEN $3 THEN 0
         WHEN $4 THEN 1
         WHEN $5 THEN 2
         ELSE 3
       END,
       t.id ASC
       LIMIT 1`,
      [user.industry_track_id, user.id, difficulties[0], difficulties[1], difficulties[2]]
    );

    if (!result.rows.length) {
      return res.status(200).json({ task: null, message: 'No unseen tasks are currently available for your selected track.', request_id: req.requestId });
    }

    return res.status(200).json({ task: result.rows[0], request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

async function submitAttempt(req, res, next) {
  let client = null;

  try {
    const taskId = positiveIntegerParam(req.params.id, 'task id');
    const answer = requiredString(req.body.answer, 'answer', 10000);
    client = await pool.connect();

    await client.query('BEGIN');

    const user = await getCurrentUser(client, req.firebaseUser.uid);
    if (!user) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }

    const taskResult = await client.query(
      `SELECT id, track_id, title, scenario, correct_answer, dimension, difficulty, feedback
       FROM tasks
       WHERE id = $1
       FOR SHARE`,
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

    const scoring = scoreAnswer(answer, task.correct_answer || '');
    const xpEarned = calculateXp(scoring.score);

    const progressResult = await client.query(
      `INSERT INTO user_progress (user_id, xp, level, streak, last_activity_date)
       VALUES ($1, 0, 1, 0, NULL)
       ON CONFLICT (user_id) DO UPDATE SET user_id = EXCLUDED.user_id
       RETURNING id, xp, level, streak, last_activity_date`,
      [user.id]
    );
    const progress = progressResult.rows[0];

    let newStreak = progress.streak;
    if (!progress.last_activity_date) {
      newStreak = 1;
    } else {
      const dateResult = await client.query(
        `SELECT CURRENT_DATE AS today,
                CURRENT_DATE - last_activity_date AS day_gap
         FROM user_progress WHERE id = $1`,
        [progress.id]
      );
      const { day_gap: dayGap } = dateResult.rows[0];
      if (Number(dayGap) === 0) newStreak = progress.streak;
      else if (Number(dayGap) === 1) newStreak = progress.streak + 1;
      else newStreak = 1;
    }

    const newXp = Number(progress.xp) + xpEarned;
    const newLevel = calculateLevel(newXp);

    const attemptResult = await client.query(
      `INSERT INTO task_attempts (user_id, task_id, answer, score, feedback, xp_earned)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, task_id, score, xp_earned, submitted_at`,
      [user.id, task.id, answer, scoring.score, task.feedback, xpEarned]
    );

    const scoreResult = await client.query(
      `INSERT INTO skill_scores (user_id, dimension, score, attempts_count, updated_at)
       VALUES ($1, $2, $3, 1, CURRENT_TIMESTAMP)
       ON CONFLICT (user_id, dimension)
       DO UPDATE SET
         score = ROUND(((skill_scores.score * skill_scores.attempts_count) + EXCLUDED.score)::numeric / (skill_scores.attempts_count + 1)),
         attempts_count = skill_scores.attempts_count + 1,
         updated_at = CURRENT_TIMESTAMP
       RETURNING dimension, score, attempts_count`,
      [user.id, task.dimension, scoring.score]
    );

    const progressUpdate = await client.query(
      `UPDATE user_progress
       SET xp = $1, level = $2, streak = $3, last_activity_date = CURRENT_DATE, updated_at = CURRENT_TIMESTAMP
       WHERE user_id = $4
       RETURNING xp, level, streak, last_activity_date`,
      [newXp, newLevel, newStreak, user.id]
    );

    const achievementResult = await awardAchievements(client, user.id);

    await client.query('COMMIT');

    return res.status(201).json({
      attempt: attemptResult.rows[0],
      result: {
        score: scoring.score,
        passed: scoring.passed,
        matched_keywords: scoring.matchedKeywords,
        missed_keywords: scoring.missedKeywords,
        feedback: task.feedback,
        xp_earned: xpEarned,
      },
      skill_score: scoreResult.rows[0],
      progress: progressUpdate.rows[0],
      newly_earned_achievements: achievementResult,
      request_id: req.requestId,
    });
  } catch (err) {
    if (client) await client.query('ROLLBACK').catch(() => {});
    return next(err);
  } finally {
    if (client) client.release();
  }
}

async function awardAchievements(client, userId) {
  const stats = await client.query(
    `SELECT COUNT(*)::int AS attempts,
            COALESCE(SUM(xp_earned), 0)::int AS xp
     FROM task_attempts WHERE user_id = $1`,
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
       VALUES ($1, $2)
       ON CONFLICT DO NOTHING
       RETURNING achievement_id`,
      [userId, achievement.id]
    );
    if (inserted.rows.length) newlyEarned.push(achievement);
  }
  return newlyEarned;
}

module.exports = { getNextTask, submitAttempt, awardAchievements };
