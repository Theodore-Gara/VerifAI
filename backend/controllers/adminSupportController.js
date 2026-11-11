// Admin support console API: correct help content, work the contact inbox and
// read support analytics. Role gates are applied in routes/admin.js
// (moderator reads, admin writes). Every content edit and ticket status change
// is written to the moderation audit trail with the actor, the target and a
// summary of what changed.
const pool = require('../db/pool');
const { logModeration } = require('./adminController');
const { clampInt } = require('../middleware/validate');
const { invalidateSupportCache } = require('../services/supportContent');
const {
  HELP_CATEGORIES, FAQ_TOPICS, MESSAGE_STATUSES, CONTACT_CATEGORIES,
} = require('../services/supportLimits');

function fail(req, res, status, code, message) {
  return res.status(status).json({ error: message, code, request_id: req.requestId });
}

// Field definitions for the two editable content types. Each validator returns
// the cleaned value, or throws a string message. Slugs are immutable on purpose:
// deep links and analytics refer to them.
const str = (field, max, min = 1) => (v) => {
  if (typeof v !== 'string') throw `${field} must be a string.`;
  const t = v.replace(/\u0000/g, '').trim();
  if (t.length < min || t.length > max) throw `${field} must be ${min} to ${max} characters.`;
  return t;
};
const oneOf = (field, allowed) => (v) => {
  if (!allowed.includes(v)) throw `${field} must be one of: ${allowed.join(', ')}.`;
  return v;
};
const bool = (field) => (v) => {
  if (typeof v !== 'boolean') throw `${field} must be true or false.`;
  return v;
};
const int = (field, min, max) => (v) => {
  if (!Number.isInteger(v) || v < min || v > max) throw `${field} must be an integer from ${min} to ${max}.`;
  return v;
};

const HELP_FIELDS = {
  title: str('title', 200),
  summary: str('summary', 1000),
  body_md: str('body_md', 30000),
  category: oneOf('category', HELP_CATEGORIES),
  sort_order: int('sort_order', 0, 10000),
  published: bool('published'),
};
const FAQ_FIELDS = {
  question: str('question', 500),
  answer_md: str('answer_md', 15000),
  topic: oneOf('topic', FAQ_TOPICS),
  sort_order: int('sort_order', 0, 10000),
  published: bool('published'),
};

const LONG_TEXT = new Set(['body_md', 'answer_md', 'summary', 'question']);

function parseChanges(body, fields) {
  const changes = {};
  for (const [key, validate] of Object.entries(fields)) {
    if (body[key] === undefined) continue;
    try {
      changes[key] = validate(body[key]);
    } catch (message) {
      const error = new Error(String(message));
      error.status = 400;
      error.code = 'invalid_field';
      throw error;
    }
  }
  return changes;
}

// "published true→false; body_md 1204→1330 chars" — what changed, without
// copying the new text into the audit log.
function diffSummary(before, changes) {
  const parts = [];
  for (const [key, next] of Object.entries(changes)) {
    const prev = before[key];
    if (prev === next) continue;
    if (LONG_TEXT.has(key)) parts.push(`${key} ${String(prev).length}→${next.length} chars`);
    else parts.push(`${key} ${prev}→${next}`);
  }
  return parts;
}

function sendValidation(req, res, err) {
  if (err && err.status === 400) return fail(req, res, 400, err.code || 'invalid_field', err.message);
  return null;
}

