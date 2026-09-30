-- =============================================================================
-- VerifAI: prototype database -> Deliverable 4 backend schema
-- =============================================================================
-- Target: the live Railway Postgres prototype (PostgreSQL 18.6), verified
--         against the running server, not assumed.
--
-- WHY THIS FILE WAS REWRITTEN
--   The previous migrate_d4.sql was written against a *different* prototype.
--   On the actual database it fails immediately: it renames a `scores` table
--   to `legacy_scores` and reads it, but no `scores` table exists, nor does
--   `task_submissions`, nor a `tasks.track_id` column. Every one of those was
--   MISSING when checked against the live server.
--
-- WHAT THIS MIGRATION DOES
--   Renames prototype columns to the names the D4 backend queries, adds the
--   columns the backend requires, and backfills them from existing data.
--   It PRESERVES all 16 curated tasks, 5 achievements and 4 industry tracks.
--
-- DATA SAFETY
--   Run against a backup. This file is wrapped in a single transaction, so a
--   failure rolls the whole thing back. A verified data backup lives at
--   db/prototype-backup-*.sql (gitignored).
--
-- COLUMN MAPPING (prototype -> D4)
--   users.full_name            -> users.display_name      (widened to 255)
--   users.                     +  industry_track_id       (new, nullable, FK)
--   tasks.industry_track_id    -> tasks.track_id
--   tasks.skill_dimension      -> tasks.dimension
--   tasks.                     +  title                   (backfilled from scenario)
--   tasks.difficulty           'Easy'/'Medium'/'Hard' -> 'easy'/'medium'/'hard'
--   tasks.embedded_flaw         KEPT (D4 does not read it; it is curated content)
--   skill_scores.skill_dimension -> skill_scores.dimension
--   skill_scores.              +  attempts_count          (new, default 0)
--   task_attempts.attempted_at -> task_attempts.submitted_at
--   task_attempts.             +  xp_earned               (new, default 0)
--   user_progress              REBUILT (prototype shape is incompatible)
--   achievements.              +  code                    (backfilled from icon)
--   industry_tracks            UNCHANGED (already matches)
--   user_achievements          UNCHANGED (already matches)
--
-- NOTHING TO CARRY OVER
--   The prototype has no `scores` and no `task_submissions` tables, so the
--   previous migration's legacy_* preservation logic is not applicable here.
--   `users`, `task_attempts`, `user_progress` and `skill_scores` were all empty,
--   so those tables need no data transformation.
-- =============================================================================

BEGIN;

-- Refuse to run twice, with a clear message rather than a confusing rename error.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'tasks' AND column_name = 'track_id'
  ) THEN
    RAISE EXCEPTION 'Already migrated: tasks.track_id exists. Nothing to do.';
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- users
-- -----------------------------------------------------------------------------
ALTER TABLE users RENAME COLUMN full_name TO display_name;
ALTER TABLE users ALTER COLUMN display_name TYPE VARCHAR(255);

ALTER TABLE users ADD COLUMN industry_track_id INTEGER;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_industry_track_id_fkey'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_industry_track_id_fkey
      FOREIGN KEY (industry_track_id) REFERENCES industry_tracks(id) ON DELETE SET NULL;
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- tasks
-- -----------------------------------------------------------------------------
-- Renaming a column leaves its CHECK and FOREIGN KEY constraints pointing at
-- the right column, but keeps the old constraint NAMES, so rename those too.
ALTER TABLE tasks RENAME COLUMN industry_track_id TO track_id;
ALTER TABLE tasks RENAME CONSTRAINT tasks_industry_track_id_fkey TO tasks_track_id_fkey;

-- The prototype's four skill_dimension values are already exactly the four
-- dimensions the D4 CHECK constraint allows, so the constraint travels across
-- the rename untouched.
ALTER TABLE tasks RENAME COLUMN skill_dimension TO dimension;
ALTER TABLE tasks RENAME CONSTRAINT tasks_skill_dimension_check TO tasks_dimension_check;

-- title is required by the D4 backend (it SELECTs t.title) and by NOT NULL,
-- but the prototype has no such column. Derive it from the first line of the
-- scenario so every existing task gets a meaningful, non-empty title.
ALTER TABLE tasks ADD COLUMN title VARCHAR(255);
UPDATE tasks
SET title = LEFT(
      COALESCE(NULLIF(BTRIM(SPLIT_PART(BTRIM(scenario), E'\n', 1)), ''), 'Assessment task'),
      255
    );
ALTER TABLE tasks ALTER COLUMN title SET NOT NULL;

-- The prototype CHECK allows capitalised 'Easy'/'Medium'/'Hard'; the D4 backend
-- compares against lowercase 'easy'/'medium'/'hard'. Swap the data and the
-- constraint together, otherwise ordering by difficulty silently matches nothing.
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_difficulty_check;
UPDATE tasks SET difficulty = LOWER(difficulty);
ALTER TABLE tasks
  ADD CONSTRAINT tasks_difficulty_check
  CHECK (difficulty IN ('easy', 'medium', 'hard'));

