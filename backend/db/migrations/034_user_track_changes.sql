-- 034_user_track_changes.sql
--
-- Audit trail for industry switches (BF-5). A bare UPDATE of
-- users.industry_track_id left no record that the learner's context changed, so
-- every derived value could look stale with nothing to retrace. One row per
-- successful switch, written in the same transaction as the update.
--
-- Idempotent.

CREATE TABLE IF NOT EXISTS user_track_changes (
  id            SERIAL PRIMARY KEY,
  user_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  from_track_id INTEGER REFERENCES industry_tracks(id) ON DELETE SET NULL,
  to_track_id   INTEGER NOT NULL REFERENCES industry_tracks(id) ON DELETE CASCADE,
  changed_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_track_changes_user
  ON user_track_changes (user_id, changed_at DESC);
