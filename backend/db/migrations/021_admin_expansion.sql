-- 021 — Admin expansion: task publish state, platform config, admin roles.
--
-- `tasks.published`: draft tasks stay hidden from the learner app until an
-- admin publishes them. Defaults to TRUE so existing/seeded rows stay live.
--
-- `app_config`: runtime key/value store for maintenance mode and feature
-- flags, changeable from the dashboard without a redeploy.
--
-- `admin_accounts`: role registry for panel users. The ADMIN_EMAILS allowlist
-- still grants baseline admin access; a row here can upgrade the role
-- ('admin' -> 'super') or define a moderator. Roles:
--   super  — everything, incl. managing admins and destructive actions
--   admin  — everything except admin management
--   moderator — users, workshop and audit log only (read-mostly + moderation)

ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS published BOOLEAN NOT NULL DEFAULT TRUE;

CREATE TABLE IF NOT EXISTS app_config (
  key VARCHAR(80) PRIMARY KEY,
  value TEXT,
  updated_by VARCHAR(255),
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS admin_accounts (
  email VARCHAR(255) PRIMARY KEY,
  role VARCHAR(20) NOT NULL DEFAULT 'admin' CHECK (role IN ('super', 'admin', 'moderator')),
  added_by VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