-- -----------------------------------------------------------------------------
-- skill_scores
-- -----------------------------------------------------------------------------
ALTER TABLE skill_scores RENAME COLUMN skill_dimension TO dimension;
ALTER TABLE skill_scores RENAME CONSTRAINT skill_scores_user_id_skill_dimension_key
  TO skill_scores_user_id_dimension_key;

ALTER TABLE skill_scores ADD COLUMN attempts_count INTEGER NOT NULL DEFAULT 0;

-- Prototype score is a nullable numeric; D4 treats it as a required integer.
UPDATE skill_scores SET score = 0 WHERE score IS NULL;
ALTER TABLE skill_scores DROP CONSTRAINT IF EXISTS skill_scores_score_check;
ALTER TABLE skill_scores ALTER COLUMN score TYPE integer USING score::integer;
ALTER TABLE skill_scores ALTER COLUMN score SET NOT NULL;
ALTER TABLE skill_scores
  ADD CONSTRAINT skill_scores_score_check CHECK (score BETWEEN 0 AND 100);

-- -----------------------------------------------------------------------------
-- task_attempts
-- -----------------------------------------------------------------------------
ALTER TABLE task_attempts RENAME COLUMN attempted_at TO submitted_at;

ALTER TABLE task_attempts ADD COLUMN xp_earned INTEGER NOT NULL DEFAULT 0
  CHECK (xp_earned >= 0);

UPDATE task_attempts SET feedback = 'Assessment completed.' WHERE feedback IS NULL;
UPDATE task_attempts SET submitted_at = CURRENT_TIMESTAMP WHERE submitted_at IS NULL;
ALTER TABLE task_attempts ALTER COLUMN feedback SET NOT NULL;
ALTER TABLE task_attempts ALTER COLUMN submitted_at SET NOT NULL;

-- industry_tracks already matches D4, apart from looser NOT NULL on created_at.
UPDATE industry_tracks SET created_at = CURRENT_TIMESTAMP WHERE created_at IS NULL;
ALTER TABLE industry_tracks ALTER COLUMN created_at SET NOT NULL;

-- -----------------------------------------------------------------------------
-- user_progress
-- -----------------------------------------------------------------------------
-- The prototype tracks progress per (user, track) with readiness scores. D4
-- tracks a single xp/level/streak row per user and relies on
-- ON CONFLICT (user_id), which needs user_id to be UNIQUE on its own. The two
-- shapes are incompatible, so the table is rebuilt. Guarded so a populated
-- progress table is never destroyed silently.
DO $$
DECLARE
  n integer;
BEGIN
  SELECT COUNT(*) INTO n FROM user_progress;
  IF n > 0 THEN
    RAISE EXCEPTION
      'Migration stopped: user_progress has % row(s) of prototype data. '
      'This migration rebuilds that table for the D4 xp/level/streak model. '
      'Back the rows up and migrate them by hand, then rerun.', n;
  END IF;
END $$;

DROP TABLE user_progress;

CREATE TABLE user_progress (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  xp INTEGER NOT NULL DEFAULT 0 CHECK (xp >= 0),
  level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
  streak INTEGER NOT NULL DEFAULT 0 CHECK (streak >= 0),
  last_activity_date DATE,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- achievements
-- -----------------------------------------------------------------------------
-- D4 identifies achievements by a stable `code` (the backend queries
-- code = 'first-task'). The prototype only has `icon`, whose values are already
-- exactly the codes the D4 backend expects, so backfill from it and fall back to
-- a slug of the name for any row added later without an icon.
ALTER TABLE achievements ADD COLUMN code VARCHAR(100);

UPDATE achievements
SET code = COALESCE(
      NULLIF(BTRIM(icon), ''),
      LOWER(REGEXP_REPLACE(BTRIM(name), '[^a-zA-Z0-9]+', '-', 'g'))
    );

ALTER TABLE achievements ALTER COLUMN code SET NOT NULL;
ALTER TABLE achievements ALTER COLUMN name TYPE VARCHAR(150);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'achievements_code_key'
  ) THEN
    ALTER TABLE achievements ADD CONSTRAINT achievements_code_key UNIQUE (code);
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- Triggers and indexes (matching db/schema.sql so a migrated database and a
-- freshly created one are equivalent)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_skill_scores_updated_at ON skill_scores;
CREATE TRIGGER trg_skill_scores_updated_at
  BEFORE UPDATE ON skill_scores
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_user_progress_updated_at ON user_progress;
CREATE TRIGGER trg_user_progress_updated_at
  BEFORE UPDATE ON user_progress
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX IF NOT EXISTS idx_tasks_track_difficulty ON tasks(track_id, difficulty, id);
CREATE INDEX IF NOT EXISTS idx_task_attempts_user ON task_attempts(user_id, submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_task_attempts_user_task ON task_attempts(user_id, task_id);
CREATE INDEX IF NOT EXISTS idx_skill_scores_user ON skill_scores(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user ON user_achievements(user_id, earned_at DESC);

COMMIT;