// ---------------------------------------------------------------------------
// Help articles and FAQs (same shape, so one implementation)
// ---------------------------------------------------------------------------
function contentHandlers({ table, label, fields, listColumns, filterColumn, auditNoun }) {
  async function list(req, res, next) {
    try {
      const where = [];
      const values = [];
      if (req.query.published === 'true' || req.query.published === 'false') {
        values.push(req.query.published === 'true');
        where.push(`published = $${values.length}`);
      }
      if (typeof req.query[filterColumn] === 'string' && req.query[filterColumn].trim()) {
        values.push(req.query[filterColumn].trim().toLowerCase());
        where.push(`${filterColumn} = $${values.length}`);
      }
      const result = await pool.query(
        `SELECT ${listColumns} FROM ${table}
          ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
          ORDER BY sort_order, id`,
        values,
      );
      return res.status(200).json({ [label]: result.rows, request_id: req.requestId });
    } catch (err) {
      return next(err);
    }
  }

  async function update(req, res, next) {
    try {
      const id = Number(req.params.id);
      const changes = parseChanges(req.body || {}, fields);
      if (!Object.keys(changes).length) {
        return fail(req, res, 400, 'no_changes', 'Provide at least one editable field.');
      }

      const current = await pool.query(`SELECT ${listColumns} FROM ${table} WHERE id = $1`, [id]);
      if (!current.rows.length) return fail(req, res, 404, 'not_found', 'Content not found.');
      const before = current.rows[0];

      const summary = diffSummary(before, changes);
      if (!summary.length) {
        // Nothing differs: do not touch updated_at (it is the content version).
        return res.status(200).json({ [auditNoun]: before, changed: [], request_id: req.requestId });
      }

      const keys = Object.keys(changes);
      const sets = keys.map((k, i) => `${k} = $${i + 1}`);
      const updated = await pool.query(
        `UPDATE ${table} SET ${sets.join(', ')}, updated_at = now()
          WHERE id = $${keys.length + 1}
          RETURNING ${listColumns}`,
        [...keys.map((k) => changes[k]), id],
      );

      // Publishing or editing is visible on the public read API immediately.
      invalidateSupportCache();

      await logModeration(req.firebaseUser, {
        action: 'support_content_update',
        reason: `${before.slug ? `${auditNoun} #${id} (${before.slug})` : `${auditNoun} #${id}`}: ${summary.join('; ')}`,
      });

      return res.status(200).json({ [auditNoun]: updated.rows[0], changed: summary, request_id: req.requestId });
    } catch (err) {
      if (sendValidation(req, res, err)) return undefined;
      return next(err);
    }
  }

  return { list, update };
}

const help = contentHandlers({
  table: 'help_articles', label: 'articles', auditNoun: 'article', filterColumn: 'category',
  fields: HELP_FIELDS,
  listColumns: 'id, slug, title, summary, body_md, category, audience, sort_order, published, updated_at',
});

const faqs = contentHandlers({
  table: 'faqs', label: 'faqs', auditNoun: 'faq', filterColumn: 'topic',
  fields: FAQ_FIELDS,
  listColumns: 'id, slug, question, answer_md, topic, sort_order, published, updated_at',
});

// ---------------------------------------------------------------------------
// Contact inbox
// ---------------------------------------------------------------------------
const MESSAGE_COLUMNS = `id, public_ref, user_id, name, email, subject, message, category, app_version,
       status, internal_note, resolved_at, last_reply_at, user_last_read_at, admin_last_read_at,
       created_at, updated_at`;

