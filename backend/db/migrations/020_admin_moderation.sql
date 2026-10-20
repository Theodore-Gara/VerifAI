-- 020 — Admin moderation: user account status + moderation audit trail.
--
-- `status`: 'active' is the default; 'suspended' is temporary (reversible),
-- 'banned' is permanent. Status is enforced by the auth middleware on every
-- protected route; auth/sync also refuses to (re)create a non-active account.
-- `moderation_events` records every admin action for audit purposes.

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'suspended', 'banned')),
  ADD COLUMN IF NOT EXISTS status_reason TEXT,
  ADD COLUMN IF NOT EXISTS status_updated_at TIMESTAMP;

CREATE TABLE IF NOT EXISTS moderation_events (
  id SERIAL PRIMARY KEY,
  admin_email VARCHAR(255) NOT NULL,
  target_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  target_email VARCHAR(255),
  action VARCHAR(30) NOT NULL CHECK (action IN ('suspend', 'ban', 'activate', 'task_create', 'task_delete')),
  reason TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_moderation_events_target
  ON moderation_events (target_user_id, created_at DESC);
