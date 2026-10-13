const pool = require('../db/pool');
const { optionalString, clampInt } = require('../middleware/validate');
const { findUserByFirebaseUid } = require('../db/users');
const { getCoachReply, streamCoachReply } = require('../services/nvidiaAssistant');
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
        `SELECT id, kind, title, instructions, task_id, sort_order FROM lab_activities WHERE lesson_id = $1 ORDER BY sort_order, id`,
        [lesson.id],
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
  listSources,
  getSource,
  getLibrary,
  coach,
};
