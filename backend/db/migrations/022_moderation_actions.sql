-- 022 — Widen the moderation_events.action vocabulary for the expanded admin
-- panel (task editing/import, workshop moderation, user data tools, config,
-- admin management).

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
    'admin_add', 'admin_remove'
  ));
