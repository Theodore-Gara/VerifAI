-- 037 — Native admin portal: support replies, read tracking, admin flag.
--
-- Idempotent. Mirrors the relevant blocks in db/schema.sql so a fresh database
-- built from schema.sql and an upgraded database via migrations end up equal.

-- 1. Admin accounts are flagged on the user row so learner-facing queries can
--    exclude them without consulting the admin registry (or Firebase claims) on
--    every request. authController refreshes this on /auth/sync and /auth/me.
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT FALSE;

-- Backfill accounts that already have a registry row. Environment-listed admins
-- are picked up the next time they call /auth/sync or /auth/me.
UPDATE users u
   SET is_admin = TRUE
  FROM admin_accounts a
 WHERE lower(a.email) = lower(u.email);

CREATE INDEX IF NOT EXISTS idx_users_not_admin
  ON users (id) WHERE is_admin = FALSE;

-- 2. Ticket conversation + read state.
ALTER TABLE support_messages
  ADD COLUMN IF NOT EXISTS last_reply_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS user_last_read_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS admin_last_read_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS support_message_replies (
  id SERIAL PRIMARY KEY,
  message_id INTEGER NOT NULL REFERENCES support_messages(id) ON DELETE CASCADE,
  author_type VARCHAR(10) NOT NULL CHECK (author_type IN ('admin', 'user', 'system')),
  author_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  author_email VARCHAR(255),
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_support_replies_message
  ON support_message_replies (message_id, created_at, id);

-- 3. Audit vocabulary for the new actions. Keep every existing value.
ALTER TABLE moderation_events DROP CONSTRAINT IF EXISTS moderation_events_action_check;

ALTER TABLE moderation_events
  ADD CONSTRAINT moderation_events_action_check CHECK (action IN (
    'suspend', 'ban', 'activate',
    'task_create', 'task_update', 'task_delete', 'task_import', 'task_publish',
    'task_approve', 'task_reject',
    'user_grant', 'user_export', 'user_delete', 'user_firebase', 'user_update',
    'workshop_delete', 'workshop_hide',
    'lab_update',
    'config_update',
    'admin_add', 'admin_remove',
    'support_content_update', 'support_message_update', 'support_reply'
  ));
