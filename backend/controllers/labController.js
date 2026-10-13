const pool = require('../db/pool');
const { optionalString, clampInt, positiveIntegerParam } = require('../middleware/validate');
const { findUserByFirebaseUid } = require('../db/users');
const { getCoachReply, streamCoachReply } = require('../services/nvidiaAssistant');
const { gradeActivity } = require('../services/activityGrading');
const { awardXp } = require('../services/xpService');
const { grantTokens } = require('../services/rewardTokens');
const { refreshReadiness } = require('../services/readinessService');
const { validateMessages } = require('./assistantController');
const { handleAiError } = require('../middleware/aiError');
const { openStream, sendEvent, endStream } = require('../middleware/sse');

const PASS_SCORE = 60;
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const LESSON_FIELDS = `id, code, title, summary, estimated_minutes, level, competency, is_original`;

function notFound(res, req, message = 'Lesson not found for your selected track.') {
  return res.status(404).json({ error: message, request_id: req.requestId });
}

async function requireUser(res, req) {
  const user = await findUserByFirebaseUid(pool, req.firebaseUser.uid);
  if (!user) {
    res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    return null;
  }
  return user;
}

// A lesson is available when it is global (track_id NULL) or belongs to the
// user's track.
async function findLessonForUser(executor, code, trackId) {
  const result = await executor.query(
    `SELECT ${LESSON_FIELDS} FROM lab_lessons WHERE code = $1 AND (track_id IS NULL OR track_id = $2)`,
    [code, trackId],
  );
  return result.rows[0] || null;
}

// Recomputes completion from live counts so status can never drift.
async function recomputeStatus(client, userId, lessonId) {
  await client.query(
    `UPDATE lab_lesson_progress p
     SET status = CASE
         WHEN p.sections_completed >= (SELECT COUNT(*)::int FROM lab_lesson_sections s WHERE s.lesson_id = $2)
          AND p.activities_completed >= (SELECT COUNT(*)::int FROM lab_activities a WHERE a.lesson_id = $2)
          AND p.assessment_best_score >= $3
         THEN 'completed' ELSE 'in_progress' END
     WHERE p.user_id = $1 AND p.lesson_id = $2`,
    [userId, lessonId, PASS_SCORE],
  );
}

async function lessonSources(executor, lessonId) {
  const result = await executor.query(
    `SELECT cs.id, cs.title, cs.author, cs.publisher, cs.edition, cs.source_url,
            cs.license, cs.license_url, cs.industry, ls.use_type, ls.changes_made
     FROM lesson_sources ls
     JOIN content_sources cs ON cs.id = ls.source_id
     WHERE ls.lesson_id = $1
     ORDER BY cs.title`,
    [lessonId],
  );
  return result.rows;
}

async function lessonAttributions(executor, lessonId) {
  const result = await executor.query(
    `SELECT credit_line, source_url, license_url, title, license, use_type
     FROM lesson_attributions WHERE lesson_id = $1 ORDER BY title`,
    [lessonId],
  );
  return result.rows;
}

async function lessonShareAlike(executor, lessonId) {
  const result = await executor.query(
    `SELECT EXISTS (SELECT 1 FROM lessons_needing_share_alike WHERE id = $1) AS share_alike`,
    [lessonId],
  );
  return result.rows[0]?.share_alike === true;
}