async function listMessages(req, res, next) {
  try {
    const where = [];
    const values = [];
    if (typeof req.query.status === 'string' && req.query.status) {
      if (!MESSAGE_STATUSES.includes(req.query.status)) {
        return fail(req, res, 400, 'invalid_status', `status must be one of: ${MESSAGE_STATUSES.join(', ')}.`);
      }
      values.push(req.query.status);
      where.push(`status = $${values.length}`);
    }
    if (typeof req.query.category === 'string' && req.query.category) {
      if (!CONTACT_CATEGORIES.includes(req.query.category)) {
        return fail(req, res, 400, 'invalid_category', `category must be one of: ${CONTACT_CATEGORIES.join(', ')}.`);
      }
      values.push(req.query.category);
      where.push(`category = $${values.length}`);
    }
    const limit = clampInt(req.query.limit, 50, 1, 200);
    const offset = clampInt(req.query.offset, 0, 0, 1000000);
    const clause = where.length ? `WHERE ${where.join(' AND ')}` : '';

    const [rows, total] = await Promise.all([
      pool.query(
        `SELECT ${MESSAGE_COLUMNS},
                (SELECT COUNT(*)::int FROM support_message_replies r
                  WHERE r.message_id = support_messages.id) AS reply_count,
                (status = 'new' OR EXISTS (
                  SELECT 1 FROM support_message_replies r
                   WHERE r.message_id = support_messages.id
                     AND r.author_type = 'user'
                     AND r.created_at > COALESCE(admin_last_read_at, 'epoch'::timestamptz)
                )) AS unread
           FROM support_messages ${clause}
          ORDER BY created_at DESC, id DESC
          LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
        [...values, limit, offset],
      ),
      pool.query(`SELECT COUNT(*)::int AS count FROM support_messages ${clause}`, values),
    ]);
    return res.status(200).json({
      messages: rows.rows,
      total: total.rows[0] ? total.rows[0].count : rows.rows.length,
      limit,
      offset,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

async function updateMessage(req, res, next) {
  try {
    const id = Number(req.params.id);
    const body = req.body || {};
    const sets = [];
    const values = [];

    if (body.status !== undefined) {
      if (!MESSAGE_STATUSES.includes(body.status)) {
        return fail(req, res, 400, 'invalid_status', `status must be one of: ${MESSAGE_STATUSES.join(', ')}.`);
      }
    }
    let note;
    if (body.internal_note !== undefined) {
      if (body.internal_note !== null && typeof body.internal_note !== 'string') {
        return fail(req, res, 400, 'invalid_note', 'internal_note must be text or null.');
      }
      note = body.internal_note === null ? null : body.internal_note.replace(/\u0000/g, '').trim();
      if (note !== null && note.length > 2000) {
        return fail(req, res, 400, 'invalid_note', 'internal_note must be 2000 characters or fewer.');
      }
      if (note === '') note = null;
    }
    if (body.status === undefined && body.internal_note === undefined) {
      return fail(req, res, 400, 'no_changes', 'Provide status and/or internal_note.');
    }

    const current = await pool.query(`SELECT ${MESSAGE_COLUMNS} FROM support_messages WHERE id = $1`, [id]);
    if (!current.rows.length) return fail(req, res, 404, 'not_found', 'Message not found.');
    const before = current.rows[0];

    const summary = [];
    if (body.status !== undefined && body.status !== before.status) {
      values.push(body.status);
      sets.push(`status = $${values.length}`);
      // resolved_at drives the retention clock, so it follows the status.
      sets.push(body.status === 'resolved' ? 'resolved_at = now()' : 'resolved_at = NULL');
      summary.push(`status ${before.status}→${body.status}`);
    }
    if (body.internal_note !== undefined && note !== (before.internal_note ?? null)) {
      values.push(note);
      sets.push(`internal_note = $${values.length}`);
      summary.push('internal note updated');
    }
    if (!summary.length) {
      return res.status(200).json({ message: before, changed: [], request_id: req.requestId });
    }

    values.push(id);
    const updated = await pool.query(
      `UPDATE support_messages SET ${sets.join(', ')}, updated_at = now()
        WHERE id = $${values.length}
        RETURNING ${MESSAGE_COLUMNS}`,
      values,
    );

    // The reference and the change only: no email or message text in the audit.
    await logModeration(req.firebaseUser, {
      action: 'support_message_update',
      targetUserId: before.user_id || null,
      reason: `Support message ${before.public_ref}: ${summary.join('; ')}`,
    });

    return res.status(200).json({ message: updated.rows[0], changed: summary, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/admin/support/messages/:id — one ticket with its conversation.
async function getMessage(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
      return fail(req, res, 400, 'invalid_id', 'Ticket id must be a positive integer.');
    }
    const current = await pool.query(
      `SELECT ${MESSAGE_COLUMNS},
              (SELECT COUNT(*)::int FROM support_message_replies r
                WHERE r.message_id = support_messages.id) AS reply_count
         FROM support_messages WHERE id = $1`,
      [id],
    );
    if (!current.rows.length) return fail(req, res, 404, 'not_found', 'Message not found.');
    const replies = await pool.query(
      `SELECT id, message_id, author_type, author_user_id, author_email, body, created_at
         FROM support_message_replies WHERE message_id = $1
        ORDER BY created_at, id`,
      [id],
    );
    return res.status(200).json({
      message: current.rows[0],
      replies: replies.rows,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// POST /api/admin/support/messages/:id/replies — post the admin reply.
// Body: { body: string, resolve?: boolean }
async function replyToMessage(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
      return fail(req, res, 400, 'invalid_id', 'Ticket id must be a positive integer.');
    }
    const text = typeof req.body?.body === 'string'
      ? req.body.body.replace(/\u0000/g, '').trim()
      : '';
    if (text.length < 1 || text.length > 4000) {
      return fail(req, res, 400, 'invalid_body', 'Reply must be 1 to 4000 characters.');
    }

    const currentResult = await pool.query(
      `SELECT ${MESSAGE_COLUMNS} FROM support_messages WHERE id = $1`,
      [id],
    );
    if (!currentResult.rows.length) return fail(req, res, 404, 'not_found', 'Message not found.');
    const current = currentResult.rows[0];

    const admin = await pool.query(
      `SELECT id, email, display_name FROM users WHERE firebase_uid = $1`,
      [req.firebaseUser.uid],
    );
    const adminRow = admin.rows[0] || null;

    const resolve = req.body?.resolve === true;
    const status = resolve
      ? 'resolved'
      : (current.status === 'new' || current.status === 'resolved')
        ? 'in_progress'
        : current.status;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const inserted = await client.query(
        `INSERT INTO support_message_replies
           (message_id, author_type, author_user_id, author_email, body)
         VALUES ($1, 'admin', $2, $3, $4)
         RETURNING id, message_id, author_type, author_user_id, author_email, body, created_at`,
        [id, adminRow ? adminRow.id : null, adminRow ? adminRow.email : (req.firebaseUser.email || null), text],
      );
      const updated = await client.query(
        `UPDATE support_messages
            SET status = $2,
                resolved_at = CASE WHEN $2 = 'resolved' THEN now() ELSE NULL END,
                last_reply_at = now(),
                admin_last_read_at = now(),
                updated_at = now()
          WHERE id = $1
          RETURNING ${MESSAGE_COLUMNS}`,
        [id, status],
      );
      await client.query('COMMIT');

      await logModeration(req.firebaseUser, {
        action: 'support_reply',
        targetUserId: current.user_id || null,
        reason: `Support message ${current.public_ref}: admin reply${resolve ? ' (resolved)' : ''}`,
      });

      return res.status(201).json({
        message: updated.rows[0],
        reply: inserted.rows[0],
        request_id: req.requestId,
      });
    } catch (err) {
      await client.query('ROLLBACK').catch(() => {});
      throw err;
    } finally {
      client.release();
    }
  } catch (err) {
    return next(err);
  }
}

// POST /api/admin/support/messages/:id/read — clear the admin unread badge.
async function markMessageRead(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
      return fail(req, res, 400, 'invalid_id', 'Ticket id must be a positive integer.');
    }
    const updated = await pool.query(
      `UPDATE support_messages SET admin_last_read_at = now() WHERE id = $1
       RETURNING id, admin_last_read_at`,
      [id],
    );
    if (!updated.rows.length) return fail(req, res, 404, 'not_found', 'Message not found.');
    return res.status(200).json({ message: updated.rows[0], request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/admin/support/unread-count — badge count for the native portal.
async function getUnreadCount(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT COUNT(*)::int AS count FROM support_messages sm
        WHERE sm.status = 'new' OR EXISTS (
          SELECT 1 FROM support_message_replies r
           WHERE r.message_id = sm.id AND r.author_type = 'user'
             AND r.created_at > COALESCE(sm.admin_last_read_at, 'epoch'::timestamptz)
        )`,
    );
    return res.status(200).json({ count: result.rows[0]?.count || 0, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// GET /api/admin/support/insights?days=30
// All queries filter on created_at >= $1, which the (created_at) and
// (event, created_at) indexes serve, so a 30-day window is a range scan.
// ---------------------------------------------------------------------------
async function getInsights(req, res, next) {
  try {
    const days = clampInt(req.query.days, 30, 1, 365);
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    const [articles, faqTopics, faqs, searches, tours, contact, funnel] = await Promise.all([
      pool.query(
        `SELECT target AS slug, COUNT(*)::int AS views
           FROM support_events
          WHERE event = 'article_view' AND created_at >= $1 AND target IS NOT NULL
          GROUP BY target ORDER BY views DESC, target LIMIT 10`, [since]),
      pool.query(
        `SELECT COALESCE(metadata->>'topic', 'unknown') AS topic, COUNT(*)::int AS expands
           FROM support_events
          WHERE event = 'faq_expand' AND created_at >= $1
          GROUP BY 1 ORDER BY expands DESC, topic LIMIT 10`, [since]),
      pool.query(
        `SELECT target AS slug, COUNT(*)::int AS expands
           FROM support_events
          WHERE event = 'faq_expand' AND created_at >= $1 AND target IS NOT NULL
          GROUP BY target ORDER BY expands DESC, target LIMIT 10`, [since]),
      pool.query(
        `SELECT COUNT(*)::int AS total,
                COUNT(*) FILTER (WHERE (metadata->>'result_count') = '0')::int AS no_result
           FROM support_events
          WHERE event = 'faq_search' AND created_at >= $1`, [since]),
      pool.query(
        `SELECT target AS tour_key,
                COUNT(*) FILTER (WHERE event = 'tour_start')::int AS starts,
                COUNT(*) FILTER (WHERE event = 'tour_complete')::int AS completes,
                COUNT(*) FILTER (WHERE event = 'tour_skip')::int AS skips
           FROM support_events
          WHERE event IN ('tour_start', 'tour_complete', 'tour_skip')
            AND created_at >= $1 AND target IS NOT NULL
          GROUP BY target ORDER BY starts DESC, target`, [since]),
      pool.query(
        `SELECT category, COUNT(*)::int AS messages
           FROM support_messages
          WHERE created_at >= $1
          GROUP BY category ORDER BY messages DESC, category`, [since]),
      pool.query(
        `SELECT COUNT(*) FILTER (WHERE event = 'contact_open')::int AS opens,
                COUNT(*) FILTER (WHERE event = 'contact_submit')::int AS submits
           FROM support_events
          WHERE event IN ('contact_open', 'contact_submit') AND created_at >= $1`, [since]),
    ]);

    const search = searches.rows[0] || { total: 0, no_result: 0 };
    const tourRows = tours.rows.map((t) => ({
      ...t,
      skip_rate: t.starts > 0 ? Math.round((t.skips / t.starts) * 1000) / 1000 : null,
    }));
    const contactRows = contact.rows;

    return res.status(200).json({
      days,
      since: since.toISOString(),
      top_articles: articles.rows,
      top_faq_topics: faqTopics.rows,
      top_faqs: faqs.rows,
      // The text people searched for is intentionally not stored (privacy), so
      // this reports how often a search found nothing, not which words.
      searches: {
        total: search.total,
        no_result: search.no_result,
        no_result_rate: search.total > 0 ? Math.round((search.no_result / search.total) * 1000) / 1000 : null,
      },
      tours: tourRows,
      contact: {
        total: contactRows.reduce((sum, r) => sum + r.messages, 0),
        by_category: contactRows,
        opens: funnel.rows[0] ? funnel.rows[0].opens : 0,
        submits: funnel.rows[0] ? funnel.rows[0].submits : 0,
      },
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listHelp: help.list,
  updateHelp: help.update,
  listFaqs: faqs.list,
  updateFaq: faqs.update,
  listMessages,
  updateMessage,
  getMessage,
  replyToMessage,
  markMessageRead,
  getUnreadCount,
  getInsights,
  // for tests
  diffSummary,
};
