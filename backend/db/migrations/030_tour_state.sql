-- 030_tour_state.sql
--
-- Per-account tutorial state (BF-7). The tour used to live only in a
-- SharedPreferences key, so a reinstall or a second device forgot it, and a
-- skipped tour was never offered again. One row per (user, track, tour_key);
-- the roadmap's `tutorial_completed` milestone reads `status = 'completed'`.
--
-- Idempotent: safe to re-run on an existing database.

CREATE TABLE IF NOT EXISTS user_tutorials (
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  track_id   INTEGER NOT NULL REFERENCES industry_tracks(id) ON DELETE CASCADE,
  tour_key   VARCHAR(80) NOT NULL DEFAULT 'industry',
  status     VARCHAR(20) NOT NULL CHECK (status IN ('completed', 'skipped')),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, track_id, tour_key)
);

CREATE INDEX IF NOT EXISTS idx_user_tutorials_user
  ON user_tutorials (user_id, updated_at DESC);