// GET /api/lab/lessons
async function listLessons(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const result = await pool.query(
      `SELECT l.id, l.code, l.title, l.summary, l.estimated_minutes, l.level, l.competency, l.sort_order,
              (SELECT COUNT(*)::int FROM lab_lesson_sections s WHERE s.lesson_id = l.id) AS sections_count,
              (SELECT COUNT(*)::int FROM lab_activities a WHERE a.lesson_id = l.id) AS activities_count,
              (SELECT COUNT(*)::int FROM lab_questions q WHERE q.lesson_id = l.id) AS questions_count,
              COALESCE(p.sections_completed, 0)::int AS sections_completed,
              COALESCE(p.activities_completed, 0)::int AS activities_completed,
              COALESCE(p.assessment_best_score, 0)::int AS assessment_best_score,
              COALESCE(p.status, 'not_started') AS status,
              p.last_viewed_at,
              (p.user_id IS NOT NULL) AS seen
       FROM lab_lessons l
       LEFT JOIN lab_lesson_progress p ON p.lesson_id = l.id AND p.user_id = $1
       WHERE l.track_id IS NULL OR l.track_id = $2
       ORDER BY l.sort_order, l.id`,
      [user.id, user.industry_track_id],
    );

    return res.status(200).json({ lessons: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/lab/lessons/next?include_seen=<bool>
//
// Rotates content: prefer a lesson the learner has not opened yet; when none
// remain and include_seen is true (the default), serve the lesson they have
// gone longest without revisiting, so seen content is never locked away.
async function getNextLesson(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const includeSeen = String(req.query.include_seen ?? 'true').toLowerCase() !== 'false';

    const params = [user.id, user.industry_track_id];
    let where = 'WHERE (l.track_id IS NULL OR l.track_id = $2)';
    if (!includeSeen) where += ' AND p.user_id IS NULL';

    const result = await pool.query(
      `SELECT l.id, l.code, l.title, l.summary, l.estimated_minutes, l.level, l.competency,
              (p.user_id IS NOT NULL) AS seen, p.last_viewed_at
       FROM lab_lessons l
       LEFT JOIN lab_lesson_progress p ON p.lesson_id = l.id AND p.user_id = $1
       ${where}
       ORDER BY seen ASC, p.last_viewed_at ASC NULLS FIRST, l.sort_order, l.id
       LIMIT 1`,
      params,
    );

    if (!result.rows.length) {
      return res.status(200).json({ lesson: null, revisited: false, request_id: req.requestId });
    }
    const lesson = result.rows[0];
    return res.status(200).json({
      lesson,
      revisited: lesson.seen === true,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// GET /api/lab/lessons/:code
async function getLesson(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const lesson = await findLessonForUser(pool, req.params.code, user.industry_track_id);
    if (!lesson) return notFound(res, req);

    // Opening a lesson records recency (not completion) so it can be rotated
    // back in later; revisiting is always allowed.
    await pool.query(
      `INSERT INTO lab_lesson_progress (user_id, lesson_id, last_viewed_at)
       VALUES ($1, $2, now())
       ON CONFLICT (user_id, lesson_id) DO UPDATE SET last_viewed_at = now()`,
      [user.id, lesson.id],
    );

    const [sections, activities, questions, progress, sources, attributions, shareAlike] = await Promise.all([
      pool.query(
        `SELECT id, heading, body, sort_order FROM lab_lesson_sections WHERE lesson_id = $1 ORDER BY sort_order, id`,
        [lesson.id],
      ),
      pool.query(
        `SELECT a.id, a.type, a.prompt, a.payload, a.sort_order, a.xp_reward,
                EXISTS (SELECT 1 FROM lab_activity_attempts aa
                        WHERE aa.activity_id = a.id AND aa.user_id = $2 AND aa.passed) AS passed
         FROM lab_activities a WHERE a.lesson_id = $1 ORDER BY a.sort_order, a.id`,
        [lesson.id, user.id],
      ),
      // correct_index and explanation are withheld until the assessment is submitted.
      pool.query(
        `SELECT id, prompt, options, sort_order FROM lab_questions WHERE lesson_id = $1 ORDER BY sort_order, id`,
        [lesson.id],
      ),
      pool.query(
        `SELECT sections_completed, activities_completed, assessment_best_score, status, last_viewed_at
         FROM lab_lesson_progress WHERE user_id = $1 AND lesson_id = $2`,
        [user.id, lesson.id],
      ),
      lessonSources(pool, lesson.id),
      lessonAttributions(pool, lesson.id),
      lessonShareAlike(pool, lesson.id),
    ]);

    return res.status(200).json({
      lesson: {
        ...lesson,
        sections: sections.rows,
        activities: activities.rows,
        questions: questions.rows,
        sources,
        attributions,
        share_alike: shareAlike,
        progress: progress.rows[0] || {
          sections_completed: 0,
          activities_completed: 0,
          assessment_best_score: 0,
          status: 'not_started',
          last_viewed_at: null,
        },
      },
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// POST /api/lab/lessons/:code/progress  { sections_completed, activities_completed }
async function recordProgress(req, res, next) {
  let client = null;
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const lesson = await findLessonForUser(pool, req.params.code, user.industry_track_id);
    if (!lesson) return notFound(res, req);

    const sectionsCompleted = clampInt(req.body.sections_completed, 0, 0, 10000);
    const activitiesCompleted = clampInt(req.body.activities_completed, 0, 0, 10000);

    client = await pool.connect();
    await client.query('BEGIN');
    await client.query(
      `INSERT INTO lab_lesson_progress (user_id, lesson_id, sections_completed, activities_completed, last_viewed_at)
       VALUES ($1, $2, $3, $4, now())
       ON CONFLICT (user_id, lesson_id) DO UPDATE SET
         sections_completed = GREATEST(lab_lesson_progress.sections_completed, EXCLUDED.sections_completed),
         activities_completed = GREATEST(lab_lesson_progress.activities_completed, EXCLUDED.activities_completed),
         last_viewed_at = now()`,
      [user.id, lesson.id, sectionsCompleted, activitiesCompleted],
    );
    await recomputeStatus(client, user.id, lesson.id);
    await client.query('COMMIT');

    const refreshed = await pool.query(
      `SELECT sections_completed, activities_completed, assessment_best_score, status, last_viewed_at
       FROM lab_lesson_progress WHERE user_id = $1 AND lesson_id = $2`,
      [user.id, lesson.id],
    );

    return res.status(200).json({ progress: refreshed.rows[0], request_id: req.requestId });
  } catch (err) {
    if (client) await client.query('ROLLBACK').catch(() => {});
    return next(err);
  } finally {
    if (client) client.release();
  }
}

// POST /api/lab/lessons/:code/assessment  { answers: [index, ...] }
async function submitAssessment(req, res, next) {
  let client = null;
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const lesson = await findLessonForUser(pool, req.params.code, user.industry_track_id);
    if (!lesson) return notFound(res, req);

    const questions = await pool.query(
      `SELECT id, options, correct_index, explanation FROM lab_questions WHERE lesson_id = $1 ORDER BY sort_order, id`,
      [lesson.id],
    );
    if (!questions.rows.length) {
      return res.status(400).json({ error: 'This lesson has no assessment.', request_id: req.requestId });
    }

    const answers = req.body.answers;
    if (!Array.isArray(answers) || answers.length !== questions.rows.length) {
      return res.status(400).json({
        error: `answers must contain ${questions.rows.length} entries.`,
        request_id: req.requestId,
      });
    }
    for (const answer of answers) {
      if (!Number.isInteger(answer) || answer < 0) {
        return res.status(400).json({ error: 'Each answer must be a non-negative integer index.', request_id: req.requestId });
      }
    }

    const results = questions.rows.map((question, index) => {
      const optionCount = Array.isArray(question.options) ? question.options.length : 0;
      const answered = answers[index];
      return {
        question_id: question.id,
        answered: answered < optionCount ? answered : null,
        correct: answered === question.correct_index,
        correct_index: question.correct_index,
        explanation: question.explanation,
      };
    });
    const correctCount = results.filter((r) => r.correct).length;
    const score = Math.round((100 * correctCount) / questions.rows.length);
    const passed = score >= PASS_SCORE;

    client = await pool.connect();
    await client.query('BEGIN');
    await client.query(
      `INSERT INTO lab_assessment_attempts (user_id, lesson_id, score, passed) VALUES ($1, $2, $3, $4)`,
      [user.id, lesson.id, score, passed],
    );
    await client.query(
      `INSERT INTO lab_lesson_progress (user_id, lesson_id, assessment_best_score, last_viewed_at)
       VALUES ($1, $2, $3, now())
       ON CONFLICT (user_id, lesson_id) DO UPDATE SET
         assessment_best_score = GREATEST(lab_lesson_progress.assessment_best_score, EXCLUDED.assessment_best_score),
         last_viewed_at = now()`,
      [user.id, lesson.id, score],
    );
    await recomputeStatus(client, user.id, lesson.id);
    await client.query('COMMIT');

    return res.status(201).json({
      result: { score, passed, correct_count: correctCount, total: questions.rows.length },
      questions: results,
      request_id: req.requestId,
    });
  } catch (err) {
    if (client) await client.query('ROLLBACK').catch(() => {});
    return next(err);
  } finally {
    if (client) client.release();
  }
}

// POST /api/lab/activities/:id/attempt  { response, practice? }
// Grades a recall activity. A first non-practice pass awards XP (default 10);
// repeat attempts are practice and earn nothing.
async function submitActivity(req, res, next) {
  let client = null;
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const activityId = positiveIntegerParam(req.params.id, 'activity id');
    const practice = req.body.practice === true;

    const activityResult = await pool.query(
      `SELECT a.id, a.lesson_id, a.type, a.correct, a.explanation, a.xp_reward
       FROM lab_activities a
       JOIN lab_lessons l ON l.id = a.lesson_id
       WHERE a.id = $1 AND (l.track_id IS NULL OR l.track_id = $2)`,
      [activityId, user.industry_track_id],
    );
    if (!activityResult.rows.length) {
      return res.status(404).json({ error: 'Activity not found for your selected track.', request_id: req.requestId });
    }
    const activity = activityResult.rows[0];

    const passed = gradeActivity(activity.type, activity.correct, req.body.response);

    client = await pool.connect();
    await client.query('BEGIN');
    const prior = await client.query(
      `SELECT 1 FROM lab_activity_attempts WHERE user_id = $1 AND activity_id = $2 AND passed LIMIT 1`,
      [user.id, activityId],
    );
    const firstPass = passed && prior.rows.length === 0 && !practice;
    const xpEarned = firstPass ? activity.xp_reward : 0;
    if (xpEarned > 0) await awardXp(client, user.id, xpEarned);

    await client.query(
      `INSERT INTO lab_activity_attempts (user_id, activity_id, passed, xp_awarded)
       VALUES ($1, $2, $3, $4)`,
      [user.id, activityId, passed, xpEarned],
    );
    await client.query('COMMIT');

    return res.status(200).json({
      result: { correct: passed, passed, xp_earned: xpEarned, practice },
      explanation: activity.explanation,
      answer: activity.correct,
      request_id: req.requestId,
    });
  } catch (err) {
    if (client) await client.query('ROLLBACK').catch(() => {});
    if (err && err.status) {
      return res.status(err.status).json({ error: err.message, request_id: req.requestId });
    }
    return next(err);
  } finally {
    if (client) client.release();
  }
}

// ---------------------------------------------------------------------------
// Capstone assessments (module-level, scenario-based)
// ---------------------------------------------------------------------------
const CAPSTONE_GRACE_SECONDS = 30;

function shuffle(values) {
  const a = [...values];
  for (let i = a.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

async function findCapstone(executor, code, trackId) {
  const result = await executor.query(
    `SELECT id, code, title, summary, time_limit_seconds, pass_score, max_attempts,
            xp_reward, token_reward, achievement_code
     FROM lab_capstone_assessments
     WHERE code = $1 AND active = TRUE AND (track_id IS NULL OR track_id = $2)`,
    [code, trackId],
  );
  return result.rows[0] || null;
}

async function attemptsUsed(executor, userId, assessmentId) {
  const result = await executor.query(
    `SELECT COUNT(*)::int AS used FROM lab_capstone_attempts
     WHERE user_id = $1 AND assessment_id = $2 AND submitted_at IS NOT NULL`,
    [userId, assessmentId],
  );
  return result.rows[0]?.used ?? 0;
}

// GET /api/lab/assessments
async function listAssessments(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const result = await pool.query(
      `SELECT c.id, c.code, c.title, c.summary, c.time_limit_seconds, c.pass_score,
              c.max_attempts, c.xp_reward, c.token_reward,
              (SELECT COUNT(*)::int FROM lab_capstone_questions q WHERE q.assessment_id = c.id) AS question_count,
              (SELECT COUNT(*)::int FROM lab_capstone_attempts a
                WHERE a.assessment_id = c.id AND a.user_id = $1 AND a.submitted_at IS NOT NULL) AS attempts_used,
              (SELECT MAX(a.score) FROM lab_capstone_attempts a
                WHERE a.assessment_id = c.id AND a.user_id = $1 AND a.passed) AS best_score
       FROM lab_capstone_assessments c
       WHERE c.active = TRUE AND (c.track_id IS NULL OR c.track_id = $2)
       ORDER BY c.sort_order, c.id`,
      [user.id, user.industry_track_id],
    );

    const assessments = result.rows.map((row) => ({
      ...row,
      attempts_remaining: Math.max(0, row.max_attempts - row.attempts_used),
      passed: row.best_score != null,
    }));
    return res.status(200).json({ assessments, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// POST /api/lab/assessments/:code/start
// Shuffles questions (and multiple-choice options) and opens a timed attempt.
async function startAssessment(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const assessment = await findCapstone(pool, req.params.code, user.industry_track_id);
    if (!assessment) {
      return res.status(404).json({ error: 'Assessment not found for your selected track.', request_id: req.requestId });
    }

    const used = await attemptsUsed(pool, user.id, assessment.id);
    if (used >= assessment.max_attempts) {
      return res.status(409).json({
        error: 'No attempts remaining for this assessment.',
        attempts_remaining: 0,
        request_id: req.requestId,
      });
    }

    const questions = await pool.query(
      `SELECT id, type, scenario, prompt, payload, sort_order
       FROM lab_capstone_questions WHERE assessment_id = $1 ORDER BY sort_order, id`,
      [assessment.id],
    );
    if (!questions.rows.length) {
      return res.status(400).json({ error: 'This assessment has no questions yet.', request_id: req.requestId });
    }

    const byId = new Map(questions.rows.map((q) => [String(q.id), q]));
    const order = shuffle(questions.rows.map((q) => q.id));
    const presentation = { order, options: {} };

    const presented = order.map((qid) => {
      const q = byId.get(String(qid));
      let payload = q.payload || {};
      if (q.type === 'multiple_choice' && Array.isArray(payload.options)) {
        const perm = shuffle(payload.options.map((_, i) => i));
        presentation.options[qid] = perm;
        payload = { ...payload, options: perm.map((i) => payload.options[i]) };
      }
      return { id: q.id, type: q.type, scenario: q.scenario, prompt: q.prompt, payload, sort_order: q.sort_order };
    });

    const attempt = await pool.query(
      `INSERT INTO lab_capstone_attempts (user_id, assessment_id, presentation)
       VALUES ($1, $2, $3)
       RETURNING id, started_at`,
      [user.id, assessment.id, JSON.stringify(presentation)],
    );

    const startedAt = new Date(attempt.rows[0].started_at).getTime();
    const expiresAt = new Date(startedAt + assessment.time_limit_seconds * 1000).toISOString();

    return res.status(201).json({
      attempt_id: attempt.rows[0].id,
      started_at: new Date(startedAt).toISOString(),
      expires_at: expiresAt,
      time_limit_seconds: assessment.time_limit_seconds,
      pass_score: assessment.pass_score,
      attempts_remaining: assessment.max_attempts - used,
      questions: presented,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// POST /api/lab/assessments/:code/submit  { attempt_id, answers: { "<qid>": response } }
async function submitCapstone(req, res, next) {
  let client = null;
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const attemptId = positiveIntegerParam(req.body.attempt_id, 'attempt_id');
    const answers = req.body.answers;
    if (!answers || typeof answers !== 'object' || Array.isArray(answers)) {
      return res.status(400).json({ error: 'answers must be an object keyed by question id.', request_id: req.requestId });
    }

    const assessment = await findCapstone(pool, req.params.code, user.industry_track_id);
    if (!assessment) {
      return res.status(404).json({ error: 'Assessment not found for your selected track.', request_id: req.requestId });
    }

    const attemptResult = await pool.query(
      `SELECT id, presentation, started_at, submitted_at
       FROM lab_capstone_attempts WHERE id = $1 AND user_id = $2 AND assessment_id = $3`,
      [attemptId, user.id, assessment.id],
    );
    if (!attemptResult.rows.length) {
      return res.status(404).json({ error: 'Attempt not found.', request_id: req.requestId });
    }
    const attempt = attemptResult.rows[0];
    if (attempt.submitted_at) {
      return res.status(409).json({ error: 'This attempt has already been submitted.', request_id: req.requestId });
    }

    const questions = await pool.query(
      `SELECT id, type, correct, explanation, points
       FROM lab_capstone_questions WHERE assessment_id = $1 ORDER BY sort_order, id`,
      [assessment.id],
    );

    const presentation = attempt.presentation || { options: {} };
    let earned = 0;
    let total = 0;
    const results = questions.rows.map((question) => {
      total += question.points;
      let response = answers[String(question.id)];
      // Map a presented option index back to the original before grading.
      if (question.type === 'multiple_choice' && presentation.options && presentation.options[question.id]) {
        const perm = presentation.options[question.id];
        const presented = Number(response);
        if (Number.isInteger(presented) && presented >= 0 && presented < perm.length) {
          response = perm[presented];
        }
      }
      const correct = gradeActivity(question.type, question.correct, response);
      if (correct) earned += question.points;
      return { question_id: question.id, correct, answer: question.correct, explanation: question.explanation };
    });

    const score = total > 0 ? Math.round((100 * earned) / total) : 0;
    const elapsedMs = Date.now() - new Date(attempt.started_at).getTime();
    const timedOut = elapsedMs > (assessment.time_limit_seconds + CAPSTONE_GRACE_SECONDS) * 1000;
    const passed = !timedOut && score >= assessment.pass_score;

    client = await pool.connect();
    await client.query('BEGIN');

    const prior = await client.query(
      `SELECT 1 FROM lab_capstone_attempts WHERE user_id = $1 AND assessment_id = $2 AND passed LIMIT 1`,
      [user.id, assessment.id],
    );
    const firstPass = passed && prior.rows.length === 0;

    let xpEarned = 0;
    let tokensEarned = 0;
    let achievement = null;
    if (firstPass) {
      if (assessment.xp_reward > 0) {
        await awardXp(client, user.id, assessment.xp_reward);
        xpEarned = assessment.xp_reward;
      }
      if (assessment.token_reward > 0) {
        await grantTokens(client, user.id, [
          { delta: assessment.token_reward, reason: 'capstone', ref: `capstone:${assessment.code}` },
        ]);
        tokensEarned = assessment.token_reward;
      }
      if (assessment.achievement_code) {
        const inserted = await client.query(
          `INSERT INTO user_achievements (user_id, achievement_id)
           SELECT $1, id FROM achievements WHERE code = $2
           ON CONFLICT DO NOTHING RETURNING achievement_id`,
          [user.id, assessment.achievement_code],
        );
        if (inserted.rows.length) achievement = assessment.achievement_code;
      }
    }

    await client.query(
      `UPDATE lab_capstone_attempts
       SET answers = $1, score = $2, passed = $3, timed_out = $4, submitted_at = now()
       WHERE id = $5`,
      [JSON.stringify(answers), score, passed, timedOut, attemptId],
    );

    const usedAfter = await attemptsUsed(client, user.id, assessment.id);
    await refreshReadiness(client, user.id, user.industry_track_id);
    await client.query('COMMIT');

    return res.status(200).json({
      result: {
        score,
        passed,
        timed_out: timedOut,
        earned_points: earned,
        total_points: total,
        attempts_remaining: Math.max(0, assessment.max_attempts - usedAfter),
      },
      results,
      xp_earned: xpEarned,
      tokens_earned: tokensEarned,
      achievement,
      request_id: req.requestId,
    });
  } catch (err) {
    if (client) await client.query('ROLLBACK').catch(() => {});
    if (err && err.status) {
      return res.status(err.status).json({ error: err.message, request_id: req.requestId });
    }
    return next(err);
  } finally {
    if (client) client.release();
  }
}

// GET /api/lab/sources — the "where our material comes from" catalogue.
async function listSources(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT id, title, author, publisher, edition, source_url, license, license_url,
              industry, checked_on, notes
       FROM content_sources
       ORDER BY industry, title`,
    );
    return res.status(200).json({ sources: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/lab/sources/:id
async function getSource(req, res, next) {
  try {
    const id = String(req.params.id || '');
    if (!UUID_RE.test(id)) {
      return res.status(400).json({ error: 'Invalid source id.', request_id: req.requestId });
    }

    const source = await pool.query(`SELECT * FROM content_sources WHERE id = $1`, [id]);
    if (!source.rows.length) {
      return res.status(404).json({ error: 'Source not found.', request_id: req.requestId });
    }

    const lessons = await pool.query(
      `SELECT l.id, l.code, l.title, ls.use_type, ls.changes_made
       FROM lesson_sources ls
       JOIN lab_lessons l ON l.id = ls.lesson_id
       WHERE ls.source_id = $1
       ORDER BY l.sort_order, l.id`,
      [id],
    );

    return res.status(200).json({ source: source.rows[0], lessons: lessons.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/lab/library — sources grouped by industry.
async function getLibrary(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT id, title, author, publisher, edition, source_url, license, license_url,
              industry, checked_on, notes
       FROM content_sources
       ORDER BY industry, title`,
    );

    const groups = [];
    const byIndustry = new Map();
    for (const source of result.rows) {
      if (!byIndustry.has(source.industry)) {
        const group = { industry: source.industry, sources: [] };
        byIndustry.set(source.industry, group);
        groups.push(group);
      }
      byIndustry.get(source.industry).sources.push(source);
    }

    return res.status(200).json({ groups, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// POST /api/lab/coach  { lesson_code, messages }  (streams by default)
async function coach(req, res, next) {
  try {
    const lessonCode = optionalString(req.body.lesson_code, 'lesson_code', 120);
    const messages = validateMessages(req.body.messages);

    const user = await requireUser(res, req);
    if (!user) return undefined;

    let lesson = null;
    if (lessonCode) {
      lesson = await findLessonForUser(pool, lessonCode, user.industry_track_id);
      if (!lesson) return notFound(res, req);
    } else {
      lesson = { title: 'AI Lab', summary: 'General AI literacy coaching.' };
    }

    const wantsStream = req.query.stream === '1' || req.body.stream === true;
    if (!wantsStream) {
      const reply = await getCoachReply({ lesson, messages });
      return res.status(200).json({ reply, request_id: req.requestId });
    }

    openStream(res);
    try {
      for await (const chunk of streamCoachReply({ lesson, messages })) {
        if (chunk.delta) sendEvent(res, { delta: chunk.delta });
      }
      endStream(res);
    } catch (error) {
      sendEvent(res, { error: error.message });
      endStream(res);
    }
    return undefined;
  } catch (err) {
    return handleAiError(err, req, res, next);
  }
}

module.exports = {
  listLessons,
  getNextLesson,
  getLesson,
  recordProgress,
  submitAssessment,
  submitActivity,
  listAssessments,
  startAssessment,
  submitCapstone,
  listSources,
  getSource,
  getLibrary,
  coach,
};
