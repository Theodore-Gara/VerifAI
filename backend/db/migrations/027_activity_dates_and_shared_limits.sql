-- 027_activity_dates_and_shared_limits.sql
--
-- Two scalability findings from the audit share one migration:
--
-- 1. Analytics grouped by `(submitted_at AT TIME ZONE 'Africa/Johannesburg')::date`
--    computed the date per row, so every 30-day chart was 30 sequential scans of
--    task_attempts/answer_logs. Those tables now carry a plain `submitted_date`
--    column written by the API (see utils/dates.js, which uses STREAK_TIMEZONE),
--    plus indexes on it. A STORED generated column is not an option: `AT TIME
--    ZONE` is STABLE, not IMMUTABLE, so PostgreSQL rejects it in a generation
--    expression.
--
-- 2. Rate-limit counters moved from each process's memory to the database
--    (`rate_limit_hits`), so two API instances share one budget.

-- ---------------------------------------------------------------------------
-- 1. Activity dates
-- ---------------------------------------------------------------------------
ALTER TABLE task_attempts ADD COLUMN IF NOT EXISTS submitted_date DATE;
ALTER TABLE answer_logs ADD COLUMN IF NOT EXISTS submitted_date DATE;
ALTER TABLE lab_activity_attempts ADD COLUMN IF NOT EXISTS submitted_date DATE;
ALTER TABLE lab_capstone_attempts ADD COLUMN IF NOT EXISTS submitted_date DATE;

-- Backfill with the deployment default. New rows are written with
-- STREAK_TIMEZONE in JavaScript, which is the same value in the default config.
UPDATE task_attempts
SET submitted_date = (submitted_at AT TIME ZONE 'Africa/Johannesburg')::date
WHERE submitted_date IS NULL;

UPDATE answer_logs
SET submitted_date = (submitted_at AT TIME ZONE 'Africa/Johannesburg')::date
WHERE submitted_date IS NULL;

UPDATE lab_activity_attempts
SET submitted_date = (submitted_at AT TIME ZONE 'Africa/Johannesburg')::date
WHERE submitted_date IS NULL;

UPDATE lab_capstone_attempts
SET submitted_date = (submitted_at AT TIME ZONE 'Africa/Johannesburg')::date
WHERE submitted_date IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_task_attempts_submitted_date
  ON task_attempts (submitted_date);
CREATE INDEX IF NOT EXISTS idx_answer_logs_submitted_date
  ON answer_logs (submitted_date);
CREATE INDEX IF NOT EXISTS idx_lab_activity_attempts_submitted_date
  ON lab_activity_attempts (submitted_date);

-- History and activity feeds filter to graded attempts and sort by date.
CREATE INDEX IF NOT EXISTS idx_task_attempts_user_graded
  ON task_attempts (user_id, submitted_at DESC)
  WHERE practice = FALSE;
CREATE INDEX IF NOT EXISTS idx_lab_activity_attempts_user_submitted
  ON lab_activity_attempts (user_id, submitted_at DESC);

-- ---------------------------------------------------------------------------
-- 2. Leaderboard: a covering index for the RANK()/ORDER BY and the "count the
--    rows ahead of me" query, so neither sorts the whole progress table.
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_user_progress_leaderboard
  ON user_progress (xp DESC, readiness_score DESC, user_id);

-- ---------------------------------------------------------------------------
-- 3. Shared rate-limit counters
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rate_limit_hits (
  key          VARCHAR(200) NOT NULL,
  window_start TIMESTAMP NOT NULL,
  hits         INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (key, window_start)
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_hits_window
  ON rate_limit_hits (window_start);
