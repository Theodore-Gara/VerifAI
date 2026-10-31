-- 033 — Contact intake, support analytics and audit vocabulary.
--
-- Privacy: both tables are wiped for an account on deletion (user_id cascades;
-- services/accountPurge.js also removes anonymous tickets that used the same
-- email) and pruned by scripts/prune-support.js.

CREATE TABLE IF NOT EXISTS support_messages (
  id SERIAL PRIMARY KEY,
  -- Public, non-sequential reference returned to the sender.
  public_ref VARCHAR(20) NOT NULL UNIQUE,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(254) NOT NULL,
  subject VARCHAR(150) NOT NULL,
  message TEXT NOT NULL,
  category VARCHAR(20) NOT NULL CHECK (category IN
    ('bug', 'account', 'content', 'verification', 'feedback', 'other')),
  app_version VARCHAR(40),
  status VARCHAR(20) NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'in_progress', 'resolved')),
  internal_note TEXT,
  request_id VARCHAR(64),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_support_messages_status ON support_messages (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_support_messages_category ON support_messages (category, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_support_messages_user ON support_messages (user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_support_messages_email ON support_messages (lower(email));
CREATE INDEX IF NOT EXISTS idx_support_messages_resolved ON support_messages (resolved_at) WHERE status = 'resolved';

CREATE TABLE IF NOT EXISTS support_events (
  id BIGSERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  event VARCHAR(30) NOT NULL CHECK (event IN (
    'help_open', 'article_view', 'faq_expand', 'faq_search',
    'tour_start', 'tour_complete', 'tour_skip',
    'contact_open', 'contact_submit')),
  target VARCHAR(80),
  -- Allowlisted keys, slugs/ids/counts only (see controllers/supportController.js).
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_support_events_created ON support_events (created_at);
CREATE INDEX IF NOT EXISTS idx_support_events_event ON support_events (event, created_at);
CREATE INDEX IF NOT EXISTS idx_support_events_user ON support_events (user_id) WHERE user_id IS NOT NULL;

-- Audit trail: the admin support console records content edits and ticket
-- status changes through moderation_events. Widen the action vocabulary
-- (same approach as 022). If another migration widens this list too, merge the
-- values rather than dropping either set.
ALTER TABLE moderation_events DROP CONSTRAINT IF EXISTS moderation_events_action_check;

ALTER TABLE moderation_events
  ADD CONSTRAINT moderation_events_action_check CHECK (action IN (
    'suspend', 'ban', 'activate',
    'task_create', 'task_update', 'task_delete', 'task_import', 'task_publish',
    'task_approve', 'task_reject',
    'user_grant', 'user_export', 'user_delete', 'user_firebase',
    'workshop_delete', 'workshop_hide',
    'lab_update',
    'config_update',
    'admin_add', 'admin_remove',
    'support_content_update', 'support_message_update'
  ));
