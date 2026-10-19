const pool = require('../db/pool');

const FEATURES = new Set(['verification', 'judgement', 'risk_governance', 'prompt_design']);
const DIFFICULTIES = new Set(['easy', 'medium', 'hard']);
const USER_STATUSES = new Set(['active', 'suspended', 'banned']);
const OPTION_KINDS = {
  verification: ['answer'],
  judgement: ['decision', 'reason'],
  risk_governance: ['decision', 'reason'],
};

// ---------------------------------------------------------------------------
// GET /api/admin/overview — counts used by the dashboard's stat cards.
// ---------------------------------------------------------------------------
async function getOverview(req, res, next) {
  try {
    const [taskCounts, users, attempts, tracks] = await Promise.all([
      pool.query(
        `SELECT feature, COUNT(*)::int AS count FROM tasks GROUP BY feature`
      ),
      pool.query(`SELECT COUNT(*)::int AS count FROM users`),
      pool.query(`SELECT COUNT(*)::int AS count, COALESCE(AVG(score), 0)::int AS avg_score FROM task_attempts`),
      pool.query(
        `SELECT t.id, t.name, COUNT(ta.id)::int AS task_count
         FROM industry_tracks t
         LEFT JOIN tasks ta ON ta.track_id = t.id
         GROUP BY t.id, t.name ORDER BY t.id`
      ),
    ]);

    const byFeature = {};
    for (const row of taskCounts.rows) byFeature[row.feature] = row.count;

    return res.status(200).json({
      tasks_total: Object.values(byFeature).reduce((a, b) => a + b, 0),
      tasks_by_feature: byFeature,
      users_total: users.rows[0].count,
      attempts_total: attempts.rows[0].count,
      avg_attempt_score: attempts.rows[0].avg_score,
      tracks: tracks.rows,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// GET /api/admin/tasks — every task with its per-feature content summary.
// Filters: ?feature=&track_id=
// ---------------------------------------------------------------------------
async function listTasks(req, res, next) {
  try {
    const params = [];
    const where = [];

    const feature = req.query.feature == null ? null : String(req.query.feature).toLowerCase().trim();
    if (feature != null) {
      if (!FEATURES.has(feature)) {
        return res.status(400).json({ error: 'Unknown feature.', request_id: req.requestId });
      }
      params.push(feature);
      where.push(`t.feature = $${params.length}`);
    }

    if (req.query.track_id != null) {
      const trackId = Number.parseInt(req.query.track_id, 10);
      if (!Number.isInteger(trackId)) {
        return res.status(400).json({ error: 'track_id must be an integer.', request_id: req.requestId });
      }
      params.push(trackId);
      where.push(`t.track_id = $${params.length}`);
    }

    const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const result = await pool.query(
      `SELECT t.id, t.code, t.feature, t.track_id, tr.name AS track_name, t.created_at,
         t.approval, t.approved_by,
         v.title, v.scenario, v.difficulty, v.format,
         j.title AS j_title, j.scenario AS j_scenario,
         r.title AS r_title, r.scenario AS r_scenario,
         (SELECT COUNT(*)::int FROM task_options o WHERE o.task_id = t.id) AS option_count,
         (SELECT COUNT(*)::int FROM task_attempts ta WHERE ta.task_id = t.id) AS attempt_count
       FROM tasks t
       JOIN industry_tracks tr ON tr.id = t.track_id
       LEFT JOIN verification_tasks v ON v.task_id = t.id
       LEFT JOIN judgement_tasks j ON j.task_id = t.id
       LEFT JOIN risk_governance_tasks r ON r.task_id = t.id
       ${whereSql}
       ORDER BY t.id ASC
       LIMIT 500`,
      params
    );

    const tasks = result.rows.map((row) => {
      const task = {
        id: row.id,
        code: row.code,
        feature: row.feature,
        track_id: row.track_id,
        track_name: row.track_name,
        created_at: row.created_at,
        approval: row.approval,
        approved_by: row.approved_by,
        option_count: row.option_count,
        attempt_count: row.attempt_count,
      };
      if (row.feature === 'verification') {
        task.title = row.title;
        task.scenario = row.scenario;
        task.difficulty = row.difficulty;
        task.format = row.format;
      } else {
        task.title = row.feature === 'judgement' ? row.j_title : row.r_title;
        task.scenario = row.feature === 'judgement' ? row.j_scenario : row.r_scenario;
      }
      return task;
    });

    return res.status(200).json({ tasks, total: tasks.length, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// Validation helpers
// ---------------------------------------------------------------------------

function fail(message) {
  const err = new Error(message);
  err.status = 400;
  throw err;
}

function reqString(value, field, max = 20000) {
  const s = value == null ? '' : String(value).trim();
  if (!s) fail(`${field} is required.`);
  if (s.length > max) fail(`${field} must be ${max} characters or fewer.`);
  return s;
}

function reqScore(value, field) {
  const n = Number(value);
  if (!Number.isInteger(n) || n < 0 || n > 100) fail(`${field} must be an integer between 0 and 100.`);
  return n;
}

function parseOptions(raw, kinds, field) {
  const list = Array.isArray(raw) ? raw : [];
  if (!list.length) fail(`At least one ${field} entry is required.`);
  return list.map((item, index) => {
    if (!item || typeof item !== 'object') fail(`${field}[${index}] must be an object.`);
    const kind = item.kind == null ? kinds[0] : String(item.kind).toLowerCase();
    if (!kinds.includes(kind)) fail(`${field}[${index}].kind must be one of: ${kinds.join(', ')}.`);
    return {
      kind,
      label: reqString(item.label, `${field}[${index}].label`, 2000),
      score: reqScore(item.score, `${field}[${index}].score`),
    };
  });
}

function parseLineTextFields(body) {
  const aiOutputLines = Array.isArray(body.ai_output_lines)
    ? body.ai_output_lines.map((line, i) => reqString(line, `ai_output_lines[${i}]`, 2000))
    : null;
  if (!aiOutputLines || aiOutputLines.length < 2) {
    fail('ai_output_lines must be an array of at least 2 lines.');
  }
  const flawLines = Array.isArray(body.flaw_lines) ? body.flaw_lines.map(Number) : [];
  if (!flawLines.length || flawLines.some((n) => !Number.isInteger(n) || n < 1 || n > aiOutputLines.length)) {
    fail('flaw_lines must be integers between 1 and the number of ai_output_lines.');
  }
  const keywords = (field) => {
    const list = Array.isArray(body[field]) ? body[field].map((k) => String(k).trim()).filter(Boolean) : [];
    if (!list.length) fail(`${field} must be a non-empty array of keywords.`);
    return list;
  };
  return {
    ai_output_lines: aiOutputLines,
    flaw_lines: [...new Set(flawLines)].sort((a, b) => a - b),
    fix_keywords: keywords('fix_keywords'),
    reason_keywords: keywords('reason_keywords'),
  };
}

// ---------------------------------------------------------------------------
// POST /api/admin/tasks — create a task with its per-feature content.
// Body shape depends on `feature`:
//   verification (choice):      title, scenario, embedded_flaw, expected_answer,
//                               feedback, difficulty, options: [{label, score}]
//   verification (line_text):   title, scenario, embedded_flaw, expected_answer,
//                               feedback, difficulty, ai_output_lines, flaw_lines,
//                               fix_keywords, reason_keywords
//   judgement / risk_governance: title, scenario, feedback,
//                               decisions: [{label, score}], reasons: [{label, score}]
// ---------------------------------------------------------------------------
async function createTask(req, res, next) {
  const client = await pool.connect();
  try {
    const body = req.body || {};
    const feature = String(body.feature || '').toLowerCase().trim();
    if (!FEATURES.has(feature)) fail('feature must be one of: verification, judgement, risk_governance, prompt_design.');
    if (feature === 'prompt_design') fail('Prompt Design tasks are not supported yet.');

    const trackId = Number.parseInt(body.track_id, 10);
    if (!Number.isInteger(trackId)) fail('track_id must be an integer.');
    const track = await client.query('SELECT id FROM industry_tracks WHERE id = $1', [trackId]);
    if (!track.rows.length) fail(`Track ${trackId} does not exist.`);

    const title = reqString(body.title, 'title', 255);
    const scenario = reqString(body.scenario, 'scenario');
    // New tasks always start as drafts awaiting moderator approval; publishing
    // happens through the approval queue, never at creation time.
    const published = false;

    await client.query('BEGIN');

    // Stable, unique code derived from the slug + timestamp.
    const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 60) || 'task';
    const code = `admin-${slug}-${Date.now()}`;
    const taskResult = await client.query(
      `INSERT INTO tasks (code, feature, track_id, published) VALUES ($1, $2, $3, $4) RETURNING id, code`,
      [code, feature, trackId, published]
    );
    const taskId = taskResult.rows[0].id;

    if (feature === 'verification') {
      const format = (body.format == null ? 'choice' : String(body.format).toLowerCase());
      if (!['choice', 'line_text'].includes(format)) fail('verification format must be choice or line_text.');
      const expectedAnswer = reqString(body.expected_answer, 'expected_answer');
      const shared = {
        title,
        scenario,
        embedded_flaw: reqString(body.embedded_flaw, 'embedded_flaw'),
        expected_answer: expectedAnswer,
        feedback: reqString(body.feedback, 'feedback'),
        difficulty: String(body.difficulty || 'medium').toLowerCase(),
      };
      if (!DIFFICULTIES.has(shared.difficulty)) fail('difficulty must be easy, medium or hard.');

      if (format === 'line_text') {
        const lineFields = parseLineTextFields(body);
        await client.query(
          `INSERT INTO verification_tasks
             (task_id, format, title, scenario, embedded_flaw, expected_answer, feedback, difficulty,
              ai_output_lines, flaw_lines, fix_keywords, reason_keywords)
           VALUES ($1, 'line_text', $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
          [taskId, shared.title, shared.scenario, shared.embedded_flaw, shared.expected_answer,
            shared.feedback, shared.difficulty, lineFields.ai_output_lines, lineFields.flaw_lines,
            lineFields.fix_keywords, lineFields.reason_keywords]
        );
      } else {
        const options = parseOptions(body.options, OPTION_KINDS.verification, 'options');
        if (!options.some((o) => o.score >= 100)) fail('At least one option must score 100 (the correct answer).');
        await client.query(
          `INSERT INTO verification_tasks
             (task_id, format, title, scenario, embedded_flaw, expected_answer, feedback, difficulty)
           VALUES ($1, 'choice', $2, $3, $4, $5, $6, $7)`,
          [taskId, shared.title, shared.scenario, shared.embedded_flaw, shared.expected_answer,
            shared.feedback, shared.difficulty]
        );
        for (let i = 0; i < options.length; i += 1) {
          await client.query(
            `INSERT INTO task_options (task_id, kind, label, score, sort_order) VALUES ($1, 'answer', $2, $3, $4)`,
            [taskId, options[i].label, options[i].score, i]
          );
        }
      }
    } else {
      // judgement / risk_governance: decision + reason options.
      const feedback = reqString(body.feedback, 'feedback');
      const table = feature === 'judgement' ? 'judgement_tasks' : 'risk_governance_tasks';
      await client.query(
        `INSERT INTO ${table} (task_id, title, scenario, feedback) VALUES ($1, $2, $3, $4)`,
        [taskId, title, scenario, feedback]
      );
      const decisions = parseOptions(body.decisions, ['decision'], 'decisions');
      const reasons = parseOptions(body.reasons, ['reason'], 'reasons');
      let sort = 0;
      for (const option of [...decisions, ...reasons]) {
        await client.query(
          `INSERT INTO task_options (task_id, kind, label, score, sort_order) VALUES ($1, $2, $3, $4, $5)`,
          [taskId, option.kind, option.label, option.score, sort]
        );
        sort += 1;
      }
    }

    await client.query('COMMIT');

    await logModeration(req.firebaseUser, { action: 'task_create', reason: `Task #${taskId} (${feature}) created${published ? '' : ' as draft'}: ${title}` });

    return res.status(201).json({
      task: { id: taskId, code, feature, track_id: trackId, title, published },
      request_id: req.requestId,
    });
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    if (!err.status) return next(err);
    return res.status(err.status).json({ error: err.message, request_id: req.requestId });
  } finally {
    client.release();
  }
}

// ---------------------------------------------------------------------------
// DELETE /api/admin/tasks/:id — removes the task and (via ON DELETE CASCADE)
// its content row, options and recorded attempts.
// ---------------------------------------------------------------------------
async function deleteTask(req, res, next) {
  const client = await pool.connect();
  try {
    const taskId = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(taskId)) {
      return res.status(400).json({ error: 'Task id must be an integer.', request_id: req.requestId });
    }
    await client.query('BEGIN');
    const result = await client.query('DELETE FROM tasks WHERE id = $1 RETURNING id, code', [taskId]);
    if (!result.rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Task not found.', request_id: req.requestId });
    }
    await client.query('COMMIT');

    await logModeration(req.firebaseUser, { action: 'task_delete', reason: `Task #${result.rows[0].id} (${result.rows[0].code}) deleted` });

    return res.status(200).json({ deleted: result.rows[0], request_id: req.requestId });
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    return next(err);
  } finally {
    client.release();
  }
}

// ---------------------------------------------------------------------------
// Moderation audit trail — every admin action lands here.
// ---------------------------------------------------------------------------
async function logModeration(firebaseUser, { action, targetUserId, targetEmail, reason }) {
  try {
    await pool.query(
      `INSERT INTO moderation_events (admin_email, target_user_id, target_email, action, reason)
       VALUES ($1, $2, $3, $4, $5)`,
      [String(firebaseUser.email || firebaseUser.uid), targetUserId || null, targetEmail || null, action, reason || null]
    );
  } catch (err) {
    // The audit trail must never break the action it records.
    console.error('Failed to record moderation event:', err.message);
  }
}

// ---------------------------------------------------------------------------
// GET /api/admin/users — searchable, filterable user list with progress.
// Filters: ?q=(email/name substring) &status=&track_id=&limit=&offset=
// ---------------------------------------------------------------------------
async function listUsers(req, res, next) {
  try {
    const params = [];
    const where = [];

    if (req.query.q != null) {
      const q = String(req.query.q).trim();
      if (q) {
        params.push(`%${q.toLowerCase()}%`);
        where.push(`(LOWER(u.email) LIKE $${params.length} OR LOWER(COALESCE(u.display_name, '')) LIKE $${params.length})`);
      }
    }
    const status = req.query.status == null ? null : String(req.query.status).toLowerCase().trim();
    if (status) {
      if (!USER_STATUSES.has(status)) {
        return res.status(400).json({ error: 'Unknown status.', request_id: req.requestId });
      }
      params.push(status);
      where.push(`u.status = $${params.length}`);
    }
    if (req.query.track_id != null) {
      const trackId = Number.parseInt(req.query.track_id, 10);
      if (!Number.isInteger(trackId)) {
        return res.status(400).json({ error: 'track_id must be an integer.', request_id: req.requestId });
      }
      params.push(trackId);
      where.push(`u.industry_track_id = $${params.length}`);
    }

    const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 50, 1), 200);
    const offset = Math.max(Number.parseInt(req.query.offset, 10) || 0, 0);

    const countResult = await pool.query(
      `SELECT COUNT(*)::int AS total FROM users u ${whereSql}`,
      params
    );

    params.push(limit, offset);
    const result = await pool.query(
      `SELECT u.id, u.email, u.display_name, u.status, u.status_reason, u.status_updated_at,
              u.industry_track_id, tr.name AS track_name, u.created_at,
              a.role AS admin_role,
              p.xp, p.level, p.streak, p.readiness_score, p.tier,
              (SELECT COUNT(*)::int FROM task_attempts ta WHERE ta.user_id = u.id AND ta.practice = FALSE) AS attempts,
              (SELECT COUNT(*)::int FROM task_attempts ta WHERE ta.user_id = u.id AND ta.practice = FALSE AND ta.passed) AS passed
       FROM users u
       LEFT JOIN industry_tracks tr ON tr.id = u.industry_track_id
       LEFT JOIN user_progress p ON p.user_id = u.id
       LEFT JOIN admin_accounts a ON lower(a.email) = lower(u.email)
       ${whereSql}
       ORDER BY u.created_at DESC, u.id DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    return res.status(200).json({
      users: result.rows,
      total: countResult.rows[0].total,
      limit,
      offset,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// GET /api/admin/users/:id — full profile for the user detail drawer.
// ---------------------------------------------------------------------------
async function getUser(req, res, next) {
  try {
    const userId = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(userId)) {
      return res.status(400).json({ error: 'User id must be an integer.', request_id: req.requestId });
    }

    const userResult = await pool.query(
      `SELECT u.*, tr.name AS track_name,
              a.role AS admin_role,
              p.xp, p.level, p.streak, p.tokens,
              p.readiness_score, p.tier, p.tier_tasks_completed, p.last_activity_date
       FROM users u
       LEFT JOIN industry_tracks tr ON tr.id = u.industry_track_id
       LEFT JOIN user_progress p ON p.user_id = u.id
       LEFT JOIN admin_accounts a ON lower(a.email) = lower(u.email)
       WHERE u.id = $1`,
      [userId]
    );
    if (!userResult.rows.length) {
      return res.status(404).json({ error: 'User not found.', request_id: req.requestId });
    }

    const [skills, attempts, achievements, moderation] = await Promise.all([
      pool.query(
        `SELECT dimension, score, attempts_count, updated_at FROM skill_scores WHERE user_id = $1 ORDER BY dimension`,
        [userId]
      ),
      pool.query(
        `SELECT ta.id, ta.task_id, ta.task_title, t.feature, ta.score, ta.passed, ta.practice,
                ta.xp_earned, ta.submitted_at
         FROM task_attempts ta
         LEFT JOIN tasks t ON t.id = ta.task_id
         WHERE ta.user_id = $1
         ORDER BY ta.submitted_at DESC, ta.id DESC LIMIT 25`,
        [userId]
      ),
      pool.query(
        `SELECT a.code, a.name, ua.earned_at
         FROM user_achievements ua JOIN achievements a ON a.id = ua.achievement_id
         WHERE ua.user_id = $1 ORDER BY ua.earned_at DESC`,
        [userId]
      ),
      pool.query(
        `SELECT action, reason, admin_email, created_at FROM moderation_events
         WHERE target_user_id = $1 ORDER BY created_at DESC LIMIT 20`,
        [userId]
      ),
    ]);

    return res.status(200).json({
      user: userResult.rows[0],
      skills: skills.rows,
      attempts: attempts.rows,
      achievements: achievements.rows,
      moderation: moderation.rows,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// POST /api/admin/users/:id/status — suspend, ban or reactivate an account.
// Body: { action: 'suspend' | 'ban' | 'activate', reason?: string }
// ---------------------------------------------------------------------------
async function setUserStatus(req, res, next) {
  try {
    const userId = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(userId)) {
      return res.status(400).json({ error: 'User id must be an integer.', request_id: req.requestId });
    }
    const body = req.body || {};
    const action = String(body.action || '').toLowerCase().trim();
    if (!['suspend', 'ban', 'activate'].includes(action)) {
      return res.status(400).json({ error: "action must be 'suspend', 'ban' or 'activate'.", request_id: req.requestId });
    }
    const status = action === 'activate' ? 'active' : action;
    const reason = body.reason == null ? null : String(body.reason).trim().slice(0, 2000) || null;

    // Admins must never be able to lock themselves out of the panel.
    const adminUid = req.firebaseUser.uid;
    if (adminUid) {
      const self = await pool.query(`SELECT id FROM users WHERE firebase_uid = $1`, [adminUid]);
      if (self.rows[0]?.id === userId) {
        return res.status(400).json({ error: 'You cannot change your own account status.', request_id: req.requestId });
      }
    }

    const result = await pool.query(
      `UPDATE users
       SET status = $1, status_reason = $2, status_updated_at = CURRENT_TIMESTAMP
       WHERE id = $3
       RETURNING id, email, status, status_reason`,
      [status, reason, userId]
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'User not found.', request_id: req.requestId });
    }

    await logModeration(req.firebaseUser, {
      action,
      targetUserId: userId,
      targetEmail: result.rows[0].email,
      reason: reason || `Account ${status} via admin dashboard`,
    });

    return res.status(200).json({ user: result.rows[0], request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// GET /api/admin/moderation — the audit trail, newest first.
// ---------------------------------------------------------------------------
async function listModeration(req, res, next) {
  try {
    const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 50, 1), 200);
    const result = await pool.query(
      `SELECT me.*, u.email AS user_email
       FROM moderation_events me
       LEFT JOIN users u ON u.id = me.target_user_id
       ORDER BY me.created_at DESC, me.id DESC
       LIMIT $1`,
      [limit]
    );
    return res.status(200).json({ events: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// GET /api/admin/track-progress — per-track engagement and skill analytics.
// ---------------------------------------------------------------------------
async function trackProgress(req, res, next) {
  try {
    const [tracks, activity, dims] = await Promise.all([
      pool.query(
        `SELECT t.id, t.name,
           (SELECT COUNT(*)::int FROM users u WHERE u.industry_track_id = t.id) AS users,
           (SELECT COUNT(*)::int FROM users u
             JOIN user_progress p ON p.user_id = u.id
             WHERE u.industry_track_id = t.id AND p.last_activity_date >= CURRENT_DATE - 7) AS active_7d,
           (SELECT COUNT(*)::int FROM users u
             JOIN user_progress p ON p.user_id = u.id
             WHERE u.industry_track_id = t.id AND p.last_activity_date >= CURRENT_DATE - 30) AS active_30d,
           (SELECT COALESCE(ROUND(AVG(p.readiness_score)), 0)::int FROM users u
             JOIN user_progress p ON p.user_id = u.id
             WHERE u.industry_track_id = t.id) AS avg_readiness,
           (SELECT COALESCE(ROUND(AVG(p.level)::numeric, 1), 0) FROM users u
             JOIN user_progress p ON p.user_id = u.id
             WHERE u.industry_track_id = t.id) AS avg_level,
           (SELECT COUNT(*)::int FROM tasks tk WHERE tk.track_id = t.id) AS task_count,
           (SELECT COUNT(*)::int FROM task_attempts ta
             JOIN tasks tk ON tk.id = ta.task_id
             WHERE tk.track_id = t.id AND ta.practice = FALSE) AS attempts,
           (SELECT COUNT(*)::int FROM task_attempts ta
             JOIN tasks tk ON tk.id = ta.task_id
             WHERE tk.track_id = t.id AND ta.practice = FALSE AND ta.passed) AS passed
         FROM industry_tracks t ORDER BY t.id`
      ),
      pool.query(
        `SELECT (NOW() AT TIME ZONE 'Africa/Johannesburg')::date - d.day AS day,
                COALESCE(COUNT(ta.id), 0)::int AS attempts,
                COALESCE(COUNT(ta.id) FILTER (WHERE ta.passed), 0)::int AS passed
         FROM generate_series(0, 13) AS d(day)
         LEFT JOIN task_attempts ta
           ON (ta.submitted_at AT TIME ZONE 'Africa/Johannesburg')::date
              = (NOW() AT TIME ZONE 'Africa/Johannesburg')::date - d.day
         GROUP BY d.day ORDER BY d.day`,
      ),
      pool.query(
        `SELECT tr.name AS track_name, s.dimension,
                COALESCE(ROUND(AVG(s.score)), 0)::int AS avg_score
         FROM skill_scores s
         JOIN users u ON u.id = s.user_id
         JOIN industry_tracks tr ON tr.id = u.industry_track_id
         GROUP BY tr.name, s.dimension
         ORDER BY tr.name, s.dimension`,
      ),
    ]);

    // Funnel: where users drop off between signup and competence.
    const funnel = await pool.query(
      `SELECT
         (SELECT COUNT(*)::int FROM users) AS signed_up,
         (SELECT COUNT(*)::int FROM users WHERE industry_track_id IS NOT NULL) AS track_selected,
         (SELECT COUNT(*)::int FROM users u
           WHERE EXISTS (SELECT 1 FROM task_attempts ta WHERE ta.user_id = u.id AND ta.practice = FALSE)) AS first_attempt,
         (SELECT COUNT(*)::int FROM users u
           WHERE (SELECT COUNT(*) FROM task_attempts ta WHERE ta.user_id = u.id AND ta.practice = FALSE) >= 5) AS five_attempts,
         (SELECT COUNT(*)::int FROM users u
           WHERE EXISTS (SELECT 1 FROM task_attempts ta WHERE ta.user_id = u.id AND ta.practice = FALSE AND ta.passed)) AS first_pass,
         (SELECT COUNT(*)::int FROM users u
           JOIN user_progress p ON p.user_id = u.id
           WHERE p.last_activity_date >= CURRENT_DATE - 30) AS active_30d`
    );

    // Cohorts: signup-month groups with their current engagement.
    const cohorts = await pool.query(
      `SELECT to_char(date_trunc('month', u.created_at), 'YYYY-MM') AS cohort,
              COUNT(*)::int AS users,
              COALESCE(ROUND(AVG(p.readiness_score)), 0)::int AS avg_readiness,
              COALESCE(ROUND(AVG(p.xp)), 0)::int AS avg_xp,
              COUNT(p.id)::int AS with_progress,
              COUNT(*) FILTER (WHERE p.last_activity_date >= CURRENT_DATE - 30)::int AS active_30d
       FROM users u
       LEFT JOIN user_progress p ON p.user_id = u.id
       GROUP BY 1 ORDER BY 1 DESC LIMIT 12`
    );

    // Content balance: feature x track coverage so gaps are visible at a glance.
    const balance = await pool.query(
      `SELECT tr.name AS track,
              COUNT(t.id) FILTER (WHERE t.feature = 'verification')::int AS verification,
              COUNT(t.id) FILTER (WHERE t.feature = 'judgement')::int AS judgement,
              COUNT(t.id) FILTER (WHERE t.feature = 'risk_governance')::int AS risk_governance,
              COUNT(t.id) FILTER (WHERE t.published = FALSE)::int AS drafts
       FROM industry_tracks tr
       LEFT JOIN tasks t ON t.track_id = tr.id
       GROUP BY tr.id, tr.name ORDER BY tr.id`
    );

    // Hardest tasks: the lowest pass rates with at least a few attempts.
    const hardest = await pool.query(
      `SELECT tk.id, tk.feature, tr.name AS track_name,
              COALESCE(v.title, j.title, r.title, '(untitled)') AS title,
              COUNT(ta.id)::int AS attempts,
              COALESCE(ROUND(100.0 * COUNT(ta.id) FILTER (WHERE ta.passed) / COUNT(ta.id)), 0)::int AS pass_rate
       FROM tasks tk
       JOIN industry_tracks tr ON tr.id = tk.track_id
       LEFT JOIN verification_tasks v ON v.task_id = tk.id
       LEFT JOIN judgement_tasks j ON j.task_id = tk.id
       LEFT JOIN risk_governance_tasks r ON r.task_id = tk.id
       JOIN task_attempts ta ON ta.task_id = tk.id AND ta.practice = FALSE
       GROUP BY tk.id, tk.feature, tr.name, v.title, j.title, r.title
       HAVING COUNT(ta.id) >= 3
       ORDER BY pass_rate ASC, attempts DESC
       LIMIT 10`
    );

    return res.status(200).json({
      tracks: tracks.rows,
      activity: activity.rows,
      skill_dimensions: dims.rows,
      hardest_tasks: hardest.rows,
      funnel: funnel.rows[0],
      cohorts: cohorts.rows,
      content_balance: balance.rows,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// GET /api/admin/tasks/:id — full task content, used by the editor and the
// learner-view preview.
// ---------------------------------------------------------------------------
async function getTaskDetail(req, res, next) {
  try {
    const taskId = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(taskId)) {
      return res.status(400).json({ error: 'Task id must be an integer.', request_id: req.requestId });
    }
    const anchor = await pool.query(
      `SELECT t.id, t.code, t.feature, t.track_id, t.published, t.created_at, tr.name AS track_name
       FROM tasks t JOIN industry_tracks tr ON tr.id = t.track_id WHERE t.id = $1`,
      [taskId]
    );
    if (!anchor.rows.length) {
      return res.status(404).json({ error: 'Task not found.', request_id: req.requestId });
    }
    const task = anchor.rows[0];
    const options = await pool.query(
      `SELECT id, kind, label, score, sort_order FROM task_options WHERE task_id = $1 ORDER BY kind, sort_order`,
      [taskId]
    );

    let content = {};
    if (task.feature === 'verification') {
      const r = await pool.query(`SELECT * FROM verification_tasks WHERE task_id = $1`, [taskId]);
      content = r.rows[0] || {};
    } else {
      const table = task.feature === 'judgement' ? 'judgement_tasks' : 'risk_governance_tasks';
      const r = await pool.query(`SELECT title, scenario, feedback FROM ${table} WHERE task_id = $1`, [taskId]);
      content = r.rows[0] || {};
    }

    return res.status(200).json({ task, content, options: options.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// PUT /api/admin/tasks/:id — edit any task field without deleting it (and so
// keeping its attempt history). Only provided fields are changed; options are
// replaced wholesale when an `options`/`decisions`/`reasons` array is given.
// ---------------------------------------------------------------------------
async function updateTask(req, res, next) {
  const client = await pool.connect();
  try {
    const taskId = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(taskId)) {
      return res.status(400).json({ error: 'Task id must be an integer.', request_id: req.requestId });
    }
    const body = req.body || {};

    await client.query('BEGIN');
    const anchor = await client.query('SELECT id, feature, code, approval FROM tasks WHERE id = $1 FOR UPDATE', [taskId]);
    if (!anchor.rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Task not found.', request_id: req.requestId });
    }
    const task = anchor.rows[0];
    const changed = [];

    // --- anchor fields ---
    if (body.track_id != null) {
      const trackId = Number.parseInt(body.track_id, 10);
      if (!Number.isInteger(trackId)) fail('track_id must be an integer.');
      const track = await client.query('SELECT id FROM industry_tracks WHERE id = $1', [trackId]);
      if (!track.rows.length) fail(`Track ${trackId} does not exist.`);
      await client.query('UPDATE tasks SET track_id = $1 WHERE id = $2', [trackId, taskId]);
      changed.push(`track -> ${trackId}`);
    }
    if (body.published != null) {
      const published = body.published === true || body.published === 'true';
      if (published && task.approval !== 'approved') {
        fail('This task has not been approved by a moderator yet. Only approved tasks can be published.');
      }
      await client.query('UPDATE tasks SET published = $1 WHERE id = $2', [published, taskId]);
      changed.push(published ? 'published' : 'unpublished (draft)');
    }

    const feature = task.feature;
    const isVerification = feature === 'verification';
    const contentTable = isVerification ? 'verification_tasks'
      : feature === 'judgement' ? 'judgement_tasks' : 'risk_governance_tasks';

    // --- content fields ---
    const fieldMap = [
      ['title', 'title'], ['scenario', 'scenario'], ['feedback', 'feedback'],
    ];
    if (isVerification) {
      fieldMap.push(['embedded_flaw', 'embedded_flaw'], ['expected_answer', 'expected_answer']);
      if (body.difficulty != null) {
        const difficulty = String(body.difficulty).toLowerCase();
        if (!DIFFICULTIES.has(difficulty)) fail('difficulty must be easy, medium or hard.');
        fieldMap.push(['difficulty', null]);
      }
    }
    for (const [field, errorName] of fieldMap) {
      if (body[field] == null) continue;
      const value = errorName ? reqString(body[field], errorName) : String(body[field]).toLowerCase();
      await client.query(`UPDATE ${contentTable} SET ${field} = $1 WHERE task_id = $2`, [value, taskId]);
      changed.push(`${field} updated`);
    }

    if (isVerification && body.format != null) {
      const format = String(body.format).toLowerCase();
      if (!['choice', 'line_text'].includes(format)) fail('format must be choice or line_text.');
      await client.query('UPDATE verification_tasks SET format = $1 WHERE task_id = $2', [format, taskId]);
      changed.push(`format -> ${format}`);
    }

    // line_text specifics
    if (isVerification && body.ai_output_lines != null) {
      const fields = parseLineTextFields(body);
      await client.query(
        `UPDATE verification_tasks
         SET ai_output_lines = $1, flaw_lines = $2, fix_keywords = $3, reason_keywords = $4
         WHERE task_id = $5`,
        [fields.ai_output_lines, fields.flaw_lines, fields.fix_keywords, fields.reason_keywords, taskId]
      );
      changed.push('line_text scoring data updated');
    }

    // --- options (replaced wholesale) ---
    if (body.options != null) {
      if (!isVerification) fail('options only applies to verification tasks; use decisions/reasons.');
      const options = parseOptions(body.options, OPTION_KINDS.verification, 'options');
      if (!options.some((o) => o.score >= 100)) fail('At least one option must score 100 (the correct answer).');
      await client.query('DELETE FROM task_options WHERE task_id = $1', [taskId]);
      for (let i = 0; i < options.length; i += 1) {
        await client.query(
          `INSERT INTO task_options (task_id, kind, label, score, sort_order) VALUES ($1, 'answer', $2, $3, $4)`,
          [taskId, options[i].label, options[i].score, i]
        );
      }
      changed.push(`${options.length} answer options replaced`);
    }
    if (body.decisions != null || body.reasons != null) {
      if (isVerification) fail('decisions/reasons only apply to judgement and risk_governance tasks.');
      const decisions = body.decisions != null ? parseOptions(body.decisions, ['decision'], 'decisions') : null;
      const reasons = body.reasons != null ? parseOptions(body.reasons, ['reason'], 'reasons') : null;
      if (decisions || reasons) {
        await client.query('DELETE FROM task_options WHERE task_id = $1', [taskId]);
        let sort = 0;
        for (const option of [...(decisions || []), ...(reasons || [])]) {
          await client.query(
            `INSERT INTO task_options (task_id, kind, label, score, sort_order) VALUES ($1, $2, $3, $4, $5)`,
            [taskId, option.kind, option.label, option.score, sort]
          );
          sort += 1;
        }
        changed.push('decision/reason options replaced');
      }
    }

    await client.query('COMMIT');

    if (body.published != null) {
      await logModeration(req.firebaseUser, {
        action: 'task_publish',
        reason: `Task #${taskId} (${task.code}): ${body.published === true || body.published === 'true' ? 'published' : 'unpublished'}`,
      });
    }
    await logModeration(req.firebaseUser, {
      action: 'task_update',
      reason: `Task #${taskId} (${task.code}) edited: ${changed.length ? changed.join(', ') : 'no changes'}`,
    });

    return res.status(200).json({ task: { id: taskId, changed }, request_id: req.requestId });
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    if (!err.status) return next(err);
    return res.status(err.status).json({ error: err.message, request_id: req.requestId });
  } finally {
    client.release();
  }
}

// ---------------------------------------------------------------------------
// POST /api/admin/tasks/import — bulk import. Body: { tasks: [...], dry_run }.
// With dry_run=true every entry is validated and nothing is written; with
// dry_run=false valid entries are inserted in one transaction. Reuses the
// single-task create validation by temporarily swapping req/res.
// ---------------------------------------------------------------------------
async function importTasks(req, res, next) {
  try {
    const list = Array.isArray(req.body?.tasks) ? req.body.tasks : [];
    if (!list.length) fail('tasks must be a non-empty array.');
    if (list.length > 200) fail('Import at most 200 tasks per request.');
    const dryRun = req.body.dry_run === true || req.body.dry_run === 'true';

    const results = [];
    const valid = [];
    for (let i = 0; i < list.length; i += 1) {
      try {
        await validateTaskBody(list[i]);
        valid.push(list[i]);
        results.push({ index: i, ok: true, title: String(list[i].title || '') });
      } catch (err) {
        results.push({ index: i, ok: false, error: err.message, title: String(list[i].title || '') });
      }
    }

    if (dryRun) {
      return res.status(200).json({
        dry_run: true, total: list.length, valid: valid.length, invalid: list.length - valid.length,
        results, request_id: req.requestId,
      });
    }
    if (!valid.length) {
      return res.status(400).json({
        error: 'No valid tasks to import.', total: list.length, valid: 0, invalid: list.length,
        results, request_id: req.requestId,
      });
    }

    // Insert all valid tasks through the same validation + insert path.
    const inserted = [];
    for (const taskBody of valid) {
      const fakeReq = { body: taskBody, requestId: req.requestId };
      const created = await insertTask(fakeReq); // shared with createTask
      inserted.push(created);
      await logModeration(req.firebaseUser, {
        action: 'task_import',
        reason: `Task #${created.id} (${created.feature}) imported: ${created.title}`,
      });
    }

    return res.status(201).json({
      dry_run: false, total: list.length, imported: inserted.length,
      failed: list.length - inserted.length, results, task_ids: inserted.map((t) => t.id),
      request_id: req.requestId,
    });
  } catch (err) {
    if (!err.status) return next(err);
    return res.status(err.status).json({ error: err.message, request_id: req.requestId });
  }
}

// Validation-only path used by the importer (no DB writes).
async function validateTaskBody(body) {
  const feature = String(body.feature || '').toLowerCase().trim();
  if (!FEATURES.has(feature)) fail('feature must be one of: verification, judgement, risk_governance, prompt_design.');
  if (feature === 'prompt_design') fail('Prompt Design tasks are not supported yet.');
  const trackId = Number.parseInt(body.track_id, 10);
  if (!Number.isInteger(trackId)) fail('track_id must be an integer.');
  const track = await pool.query('SELECT id FROM industry_tracks WHERE id = $1', [trackId]);
  if (!track.rows.length) fail(`Track ${trackId} does not exist.`);
  reqString(body.title, 'title', 255);
  reqString(body.scenario, 'scenario');
  if (feature === 'verification') {
    const format = body.format == null ? 'choice' : String(body.format).toLowerCase();
    if (!['choice', 'line_text'].includes(format)) fail('verification format must be choice or line_text.');
    reqString(body.embedded_flaw, 'embedded_flaw');
    reqString(body.expected_answer, 'expected_answer');
    reqString(body.feedback, 'feedback');
    const difficulty = String(body.difficulty || 'medium').toLowerCase();
    if (!DIFFICULTIES.has(difficulty)) fail('difficulty must be easy, medium or hard.');
    if (format === 'choice') {
      const options = parseOptions(body.options, OPTION_KINDS.verification, 'options');
      if (!options.some((o) => o.score >= 100)) fail('At least one option must score 100 (the correct answer).');
    } else {
      parseLineTextFields(body);
    }
  } else {
    reqString(body.feedback, 'feedback');
    parseOptions(body.decisions, ['decision'], 'decisions');
    parseOptions(body.reasons, ['reason'], 'reasons');
  }
  return true;
}

// Shared task insert (used by createTask and the importer). Returns the new
// task's identity. Assumes the body has already been validated when called from
// the importer; createTask calls it after its own validation.
async function insertTask(req) {
  const body = req.body || {};
  const feature = String(body.feature).toLowerCase().trim();
  const trackId = Number.parseInt(body.track_id, 10);
  const title = reqString(body.title, 'title', 255);
  const scenario = reqString(body.scenario, 'scenario');
  const published = false; // drafts await moderator approval

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 60) || 'task';
    const code = `admin-${slug}-${Date.now()}`;
    const taskResult = await client.query(
      `INSERT INTO tasks (code, feature, track_id, published) VALUES ($1, $2, $3, $4) RETURNING id, code`,
      [code, feature, trackId, published]
    );
    const taskId = taskResult.rows[0].id;

    if (feature === 'verification') {
      const format = (body.format == null ? 'choice' : String(body.format).toLowerCase());
      if (format === 'line_text') {
        const lineFields = parseLineTextFields(body);
        await client.query(
          `INSERT INTO verification_tasks
             (task_id, format, title, scenario, embedded_flaw, expected_answer, feedback, difficulty,
              ai_output_lines, flaw_lines, fix_keywords, reason_keywords)
           VALUES ($1, 'line_text', $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
          [taskId, title, scenario, reqString(body.embedded_flaw, 'embedded_flaw'),
            reqString(body.expected_answer, 'expected_answer'), reqString(body.feedback, 'feedback'),
            String(body.difficulty || 'medium').toLowerCase(), lineFields.ai_output_lines,
            lineFields.flaw_lines, lineFields.fix_keywords, lineFields.reason_keywords]
        );
      } else {
        const options = parseOptions(body.options, OPTION_KINDS.verification, 'options');
        await client.query(
          `INSERT INTO verification_tasks
             (task_id, format, title, scenario, embedded_flaw, expected_answer, feedback, difficulty)
           VALUES ($1, 'choice', $2, $3, $4, $5, $6, $7)`,
          [taskId, title, scenario, reqString(body.embedded_flaw, 'embedded_flaw'),
            reqString(body.expected_answer, 'expected_answer'), reqString(body.feedback, 'feedback'),
            String(body.difficulty || 'medium').toLowerCase()]
        );
        for (let i = 0; i < options.length; i += 1) {
          await client.query(
            `INSERT INTO task_options (task_id, kind, label, score, sort_order) VALUES ($1, 'answer', $2, $3, $4)`,
            [taskId, options[i].label, options[i].score, i]
          );
        }
      }
    } else {
      const table = feature === 'judgement' ? 'judgement_tasks' : 'risk_governance_tasks';
      await client.query(
        `INSERT INTO ${table} (task_id, title, scenario, feedback) VALUES ($1, $2, $3, $4)`,
        [taskId, title, scenario, reqString(body.feedback, 'feedback')]
      );
      const decisions = parseOptions(body.decisions, ['decision'], 'decisions');
      const reasons = parseOptions(body.reasons, ['reason'], 'reasons');
      let sort = 0;
      for (const option of [...decisions, ...reasons]) {
        await client.query(
          `INSERT INTO task_options (task_id, kind, label, score, sort_order) VALUES ($1, $2, $3, $4, $5)`,
          [taskId, option.kind, option.label, option.score, sort]
        );
        sort += 1;
      }
    }

    await client.query('COMMIT');
    return { id: taskId, code, feature, track_id: trackId, title, published };
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    throw err;
  } finally {
    client.release();
  }
}

// ---------------------------------------------------------------------------
// Lab / textbook content management
// ---------------------------------------------------------------------------

// GET /api/admin/lab — lessons with section counts and activity counts.
async function listLab(req, res, next) {
  try {
    const params = [];
    let where = '';
    if (req.query.track_id != null) {
      const trackId = Number.parseInt(req.query.track_id, 10);
      if (!Number.isInteger(trackId)) {
        return res.status(400).json({ error: 'track_id must be an integer.', request_id: req.requestId });
      }
      params.push(trackId);
      where = `WHERE l.track_id = $${params.length}`;
    }
    const result = await pool.query(
      `SELECT l.id, l.code, l.title, l.summary, l.level, l.competency, l.sort_order,
              tr.name AS track_name,
              (SELECT COUNT(*)::int FROM lab_lesson_sections s WHERE s.lesson_id = l.id) AS section_count,
              (SELECT COUNT(*)::int FROM lab_activities a WHERE a.lesson_id = l.id) AS activity_count
       FROM lab_lessons l
       LEFT JOIN industry_tracks tr ON tr.id = l.track_id
       ${where}
       ORDER BY l.sort_order, l.id
       LIMIT 300`,
      params
    );
    return res.status(200).json({ lessons: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/admin/lab/:id — one lesson with its full section tree.
async function getLabLesson(req, res, next) {
  try {
    const lessonId = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(lessonId)) {
      return res.status(400).json({ error: 'Lesson id must be an integer.', request_id: req.requestId });
    }
    const lesson = await pool.query(
      `SELECT l.*, tr.name AS track_name FROM lab_lessons l
       LEFT JOIN industry_tracks tr ON tr.id = l.track_id WHERE l.id = $1`,
      [lessonId]
    );
    if (!lesson.rows.length) {
      return res.status(404).json({ error: 'Lesson not found.', request_id: req.requestId });
    }
    const sections = await pool.query(
      `SELECT id, parent_id, heading, body, sort_order FROM lab_lesson_sections
       WHERE lesson_id = $1 ORDER BY sort_order, id`,
      [lessonId]
    );
    return res.status(200).json({ lesson: lesson.rows[0], sections: sections.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// PUT /api/admin/lab/sections/:id — edit a section's heading and/or body.
async function updateLabSection(req, res, next) {
  try {
    const sectionId = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(sectionId)) {
      return res.status(400).json({ error: 'Section id must be an integer.', request_id: req.requestId });
    }
    const body = req.body || {};
    const sets = [];
    const params = [];
    if (body.heading != null) {
      params.push(reqString(body.heading, 'heading', 255));
      sets.push(`heading = $${params.length}`);
    }
    if (body.body != null) {
      params.push(reqString(body.body, 'body'));
      sets.push(`body = $${params.length}`);
    }
    if (!sets.length) fail('Nothing to update: provide heading and/or body.');
    params.push(sectionId);
    const result = await pool.query(
      `UPDATE lab_lesson_sections SET ${sets.join(', ')} WHERE id = $${params.length} RETURNING id, lesson_id, heading`,
      params
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Section not found.', request_id: req.requestId });
    }
    await logModeration(req.firebaseUser, {
      action: 'lab_update',
      reason: `Lab section #${sectionId} (lesson #${result.rows[0].lesson_id}) updated`,
    });
    return res.status(200).json({ section: result.rows[0], request_id: req.requestId });
  } catch (err) {
    if (!err.status) return next(err);
    return res.status(err.status).json({ error: err.message, request_id: req.requestId });
  }
}

// ---------------------------------------------------------------------------
// Workshop moderation
// ---------------------------------------------------------------------------

// GET /api/admin/workshop — posts (optionally ?reported=1 to show only posts
// with open reports, ?q= for body text search, ?track_id=).
async function listWorkshopPosts(req, res, next) {
  try {
    const params = [];
    const where = [];
    if (String(req.query.reported) === '1') {
      where.push(`EXISTS (SELECT 1 FROM workshop_reports wr WHERE wr.post_id = p.id)`);
    }
    if (req.query.q != null && String(req.query.q).trim()) {
      params.push(`%${String(req.query.q).trim().toLowerCase()}%`);
      where.push(`LOWER(p.body) LIKE $${params.length}`);
    }
    if (req.query.track_id != null) {
      const trackId = Number.parseInt(req.query.track_id, 10);
      if (!Number.isInteger(trackId)) {
        return res.status(400).json({ error: 'track_id must be an integer.', request_id: req.requestId });
      }
      params.push(trackId);
      where.push(`p.track_id = $${params.length}`);
    }
    const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const result = await pool.query(
      `SELECT p.id, p.body, p.hidden, p.created_at, p.track_id, tr.name AS track_name,
              u.id AS author_id, u.email AS author_email, u.display_name AS author_name,
              u.status AS author_status,
              (SELECT COUNT(*)::int FROM workshop_reports wr WHERE wr.post_id = p.id) AS report_count,
              (SELECT COUNT(*)::int FROM workshop_reactions rx WHERE rx.post_id = p.id) AS reaction_count
       FROM workshop_posts p
       JOIN users u ON u.id = p.author_id
       LEFT JOIN industry_tracks tr ON tr.id = p.track_id
       ${whereSql}
       ORDER BY report_count DESC, p.created_at DESC
       LIMIT 200`,
      params
    );
    return res.status(200).json({ posts: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/admin/workshop/reports — every report with its post and reporter.
async function listWorkshopReports(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT wr.id, wr.reason, wr.created_at,
              p.id AS post_id, p.body AS post_body, p.hidden AS post_hidden,
              reporter.email AS reporter_email,
              author.id AS author_id, author.email AS author_email, author.display_name AS author_name,
              author.status AS author_status
       FROM workshop_reports wr
       JOIN workshop_posts p ON p.id = wr.post_id
       JOIN users reporter ON reporter.id = wr.reporter_id
       JOIN users author ON author.id = p.author_id
       ORDER BY wr.created_at DESC
       LIMIT 200`
    );
    return res.status(200).json({ reports: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// POST /api/admin/workshop/:id — moderate one post.
// Body: { action: 'hide' | 'unhide' | 'delete', reason? }
async function moderateWorkshopPost(req, res, next) {
  try {
    const postId = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(postId)) {
      return res.status(400).json({ error: 'Post id must be an integer.', request_id: req.requestId });
    }
    const body = req.body || {};
    const action = String(body.action || '').toLowerCase().trim();
    if (!['hide', 'unhide', 'delete'].includes(action)) {
      return res.status(400).json({ error: "action must be 'hide', 'unhide' or 'delete'.", request_id: req.requestId });
    }
    const reason = body.reason == null ? null : String(body.reason).trim().slice(0, 2000) || null;

    if (action === 'delete') {
      // Deletes the post, its replies (parent_id cascade), reactions and reports.
      const result = await pool.query('DELETE FROM workshop_posts WHERE id = $1 RETURNING id', [postId]);
      if (!result.rows.length) {
        return res.status(404).json({ error: 'Post not found.', request_id: req.requestId });
      }
      await logModeration(req.firebaseUser, { action: 'workshop_delete', reason: `Workshop post #${postId} deleted${reason ? ': ' + reason : ''}` });
      return res.status(200).json({ deleted: result.rows[0], request_id: req.requestId });
    }

    const hidden = action === 'hide';
    const result = await pool.query(
      `UPDATE workshop_posts SET hidden = $1, edited_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING id, hidden`,
      [hidden, postId]
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Post not found.', request_id: req.requestId });
    }
    await logModeration(req.firebaseUser, { action: 'workshop_hide', reason: `Workshop post #${postId} ${action} by admin${reason ? ': ' + reason : ''}` });
    return res.status(200).json({ post: result.rows[0], request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// User tools: grant XP/tokens, GDPR export, hard delete, Firebase disable.
// ---------------------------------------------------------------------------

// POST /api/admin/users/:id/grant — adjust a user's XP and/or reward tokens
// (e.g. compensating for a bug). Token changes go through the ledger's
// 'adjustment' reason so the app's wallet stays consistent.
async function grantAdjust(req, res, next) {
  const client = await pool.connect();
  try {
    const userId = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(userId)) fail('User id must be an integer.');
    const body = req.body || {};
    const xp = body.xp == null ? 0 : Number(body.xp);
    const tokens = body.tokens == null ? 0 : Number(body.tokens);
    if (!Number.isInteger(xp) || xp < 0) fail('xp must be a non-negative integer.');
    if (!Number.isInteger(tokens) || tokens <= 0) fail('tokens must be a positive integer (spending tokens is not an admin tool).');
    const reason = reqString(body.reason, 'reason', 500);
    let changed = '';

    await client.query('BEGIN');
    const user = await client.query('SELECT id, email FROM users WHERE id = $1', [userId]);
    if (!user.rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'User not found.', request_id: req.requestId });
    }

    if (xp > 0) {
      const result = await client.query(
        `UPDATE user_progress SET xp = xp + $1, updated_at = CURRENT_TIMESTAMP WHERE user_id = $2 RETURNING xp, level`,
        [xp, userId]
      );
      if (!result.rows.length) {
        await client.query(
          `INSERT INTO user_progress (user_id, xp, level, streak, last_activity_date)
           VALUES ($1, $2, 1, 0, NULL) RETURNING xp, level`,
          [userId, xp]
        );
      }
      changed = `+${xp} XP`;
    }
    if (tokens > 0) {
      const ref = `admin-grant-${Date.now()}`;
      await client.query(
        `INSERT INTO reward_token_events (user_id, delta, reason, ref) VALUES ($1, $2, 'adjustment', $3)`,
        [userId, tokens, ref]
      );
      const wallet = await client.query(
        `UPDATE user_progress SET tokens = tokens + $1 WHERE user_id = $2 RETURNING tokens`,
        [tokens, userId]
      );
      if (!wallet.rows.length) {
        await client.query(
          `INSERT INTO user_progress (user_id, xp, level, streak, last_activity_date, tokens)
           VALUES ($1, 0, 1, 0, NULL, $2)`,
          [userId, tokens]
        );
      }
      changed = (changed ? changed + ', ' : '') + `+${tokens} tokens`;
    }

    await client.query('COMMIT');
    await logModeration(req.firebaseUser, {
      action: 'user_grant', targetUserId: userId, targetEmail: user.rows[0].email,
      reason: `${changed}: ${reason}`,
    });
    return res.status(200).json({ granted: { xp, tokens }, request_id: req.requestId });
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    if (!err.status) return next(err);
    return res.status(err.status).json({ error: err.message, request_id: req.requestId });
  } finally {
    client.release();
  }
}

// GET /api/admin/users/:id/export — GDPR data export: everything the platform
// knows about this user, as a downloadable JSON file.
async function exportUserData(req, res, next) {
  try {
    const userId = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(userId)) {
      return res.status(400).json({ error: 'User id must be an integer.', request_id: req.requestId });
    }
    const [user, progress, skills, attempts, tokens, achievements, posts] = await Promise.all([
      pool.query('SELECT * FROM users WHERE id = $1', [userId]),
      pool.query('SELECT * FROM user_progress WHERE user_id = $1', [userId]),
      pool.query('SELECT dimension, score, attempts_count, updated_at FROM skill_scores WHERE user_id = $1', [userId]),
      pool.query('SELECT * FROM task_attempts WHERE user_id = $1 ORDER BY submitted_at DESC', [userId]),
      pool.query('SELECT * FROM reward_token_events WHERE user_id = $1 ORDER BY created_at DESC', [userId]),
      pool.query(`SELECT a.code, a.name, ua.earned_at FROM user_achievements ua JOIN achievements a ON a.id = ua.achievement_id WHERE ua.user_id = $1`, [userId]),
      pool.query('SELECT id, body, hidden, created_at FROM workshop_posts WHERE author_id = $1 ORDER BY created_at DESC', [userId]),
    ]);
    if (!user.rows.length) {
      return res.status(404).json({ error: 'User not found.', request_id: req.requestId });
    }
    await logModeration(req.firebaseUser, {
      action: 'user_export', targetUserId: userId, targetEmail: user.rows[0].email,
      reason: 'GDPR data export downloaded',
    });
    const payload = {
      exported_at: new Date().toISOString(),
      user: user.rows[0],
      progress: progress.rows[0] || null,
      skill_scores: skills.rows,
      task_attempts: attempts.rows,
      reward_token_events: tokens.rows,
      achievements: achievements.rows,
      workshop_posts: posts.rows,
    };
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', `attachment; filename="verifai-user-${userId}-export.json"`);
    return res.status(200).send(JSON.stringify(payload, null, 2));
  } catch (err) {
    return next(err);
  }
}

// DELETE /api/admin/users/:id — GDPR hard delete. FK cascades remove every
// trace (attempts, skills, posts, tokens). Refuses to delete an admin.
async function hardDeleteUser(req, res, next) {
  const client = await pool.connect();
  try {
    const userId = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(userId)) fail('User id must be an integer.');
    const adminUid = req.firebaseUser.uid;
    if (adminUid) {
      const self = await client.query('SELECT id FROM users WHERE firebase_uid = $1', [adminUid]);
      if (self.rows[0]?.id === userId) fail('You cannot delete your own account from the panel.');
    }
    await client.query('BEGIN');
    const result = await client.query('DELETE FROM users WHERE id = $1 RETURNING id, email', [userId]);
    if (!result.rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'User not found.', request_id: req.requestId });
    }
    await client.query('COMMIT');
    await logModeration(req.firebaseUser, {
      action: 'user_delete', targetUserId: userId, targetEmail: result.rows[0].email,
      reason: 'GDPR hard delete (all data removed)',
    });
    return res.status(200).json({ deleted: result.rows[0], request_id: req.requestId });
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    if (!err.status) return next(err);
    return res.status(err.status).json({ error: err.message, request_id: req.requestId });
  } finally {
    client.release();
  }
}

// POST /api/admin/users/:id/firebase — disable/enable the underlying Firebase
// Auth account (a DB suspension blocks the API, but Firebase disable also stops
// new sign-ins and token refreshes).
async function setFirebaseDisabled(req, res, next) {
  try {
    const userId = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(userId)) {
      return res.status(400).json({ error: 'User id must be an integer.', request_id: req.requestId });
    }
    const disabled = req.body?.disabled === true;
    const user = await pool.query('SELECT id, email, firebase_uid FROM users WHERE id = $1', [userId]);
    if (!user.rows.length) {
      return res.status(404).json({ error: 'User not found.', request_id: req.requestId });
    }
    const { getFirebaseAdmin } = require('../db/firebase');
    await getFirebaseAdmin().updateUser(user.rows[0].firebase_uid, { disabled });
    await logModeration(req.firebaseUser, {
      action: 'user_firebase', targetUserId: userId, targetEmail: user.rows[0].email,
      reason: `Firebase account ${disabled ? 'disabled' : 're-enabled'} (blocks sign-in and token refresh)`,
    });
    return res.status(200).json({ user: { id: userId, firebase_disabled: disabled }, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// System: health, config, admin registry.
// ---------------------------------------------------------------------------

// GET /api/admin/system — live platform health for the System tab.
async function getSystem(req, res, next) {
  try {
    const usage = await pool.query(
      `SELECT
         (SELECT COUNT(*)::int FROM assistant_sessions WHERE created_at >= CURRENT_DATE - 7) AS assistant_sessions_7d,
         (SELECT COUNT(*)::int FROM vera_sessions WHERE created_at >= CURRENT_DATE - 7) AS vera_sessions_7d,
         (SELECT COUNT(*)::int FROM verification_analyses WHERE created_at >= CURRENT_DATE - 7) AS verification_analyses_7d,
         (SELECT COUNT(*)::int FROM task_attempts WHERE submitted_at >= CURRENT_DATE - 7) AS attempts_7d,
         (SELECT COUNT(*)::int FROM users) AS users_total`
    );
    const dbLatency = await (async () => { const t0 = Date.now(); await pool.query('SELECT 1'); return Date.now() - t0; })();
    const { resolveRole } = require('../middleware/adminRoles');
    const role = await resolveRole(req.firebaseUser);
    return res.status(200).json({
      status: 'ok',
      role,
      db: { connected: true, latency_ms: dbLatency, pool_total: pool.totalCount, pool_idle: pool.idleCount, pool_waiting: pool.waitingCount },
      process: { uptime_seconds: Math.round(process.uptime()), memory_mb: Math.round(process.memoryUsage().rss / 1048576), node: process.version },
      usage: usage.rows[0],
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// GET /api/admin/config — current runtime configuration.
async function getConfigValues(req, res, next) {
  try {
    const config = await require('../middleware/adminRoles').getConfig();
    return res.status(200).json({ config, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// PUT /api/admin/config — update runtime configuration keys. Only keys in the
// defaults whitelist are accepted; values are free-form strings.
async function updateConfigValues(req, res, next) {
  try {
    const { CONFIG_DEFAULTS, invalidateConfigCache } = require('../middleware/adminRoles');
    const body = req.body || {};
    const updates = [];
    for (const [key, value] of Object.entries(body)) {
      if (!(key in CONFIG_DEFAULTS)) fail(`Unknown config key: ${key}`);
      const valueStr = String(value);
      if (key === 'maintenance_mode' && !['on', 'off'].includes(valueStr)) fail('maintenance_mode must be on or off.');
      if (valueStr.length > 500) fail(`${key} is too long (max 500).`);
      updates.push([key, valueStr]);
    }
    if (!updates.length) fail('No configuration changes provided.');
    for (const [key, value] of updates) {
      await pool.query(
        `INSERT INTO app_config (key, value, updated_by) VALUES ($1, $2, $3)
         ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_by = EXCLUDED.updated_by, updated_at = CURRENT_TIMESTAMP`,
        [key, value, String(req.firebaseUser.email || req.firebaseUser.uid)]
      );
    }
    invalidateConfigCache();
    await logModeration(req.firebaseUser, {
      action: 'config_update',
      reason: `Config updated: ${updates.map(([k, v]) => `${k}=${v}`).join(', ')}`,
    });
    const config = await require('../middleware/adminRoles').getConfig();
    return res.status(200).json({ config, request_id: req.requestId });
  } catch (err) {
    if (!err.status) return next(err);
    return res.status(err.status).json({ error: err.message, request_id: req.requestId });
  }
}

// GET /api/admin/admins — the admin registry (role per admin email).
async function listAdmins(req, res, next) {
  try {
    const rows = await pool.query('SELECT email, role, added_by, created_at FROM admin_accounts ORDER BY created_at');
    const envEmails = (process.env.ADMIN_EMAILS || '').split(',').map((s) => s.trim()).filter(Boolean)
      .map((entry) => {
        const [email, role] = entry.toLowerCase().split(':');
        return { email, role: role || 'admin', source: 'env' };
      });
    return res.status(200).json({ db_admins: rows.rows, env_admins: envEmails, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// POST /api/admin/admins — add or update an admin's role. Body: { email, role }.
async function addAdmin(req, res, next) {
  try {
    const email = String(req.body?.email || '').trim().toLowerCase();
    const role = String(req.body?.role || '').toLowerCase().trim();
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) fail('A valid email is required.');
    if (!['super', 'admin', 'moderator'].includes(role)) fail("role must be 'super', 'admin' or 'moderator'.");
    const result = await pool.query(
      `INSERT INTO admin_accounts (email, role, added_by) VALUES ($1, $2, $3)
       ON CONFLICT (email) DO UPDATE SET role = EXCLUDED.role, added_by = EXCLUDED.added_by
       RETURNING email, role, added_by`,
      [email, role, String(req.firebaseUser.email || req.firebaseUser.uid)]
    );
    await logModeration(req.firebaseUser, { action: 'admin_add', targetEmail: email, reason: `${email} granted ${role} role` });
    return res.status(200).json({ admin: result.rows[0], request_id: req.requestId });
  } catch (err) {
    if (!err.status) return next(err);
    return res.status(err.status).json({ error: err.message, request_id: req.requestId });
  }
}

// DELETE /api/admin/admins/:email — remove a DB-registered admin (env admins
// cannot be removed here; edit ADMIN_EMAILS instead).
async function removeAdmin(req, res, next) {
  try {
    const email = String(req.params.email || '').trim().toLowerCase();
    const result = await pool.query('DELETE FROM admin_accounts WHERE email = $1 RETURNING email, role', [email]);
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Admin not found in the registry (env-listed admins are managed via ADMIN_EMAILS).', request_id: req.requestId });
    }
    await logModeration(req.firebaseUser, { action: 'admin_remove', targetEmail: email, reason: `${email} removed from ${result.rows[0].role} role` });
    return res.status(200).json({ removed: result.rows[0], request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// CSV exports: users.csv, attempts.csv, tracks.csv (with a BOM so Excel opens
// UTF-8 correctly).
// ---------------------------------------------------------------------------
function csvEscape(value) {
  const s = value == null ? '' : String(value);
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}
function sendCsv(res, filename, headers, rows) {
  const lines = [headers.join(',')];
  for (const row of rows) lines.push(row.map(csvEscape).join(','));
  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
  res.status(200).send('\uFEFF' + lines.join('\n'));
}

async function exportUsersCsv(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT u.id, u.email, u.display_name, u.status, tr.name AS track, u.created_at,
              a.role AS admin_role,
              p.xp, p.level, p.streak, p.readiness_score, p.tier,
              (SELECT COUNT(*)::int FROM task_attempts ta WHERE ta.user_id = u.id AND ta.practice = FALSE) AS attempts,
              (SELECT COUNT(*)::int FROM task_attempts ta WHERE ta.user_id = u.id AND ta.practice = FALSE AND ta.passed) AS passed
       FROM users u
       LEFT JOIN industry_tracks tr ON tr.id = u.industry_track_id
       LEFT JOIN user_progress p ON p.user_id = u.id
       LEFT JOIN admin_accounts a ON lower(a.email) = lower(u.email)
       ORDER BY u.id`
    );
    sendCsv(res, 'verifai-users.csv',
      ['id', 'email', 'display_name', 'status', 'track', 'created_at', 'admin_role', 'xp', 'level', 'streak', 'readiness', 'tier', 'attempts', 'passed'],
      result.rows.map((u) => [u.id, u.email, u.display_name, u.status, u.track, u.created_at, u.admin_role, u.xp, u.level, u.streak, u.readiness_score, u.tier, u.attempts, u.passed]));
  } catch (err) {
    return next(err);
  }
}

async function exportAttemptsCsv(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT ta.id, u.email, ta.task_id, ta.task_title, t.feature, tr.name AS track,
              ta.score, ta.passed, ta.practice, ta.xp_earned, ta.submitted_at
       FROM task_attempts ta
       JOIN users u ON u.id = ta.user_id
       JOIN tasks t ON t.id = ta.task_id
       LEFT JOIN industry_tracks tr ON tr.id = t.track_id
       ORDER BY ta.submitted_at DESC LIMIT 50000`
    );
    sendCsv(res, 'verifai-attempts.csv',
      ['id', 'user_email', 'task_id', 'task_title', 'feature', 'track', 'score', 'passed', 'practice', 'xp_earned', 'submitted_at'],
      result.rows.map((a) => [a.id, a.email, a.task_id, a.task_title, a.feature, a.track, a.score, a.passed, a.practice, a.xp_earned, a.submitted_at]));
  } catch (err) {
    return next(err);
  }
}

async function exportTracksCsv(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT t.name AS track,
         (SELECT COUNT(*)::int FROM users u WHERE u.industry_track_id = t.id) AS users,
         (SELECT COUNT(*)::int FROM users u JOIN user_progress p ON p.user_id = u.id
           WHERE u.industry_track_id = t.id AND p.last_activity_date >= CURRENT_DATE - 30) AS active_30d,
         (SELECT COALESCE(ROUND(AVG(p.readiness_score)), 0)::int FROM users u JOIN user_progress p ON p.user_id = u.id
           WHERE u.industry_track_id = t.id) AS avg_readiness,
         (SELECT COUNT(*)::int FROM tasks tk WHERE tk.track_id = t.id) AS tasks,
         (SELECT COUNT(*)::int FROM task_attempts ta JOIN tasks tk ON tk.id = ta.task_id
           WHERE tk.track_id = t.id AND ta.practice = FALSE) AS attempts,
         (SELECT COUNT(*)::int FROM task_attempts ta JOIN tasks tk ON tk.id = ta.task_id
           WHERE tk.track_id = t.id AND ta.practice = FALSE AND ta.passed) AS passed
       FROM industry_tracks t ORDER BY t.id`
    );
    sendCsv(res, 'verifai-tracks.csv',
      ['track', 'users', 'active_30d', 'avg_readiness', 'tasks', 'attempts', 'passed'],
      result.rows.map((t) => [t.track, t.users, t.active_30d, t.avg_readiness, t.tasks, t.attempts, t.passed]));
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// APPROVAL QUEUE — every task must be approved by a moderator before it can
// be published to learners.
// ---------------------------------------------------------------------------

// GET /api/admin/approvals?status=pending|approved|rejected — the queue.
async function listApprovals(req, res, next) {
  try {
    const status = String(req.query.status || 'pending').toLowerCase();
    if (!['pending', 'approved', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'status must be pending, approved or rejected.', request_id: req.requestId });
    }
    const result = await pool.query(
      `SELECT t.id, t.code, t.feature, t.approval, t.approved_by, t.approved_at, t.approval_note,
              t.published, t.created_at, tr.name AS track_name,
              COALESCE(v.title, j.title, r.title, '(untitled)') AS title
       FROM tasks t
       JOIN industry_tracks tr ON tr.id = t.track_id
       LEFT JOIN verification_tasks v ON v.task_id = t.id
       LEFT JOIN judgement_tasks j ON j.task_id = t.id
       LEFT JOIN risk_governance_tasks r ON r.task_id = t.id
       WHERE t.approval = $1
       ORDER BY t.created_at ASC
       LIMIT 200`,
      [status]
    );
    return res.status(200).json({ tasks: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// POST /api/admin/tasks/:id/approval — approve or reject. Body: { action,
// note? }. Approval is what unlocks publishing; rejection sends the task back
// for rework (still editable via PUT).
async function reviewTask(req, res, next) {
  try {
    const taskId = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(taskId)) {
      return res.status(400).json({ error: 'Task id must be an integer.', request_id: req.requestId });
    }
    const action = String(req.body?.action || '').toLowerCase();
    if (!['approve', 'reject'].includes(action)) {
      return res.status(400).json({ error: "action must be 'approve' or 'reject'.", request_id: req.requestId });
    }
    const note = req.body?.note == null ? null : String(req.body.note).trim().slice(0, 2000) || null;
    const approval = action === 'approve' ? 'approved' : 'rejected';

    const result = await pool.query(
      `UPDATE tasks
       SET approval = $1, approved_by = $2, approved_at = CURRENT_TIMESTAMP, approval_note = $3
       WHERE id = $4
       RETURNING id, code, approval, approved_by`,
      [approval, String(req.firebaseUser.email || req.firebaseUser.uid), note, taskId]
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Task not found.', request_id: req.requestId });
    }
    await logModeration(req.firebaseUser, {
      action: `task_${action}`,
      reason: `Task #${taskId} (${result.rows[0].code}) ${approval}${note ? ': ' + note : ''}`,
    });
    return res.status(200).json({ task: result.rows[0], request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// PER-DEPARTMENT ANSWER TRACKING (answer_logs)
// ---------------------------------------------------------------------------

// GET /api/admin/answers/summary — rollups per department (industry track):
// volume, pass rate, average score, per-feature breakdown, and daily trend.
async function answerSummary(req, res, next) {
  try {
    const [dept, perFeature, trend] = await Promise.all([
      pool.query(
        `SELECT COALESCE(tr.name, '(no track)') AS department,
                COUNT(*)::int AS answers,
                COUNT(*) FILTER (WHERE NOT al.practice)::int AS graded_answers,
                COUNT(*) FILTER (WHERE al.passed)::int AS passed,
                COALESCE(ROUND(AVG(al.score)), 0)::int AS avg_score,
                COUNT(DISTINCT al.user_id)::int AS users
         FROM answer_logs al
         LEFT JOIN industry_tracks tr ON tr.id = al.department_id
         GROUP BY tr.id, tr.name
         ORDER BY answers DESC`
      ),
      pool.query(
        `SELECT COALESCE(tr.name, '(no track)') AS department, al.feature,
                COUNT(*)::int AS answers,
                COALESCE(ROUND(AVG(al.score)), 0)::int AS avg_score,
                COALESCE(ROUND(100.0 * COUNT(*) FILTER (WHERE al.passed) / NULLIF(COUNT(*), 0)), 0)::int AS pass_rate
         FROM answer_logs al
         LEFT JOIN industry_tracks tr ON tr.id = al.department_id
         GROUP BY tr.id, tr.name, al.feature
         ORDER BY department, al.feature`
      ),
      pool.query(
        `SELECT COALESCE(tr.name, '(no track)') AS department,
                (NOW() AT TIME ZONE 'Africa/Johannesburg')::date - d.day AS day,
                COUNT(al.id)::int AS answers,
                COALESCE(ROUND(AVG(al.score)), 0)::int AS avg_score
         FROM generate_series(0, 29) AS d(day)
         CROSS JOIN (SELECT DISTINCT department_id FROM answer_logs) dd
         LEFT JOIN answer_logs al
           ON al.department_id = dd.department_id
          AND (al.submitted_at AT TIME ZONE 'Africa/Johannesburg')::date
              = (NOW() AT TIME ZONE 'Africa/Johannesburg')::date - d.day
         LEFT JOIN industry_tracks tr ON tr.id = dd.department_id
         GROUP BY dd.department_id, tr.name, d.day
         ORDER BY department, d.day`
      ),
    ]);
    return res.status(200).json({
      departments: dept.rows, per_feature: perFeature.rows, trend: trend.rows,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// GET /api/admin/answers?department_id=&feature=&practice=&limit=&offset=
// — raw answer log drill-down.
async function listAnswers(req, res, next) {
  try {
    const params = [];
    const where = [];
    if (req.query.department_id != null) {
      const deptId = Number.parseInt(req.query.department_id, 10);
      if (!Number.isInteger(deptId)) {
        return res.status(400).json({ error: 'department_id must be an integer.', request_id: req.requestId });
      }
      params.push(deptId);
      where.push(`al.department_id = $${params.length}`);
    }
    const feature = req.query.feature == null ? null : String(req.query.feature).toLowerCase();
    if (feature) {
      if (!FEATURES.has(feature)) {
        return res.status(400).json({ error: 'Unknown feature.', request_id: req.requestId });
      }
      params.push(feature);
      where.push(`al.feature = $${params.length}`);
    }
    if (req.query.practice != null) {
      params.push(String(req.query.practice) === 'true');
      where.push(`al.practice = $${params.length}`);
    }
    const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 100, 1), 500);
    const offset = Math.max(Number.parseInt(req.query.offset, 10) || 0, 0);

    const count = await pool.query(`SELECT COUNT(*)::int AS total FROM answer_logs al ${whereSql}`, params);
    params.push(limit, offset);
    const result = await pool.query(
      `SELECT al.id, al.score, al.passed, al.practice, al.answer_summary, al.submitted_at,
              al.feature, u.email AS user_email, u.display_name AS user_name,
              tr.name AS department, ta.task_title
       FROM answer_logs al
       LEFT JOIN users u ON u.id = al.user_id
       LEFT JOIN industry_tracks tr ON tr.id = al.department_id
       LEFT JOIN task_attempts ta ON ta.id = al.attempt_id
       ${whereSql}
       ORDER BY al.submitted_at DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );
    return res.status(200).json({
      answers: result.rows, total: count.rows[0].total, limit, offset,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// GET /api/admin/analytics — app-wide analytics for the Analytics page.
// ---------------------------------------------------------------------------
async function getAnalytics(req, res, next) {
  try {
    const [growth, activity, features, workshop, tokens, moderation, llm] = await Promise.all([
      // User growth: new signups per week (last 12 weeks) + totals. The weekly
      // series is zero-filled with generate_series so weeks without signups
      // still produce a bar-slot (and a correct label) on the chart.
      pool.query(
        `SELECT (SELECT COUNT(*)::int FROM users) AS total,
                (SELECT COUNT(*)::int FROM users WHERE created_at >= CURRENT_DATE - 7) AS new_7d,
                (SELECT COUNT(*)::int FROM users WHERE created_at >= CURRENT_DATE - 30) AS new_30d,
                (SELECT COUNT(*)::int FROM users u JOIN user_progress p ON p.user_id = u.id
                  WHERE p.last_activity_date >= CURRENT_DATE - 1) AS active_1d,
                (SELECT COUNT(*)::int FROM users u JOIN user_progress p ON p.user_id = u.id
                  WHERE p.last_activity_date >= CURRENT_DATE - 7) AS active_7d,
                (SELECT COUNT(*)::int FROM users u JOIN user_progress p ON p.user_id = u.id
                  WHERE p.last_activity_date >= CURRENT_DATE - 30) AS active_30d,
                COALESCE((SELECT json_agg(g ORDER BY g.week_start) FROM (
                  SELECT to_char(w.week_start, 'MM-DD') AS week,
                         to_char(w.week_start, 'YYYY-MM-DD') AS week_start,
                         COUNT(u.id)::int AS signups
                  FROM generate_series(
                         date_trunc('week', (NOW() AT TIME ZONE 'Africa/Johannesburg')::date - INTERVAL '11 weeks'),
                         date_trunc('week', (NOW() AT TIME ZONE 'Africa/Johannesburg')::date),
                         INTERVAL '1 week'
                       ) AS w(week_start)
                  LEFT JOIN users u ON date_trunc('week', u.created_at) = w.week_start
                  GROUP BY w.week_start
                ) g), '[]'::json) AS weekly_signups`
      ),
      // Attempts per day (last 30 days), passed/failed split.
      pool.query(
        `SELECT (NOW() AT TIME ZONE 'Africa/Johannesburg')::date - d.day AS day,
                COUNT(ta.id)::int AS attempts,
                COUNT(ta.id) FILTER (WHERE ta.passed)::int AS passed,
                COALESCE(ROUND(AVG(ta.score)), 0)::int AS avg_score
         FROM generate_series(0, 29) AS d(day)
         LEFT JOIN task_attempts ta
           ON (ta.submitted_at AT TIME ZONE 'Africa/Johannesburg')::date
              = (NOW() AT TIME ZONE 'Africa/Johannesburg')::date - d.day
         GROUP BY d.day ORDER BY d.day`
      ),
      // Per-feature: attempts, avg score, pass rate.
      pool.query(
        `SELECT t.feature, COUNT(ta.id)::int AS attempts,
                COALESCE(ROUND(AVG(ta.score)), 0)::int AS avg_score,
                COALESCE(ROUND(100.0 * COUNT(ta.id) FILTER (WHERE ta.passed) / NULLIF(COUNT(ta.id), 0)), 0)::int AS pass_rate,
                COUNT(DISTINCT ta.user_id)::int AS users
         FROM tasks t JOIN task_attempts ta ON ta.task_id = t.id AND ta.practice = FALSE
         GROUP BY t.feature ORDER BY attempts DESC`
      ),
      pool.query(
        `SELECT (SELECT COUNT(*)::int FROM workshop_posts) AS posts,
                (SELECT COUNT(*)::int FROM workshop_posts WHERE created_at >= CURRENT_DATE - 7) AS posts_7d,
                (SELECT COUNT(*)::int FROM workshop_posts WHERE hidden) AS hidden,
                (SELECT COUNT(*)::int FROM workshop_reports) AS reports_total,
                (SELECT COUNT(*)::int FROM workshop_posts p
                  WHERE EXISTS (SELECT 1 FROM workshop_reports wr WHERE wr.post_id = p.id)) AS posts_with_reports`
      ),
      // Token economy: issued vs spent (redemptions), from the append-only
      // reward_token_events ledger; outstanding balance from user_progress.
      pool.query(
        `SELECT
           COALESCE(SUM(e.delta) FILTER (WHERE e.delta > 0), 0)::int AS issued,
           COALESCE(-SUM(e.delta) FILTER (WHERE e.delta < 0), 0)::int AS spent,
           COALESCE(SUM(e.delta) FILTER (WHERE e.reason = 'adjustment'), 0)::int AS admin_adjusted,
           (SELECT COALESCE(SUM(tokens), 0)::int FROM user_progress) AS outstanding_balance
         FROM reward_token_events e`
      ),
      pool.query(
        `SELECT action, COUNT(*)::int AS count FROM moderation_events
         WHERE created_at >= CURRENT_DATE - 30 GROUP BY action ORDER BY count DESC`
      ),
      pool.query(
        `SELECT
           (SELECT COUNT(*)::int FROM assistant_sessions WHERE started_at >= CURRENT_DATE - 30) AS assistant_30d,
           (SELECT COUNT(*)::int FROM vera_sessions WHERE started_at >= CURRENT_DATE - 30) AS vera_30d,
           (SELECT COUNT(*)::int FROM verification_analyses WHERE created_at >= CURRENT_DATE - 30) AS verification_30d`
      ),
    ]);

    return res.status(200).json({
      users: growth.rows[0],
      activity: activity.rows,
      features: features.rows,
      workshop: workshop.rows[0],
      tokens: tokens.rows[0],
      moderation_30d: moderation.rows,
      llm_30d: llm.rows[0],
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// GET /api/admin/tasks/:id/answers — per-task answer drill-down: every answer
// for the task plus right/wrong totals and, per task_options row, how many
// learners picked it (with the option's score so the UI can mark the correct
// choice).
// ---------------------------------------------------------------------------
async function getTaskAnswers(req, res, next) {
  try {
    const taskId = Number.parseInt(req.params.id, 10);
    if (!Number.isInteger(taskId)) {
      return res.status(400).json({ error: 'Task id must be an integer.', request_id: req.requestId });
    }

    const task = await pool.query(
      `SELECT t.id, t.feature, t.published, tr.name AS track_name
       FROM tasks t JOIN industry_tracks tr ON tr.id = t.track_id WHERE t.id = $1`,
      [taskId]
    );
    if (!task.rows.length) {
      return res.status(404).json({ error: 'Task not found.', request_id: req.requestId });
    }

    const [stats, options, answers] = await Promise.all([
      pool.query(
        `SELECT COUNT(*)::int AS total,
                COUNT(*) FILTER (WHERE NOT al.practice)::int AS graded,
                COUNT(*) FILTER (WHERE al.practice)::int AS practice,
                COUNT(*) FILTER (WHERE NOT al.practice AND al.passed)::int AS right,
                COUNT(*) FILTER (WHERE NOT al.practice AND NOT al.passed)::int AS wrong,
                COALESCE(ROUND(AVG(al.score) FILTER (WHERE NOT al.practice)), 0)::int AS avg_score
         FROM answer_logs al WHERE al.task_id = $1`,
        [taskId]
      ),
      pool.query(
        `SELECT o.id, o.kind, o.label, o.score, o.sort_order,
                (SELECT COUNT(*)::int FROM task_attempts ta
                  WHERE ta.task_id = o.task_id AND ta.practice = FALSE AND
                        (ta.answer_option_id = o.id OR ta.decision_option_id = o.id OR ta.reason_option_id = o.id)) AS picked
         FROM task_options o
         WHERE o.task_id = $1
         ORDER BY o.kind, o.sort_order`,
        [taskId]
      ),
      pool.query(
        `SELECT al.id, al.score, al.passed, al.practice, al.answer_summary, al.submitted_at,
                u.email AS user_email, u.display_name AS user_name
         FROM answer_logs al
         LEFT JOIN users u ON u.id = al.user_id
         WHERE al.task_id = $1
         ORDER BY al.submitted_at DESC
         LIMIT 200`,
        [taskId]
      ),
    ]);

    return res.status(200).json({
      task: task.rows[0],
      stats: stats.rows[0],
      options: options.rows,
      answers: answers.rows,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  getOverview, listTasks, createTask, deleteTask,
  listUsers, getUser, setUserStatus, listModeration, trackProgress,
  getTaskDetail, updateTask, importTasks, getTaskAnswers,
  listApprovals, reviewTask, answerSummary, listAnswers, getAnalytics,
  listLab, getLabLesson, updateLabSection,
  listWorkshopPosts, listWorkshopReports, moderateWorkshopPost,
  grantAdjust, exportUserData, hardDeleteUser, setFirebaseDisabled,
  getSystem, getConfigValues, updateConfigValues, listAdmins, addAdmin, removeAdmin,
  exportUsersCsv, exportAttemptsCsv, exportTracksCsv,
};
