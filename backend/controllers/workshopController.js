const pool = require('../db/pool');
const { requiredString, optionalString, positiveIntegerParam, clampInt } = require('../middleware/validate');

// A post is auto-hidden once this many distinct users report it, pending review.
const HIDE_AFTER_REPORTS = 3;
const REPORT_REASONS = new Set(['spam', 'abuse', 'off_topic', 'other']);

async function resolveLessonId(executor, code, trackId) {
  if (!code) return null;
  const result = await executor.query(
    `SELECT id FROM lab_lessons WHERE code = $1 AND (track_id IS NULL OR track_id = $2)`,
    [code, trackId],
  );
  return result.rows[0]?.id ?? null;
}

// GET /api/workshop/posts?lesson=<code>&limit=&offset=
async function listPosts(req, res, next) {
  try {
    const user = req.user;
    if (!user.industry_track_id) {
      return res.status(400).json({ error: 'Select an industry track before using the Workshop.', request_id: req.requestId });
    }

    const limit = clampInt(req.query.limit, 20, 1, 50);
    const offset = clampInt(req.query.offset, 0, 0, 100000);
    const lessonCode = optionalString(req.query.lesson, 'lesson', 120);

    const params = [user.id, user.industry_track_id];
    let lessonFilter = '';
    if (lessonCode) {
      const lessonId = await resolveLessonId(pool, lessonCode, user.industry_track_id);
      if (!lessonId) {
        return res.status(404).json({ error: 'Lesson not found for your selected track.', request_id: req.requestId });
      }
      params.push(lessonId);
      lessonFilter = ` AND p.lesson_id = $${params.length}`;
    }

    params.push(limit, offset);
    const result = await pool.query(
      `SELECT p.id, p.parent_id, p.lesson_id, p.body, p.created_at, p.edited_at,
              p.author_id, u.display_name AS author_name,
              (p.author_id = $1) AS is_mine,
              (SELECT COUNT(*)::int FROM workshop_posts r WHERE r.parent_id = p.id AND r.hidden = FALSE) AS reply_count,
              (SELECT COUNT(*)::int FROM workshop_reactions rx WHERE rx.post_id = p.id) AS reaction_count,
              EXISTS (SELECT 1 FROM workshop_reactions rx WHERE rx.post_id = p.id AND rx.user_id = $1) AS reacted
       FROM workshop_posts p
       JOIN users u ON u.id = p.author_id
       WHERE p.track_id = $2 AND p.hidden = FALSE AND p.parent_id IS NULL${lessonFilter}
       ORDER BY p.created_at DESC, p.id DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params,
    );

    return res.status(200).json({ posts: result.rows, limit, offset, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// GET /api/workshop/posts/:id/replies
async function listReplies(req, res, next) {
  try {
    const user = req.user;

    const postId = positiveIntegerParam(req.params.id, 'post id');
    const parent = await pool.query(
      `SELECT id FROM workshop_posts WHERE id = $1 AND track_id = $2 AND hidden = FALSE`,
      [postId, user.industry_track_id],
    );
    if (!parent.rows.length) {
      return res.status(404).json({ error: 'Post not found.', request_id: req.requestId });
    }

    const result = await pool.query(
      `SELECT p.id, p.parent_id, p.body, p.created_at, p.edited_at,
              p.author_id, u.display_name AS author_name,
              (p.author_id = $1) AS is_mine,
              (SELECT COUNT(*)::int FROM workshop_reactions rx WHERE rx.post_id = p.id) AS reaction_count,
              EXISTS (SELECT 1 FROM workshop_reactions rx WHERE rx.post_id = p.id AND rx.user_id = $1) AS reacted
       FROM workshop_posts p
       JOIN users u ON u.id = p.author_id
       WHERE p.parent_id = $2 AND p.hidden = FALSE
       ORDER BY p.created_at ASC, p.id ASC`,
      [user.id, postId],
    );

    return res.status(200).json({ replies: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// POST /api/workshop/posts  { body, lesson_code?, parent_id? }
async function createPost(req, res, next) {
  try {
    const user = req.user;
    if (!user.industry_track_id) {
      return res.status(400).json({ error: 'Select an industry track before using the Workshop.', request_id: req.requestId });
    }

    const body = requiredString(req.body.body, 'body', 2000);
    const lessonCode = optionalString(req.body.lesson_code, 'lesson_code', 120);
    let parentId = null;
    if (req.body.parent_id !== undefined && req.body.parent_id !== null) {
      parentId = positiveIntegerParam(req.body.parent_id, 'parent_id');
      const parent = await pool.query(
        `SELECT id FROM workshop_posts WHERE id = $1 AND track_id = $2 AND hidden = FALSE`,
        [parentId, user.industry_track_id],
      );
      if (!parent.rows.length) {
        return res.status(404).json({ error: 'The post you are replying to was not found.', request_id: req.requestId });
      }
    }

    const lessonId = await resolveLessonId(pool, lessonCode, user.industry_track_id);
    if (lessonCode && !lessonId) {
      return res.status(404).json({ error: 'Lesson not found for your selected track.', request_id: req.requestId });
    }

    const result = await pool.query(
      `INSERT INTO workshop_posts (track_id, lesson_id, author_id, parent_id, body)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, parent_id, lesson_id, body, created_at`,
      [user.industry_track_id, lessonId, user.id, parentId, body],
    );

    return res.status(201).json({ post: result.rows[0], request_id: req.requestId });
  } catch (err) {
    if (err && err.status === 400) {
      return res.status(400).json({ error: err.message, request_id: req.requestId });
    }
    return next(err);
  }
}

// POST /api/workshop/posts/:id/react — toggle an upvote
async function react(req, res, next) {
  let client = null;
  try {
    const user = req.user;

    const postId = positiveIntegerParam(req.params.id, 'post id');
    client = await pool.connect();
    await client.query('BEGIN');

    const post = await client.query(
      `SELECT id FROM workshop_posts WHERE id = $1 AND track_id = $2 AND hidden = FALSE`,
      [postId, user.industry_track_id],
    );
    if (!post.rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Post not found.', request_id: req.requestId });
    }

    const existing = await client.query(
      `SELECT 1 FROM workshop_reactions WHERE post_id = $1 AND user_id = $2 AND kind = 'upvote'`,
      [postId, user.id],
    );

    let reacted;
    if (existing.rows.length) {
      await client.query(
        `DELETE FROM workshop_reactions WHERE post_id = $1 AND user_id = $2 AND kind = 'upvote'`,
        [postId, user.id],
      );
      reacted = false;
    } else {
      await client.query(
        `INSERT INTO workshop_reactions (post_id, user_id, kind) VALUES ($1, $2, 'upvote')
         ON CONFLICT DO NOTHING`,
        [postId, user.id],
      );
      reacted = true;
    }

    const count = await client.query(
      `SELECT COUNT(*)::int AS n FROM workshop_reactions WHERE post_id = $1`,
      [postId],
    );
    await client.query('COMMIT');

    return res.status(200).json({ reacted, reaction_count: count.rows[0].n, request_id: req.requestId });
  } catch (err) {
    if (client) await client.query('ROLLBACK').catch(() => {});
    return next(err);
  } finally {
    if (client) client.release();
  }
}

// POST /api/workshop/posts/:id/report  { reason }
async function report(req, res, next) {
  let client = null;
  try {
    const user = req.user;

    const postId = positiveIntegerParam(req.params.id, 'post id');
    const reason = requiredString(req.body.reason, 'reason', 40).toLowerCase();
    if (!REPORT_REASONS.has(reason)) {
      return res.status(400).json({
        error: 'reason must be one of spam, abuse, off_topic, other.',
        request_id: req.requestId,
      });
    }

    client = await pool.connect();
    await client.query('BEGIN');

    const post = await client.query(
      `SELECT id, author_id FROM workshop_posts WHERE id = $1 AND track_id = $2 AND hidden = FALSE`,
      [postId, user.industry_track_id],
    );
    if (!post.rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Post not found.', request_id: req.requestId });
    }
    if (Number(post.rows[0].author_id) === Number(user.id)) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'You cannot report your own post.', request_id: req.requestId });
    }

    const inserted = await client.query(
      `INSERT INTO workshop_reports (post_id, reporter_id, reason)
       VALUES ($1, $2, $3) ON CONFLICT (post_id, reporter_id) DO NOTHING
       RETURNING id`,
      [postId, user.id, reason],
    );

    let hidden = false;
    if (inserted.rows.length) {
      const reports = await client.query(
        `SELECT COUNT(*)::int AS n FROM workshop_reports WHERE post_id = $1`,
        [postId],
      );
      if (reports.rows[0].n >= HIDE_AFTER_REPORTS) {
        await client.query(`UPDATE workshop_posts SET hidden = TRUE WHERE id = $1`, [postId]);
        hidden = true;
      }
    }
    await client.query('COMMIT');

    return res.status(200).json({ reported: true, hidden, request_id: req.requestId });
  } catch (err) {
    if (client) await client.query('ROLLBACK').catch(() => {});
    return next(err);
  } finally {
    if (client) client.release();
  }
}

// DELETE /api/workshop/posts/:id — author only
async function deletePost(req, res, next) {
  try {
    const user = req.user;

    const postId = positiveIntegerParam(req.params.id, 'post id');
    const existing = await pool.query(
      `SELECT author_id FROM workshop_posts WHERE id = $1 AND track_id = $2`,
      [postId, user.industry_track_id],
    );
    if (!existing.rows.length) {
      return res.status(404).json({ error: 'Post not found.', request_id: req.requestId });
    }
    if (Number(existing.rows[0].author_id) !== Number(user.id)) {
      return res.status(403).json({ error: 'You can only delete your own posts.', request_id: req.requestId });
    }

    await pool.query(`DELETE FROM workshop_posts WHERE id = $1`, [postId]);
    return res.status(200).json({ deleted: true, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

module.exports = { listPosts, listReplies, createPost, react, report, deletePost };
