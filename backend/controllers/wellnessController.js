const pool = require('../db/pool');
const { clampInt } = require('../middleware/validate');
const { findUserByFirebaseUid } = require('../db/users');

const MOODS = new Set(['Great', 'Calm', 'Okay', 'Stressed', 'Tired', 'Low']);
const ACTIVITIES = new Set(['breathing', 'journal', 'step_outside']);
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const MAX_JOURNAL_CHARS = 1200;

async function requireUser(res, req) {
  const user = await findUserByFirebaseUid(pool, req.firebaseUser.uid);
  if (!user) {
    res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    return null;
  }
  return user;
}

// undefined when absent, null when malformed. The client sends its own local
// date so a check-in lands on the day the learner saw it.
function parseDate(value) {
  if (value === undefined || value === null || value === '') return undefined;
  return DATE_RE.test(String(value)) ? String(value) : null;
}

function badRequest(res, req, message) {
  return res.status(400).json({ error: message, request_id: req.requestId });
}

// GET /api/wellness/mood?limit=30
async function listMood(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;
    const limit = clampInt(req.query.limit, 30, 1, 90);

    const result = await pool.query(
      `SELECT check_in_date::text AS date, mood, updated_at
       FROM wellness_mood_checkins
       WHERE user_id = $1
       ORDER BY check_in_date DESC
       LIMIT $2`,
      [user.id, limit],
    );

    return res.status(200).json({ checkins: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// PUT /api/wellness/mood  body { mood, date? } — one check-in per day, re-saving updates it.
async function saveMood(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const mood = typeof req.body?.mood === 'string' ? req.body.mood.trim() : '';
    if (!MOODS.has(mood)) {
      return badRequest(res, req, `mood must be one of: ${[...MOODS].join(', ')}.`);
    }
    const date = parseDate(req.body?.date);
    if (date === null) return badRequest(res, req, 'date must be YYYY-MM-DD.');

    const result = await pool.query(
      `INSERT INTO wellness_mood_checkins (user_id, check_in_date, mood)
       VALUES ($1, COALESCE($2::date, CURRENT_DATE), $3)
       ON CONFLICT (user_id, check_in_date)
       DO UPDATE SET mood = EXCLUDED.mood
       RETURNING check_in_date::text AS date, mood, updated_at`,
      [user.id, date ?? null, mood],
    );

    return res.status(200).json({ checkin: result.rows[0], request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/wellness/journal?limit=30
async function listJournal(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;
    const limit = clampInt(req.query.limit, 30, 1, 90);

    const result = await pool.query(
      `SELECT entry_date::text AS date, content, updated_at
       FROM wellness_journal_entries
       WHERE user_id = $1
       ORDER BY entry_date DESC
       LIMIT $2`,
      [user.id, limit],
    );

    return res.status(200).json({ entries: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// PUT /api/wellness/journal  body { content, date? } — one entry per day.
async function saveJournal(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const content = typeof req.body?.content === 'string' ? req.body.content.trim() : '';
    if (!content) return badRequest(res, req, 'content is required.');
    if (content.length > MAX_JOURNAL_CHARS) {
      return badRequest(res, req, `content must be ${MAX_JOURNAL_CHARS} characters or fewer.`);
    }
    const date = parseDate(req.body?.date);
    if (date === null) return badRequest(res, req, 'date must be YYYY-MM-DD.');

    const result = await pool.query(
      `INSERT INTO wellness_journal_entries (user_id, entry_date, content)
       VALUES ($1, COALESCE($2::date, CURRENT_DATE), $3)
       ON CONFLICT (user_id, entry_date)
       DO UPDATE SET content = EXCLUDED.content
       RETURNING entry_date::text AS date, content, updated_at`,
      [user.id, date ?? null, content],
    );

    return res.status(200).json({ entry: result.rows[0], request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/wellness/activities?days=7 — self-care completions in the window.
async function listActivities(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;
    const days = clampInt(req.query.days, 7, 1, 30);

    const result = await pool.query(
      `SELECT activity, COUNT(*)::int AS count, MAX(completed_at) AS last_at
       FROM wellness_activities
       WHERE user_id = $1 AND completed_at >= now() - ($2::int * interval '1 day')
       GROUP BY activity
       ORDER BY activity`,
      [user.id, days],
    );

    const total = result.rows.reduce((sum, row) => sum + row.count, 0);
    return res.status(200).json({ days, total, activities: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// POST /api/wellness/activities  body { activity }
async function logActivity(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const activity = typeof req.body?.activity === 'string' ? req.body.activity.trim() : '';
    if (!ACTIVITIES.has(activity)) {
      return badRequest(res, req, `activity must be one of: ${[...ACTIVITIES].join(', ')}.`);
    }

    const result = await pool.query(
      `INSERT INTO wellness_activities (user_id, activity)
       VALUES ($1, $2)
       RETURNING id, activity, completed_at`,
      [user.id, activity],
    );

    return res.status(201).json({ activity: result.rows[0], request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listMood,
  saveMood,
  listJournal,
  saveJournal,
  listActivities,
  logActivity,
  MOODS,
  ACTIVITIES,
};
