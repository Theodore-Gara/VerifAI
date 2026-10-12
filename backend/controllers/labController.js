const pool = require('../db/pool');
const { optionalString, clampInt } = require('../middleware/validate');
const { findUserByFirebaseUid } = require('../db/users');
const { getCoachReply, streamCoachReply } = require('../services/nvidiaAssistant');
const { validateMessages } = require('./assistantController');
const { handleAiError } = require('../middleware/aiError');
const { openStream, sendEvent, endStream } = require('../middleware/sse');

const PASS_SCORE = 60;

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
    `SELECT id, code, title, summary, estimated_minutes, level
     FROM lab_lessons
     WHERE code = $1 AND (track_id IS NULL OR track_id = $2)`,
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

// GET /api/lab/lessons
async function listLessons(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const result = await pool.query(
      `SELECT l.id, l.code, l.title, l.summary, l.estimated_minutes, l.level, l.sort_order,
              (SELECT COUNT(*)::int FROM lab_lesson_sections s WHERE s.lesson_id = l.id) AS sections_count,
              (SELECT COUNT(*)::int FROM lab_activities a WHERE a.lesson_id = l.id) AS activities_count,
              (SELECT COUNT(*)::int FROM lab_questions q WHERE q.lesson_id = l.id) AS questions_count,
              COALESCE(p.sections_completed, 0)::int AS sections_completed,
              COALESCE(p.activities_completed, 0)::int AS activities_completed,
              COALESCE(p.assessment_best_score, 0)::int AS assessment_best_score,
              COALESCE(p.status, 'not_started') AS status
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

// GET /api/lab/lessons/:code
async function getLesson(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const lesson = await findLessonForUser(pool, req.params.code, user.industry_track_id);
    if (!lesson) return notFound(res, req);

    const [sections, activities, questions, progress] = await Promise.all([
      pool.query(
        `SELECT id, heading, body, sort_order FROM lab_lesson_sections WHERE lesson_id = $1 ORDER BY sort_order, id`,
        [lesson.id],
      ),
      pool.query(
        `SELECT id, kind, title, instructions, task_id, sort_order FROM lab_activities WHERE lesson_id = $1 ORDER BY sort_order, id`,
        [lesson.id],
      ),
      // correct_index and explanation are withheld until the assessment is submitted.
      pool.query(
        `SELECT id, prompt, options, sort_order FROM lab_questions WHERE lesson_id = $1 ORDER BY sort_order, id`,
        [lesson.id],
      ),
      pool.query(
        `SELECT sections_completed, activities_completed, assessment_best_score, status, updated_at
         FROM lab_lesson_progress WHERE user_id = $1 AND lesson_id = $2`,
        [user.id, lesson.id],
      ),
    ]);

    return res.status(200).json({
      lesson: {
        ...lesson,
        sections: sections.rows,
        activities: activities.rows,
        questions: questions.rows,
        progress: progress.rows[0] || {
          sections_completed: 0,
          activities_completed: 0,
          assessment_best_score: 0,
          status: 'not_started',
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
    const result = await client.query(
      `INSERT INTO lab_lesson_progress (user_id, lesson_id, sections_completed, activities_completed)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id, lesson_id) DO UPDATE SET
         sections_completed = GREATEST(lab_lesson_progress.sections_completed, EXCLUDED.sections_completed),
         activities_completed = GREATEST(lab_lesson_progress.activities_completed, EXCLUDED.activities_completed)
       RETURNING sections_completed, activities_completed, assessment_best_score, status, updated_at`,
      [user.id, lesson.id, sectionsCompleted, activitiesCompleted],
    );
    await recomputeStatus(client, user.id, lesson.id);
    await client.query('COMMIT');

    const refreshed = await pool.query(
      `SELECT sections_completed, activities_completed, assessment_best_score, status, updated_at
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
      const correct = answered === question.correct_index;
      return {
        question_id: question.id,
        answered: answered < optionCount ? answered : null,
        correct,
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
      `INSERT INTO lab_lesson_progress (user_id, lesson_id, assessment_best_score)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, lesson_id) DO UPDATE SET
         assessment_best_score = GREATEST(lab_lesson_progress.assessment_best_score, EXCLUDED.assessment_best_score),
         updated_at = CURRENT_TIMESTAMP`,
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
  getLesson,
  recordProgress,
  submitAssessment,
  coach,
};
