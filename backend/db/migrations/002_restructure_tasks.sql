-- =============================================================================
-- 002: single-table `tasks` -> per-feature task model
-- =============================================================================
-- Target: the live D4 database (after 001). Splits task content into per-feature
-- tables behind a thin `tasks` anchor, and extends `task_attempts`.
--
-- DATA SAFETY: this wipes task content and attempts and resets the derived
-- progression tables (skill_scores / user_progress / user_achievements).
-- `users` is preserved. No backup step (no valuable data yet).
--
-- The runner (scripts/db-setup.js) wraps this file in a transaction, so do NOT
-- put BEGIN/COMMIT here. Run against a fresh database via schema.sql instead.
-- =============================================================================

-- 1. Wipe attempts + old tasks; reset derived progression (keep users).
DROP TABLE IF EXISTS task_attempts CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
TRUNCATE TABLE skill_scores, user_progress, user_achievements RESTART IDENTITY;

-- 2. Anchor (identity only; `code` is the stable seed key).
CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  code VARCHAR(120) NOT NULL UNIQUE,
  feature VARCHAR(30) NOT NULL CHECK (feature IN ('verification', 'judgement', 'risk_governance', 'prompt_design')),
  track_id INTEGER NOT NULL REFERENCES industry_tracks(id) ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Per-feature content tables.
CREATE TABLE verification_tasks (
  task_id INTEGER PRIMARY KEY REFERENCES tasks(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  scenario TEXT NOT NULL,
  embedded_flaw TEXT NOT NULL,
  expected_answer TEXT NOT NULL,
  feedback TEXT NOT NULL,
  difficulty VARCHAR(20) NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
  keywords TEXT[]
);

CREATE TABLE judgement_tasks (
  task_id INTEGER PRIMARY KEY REFERENCES tasks(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  scenario TEXT NOT NULL,
  feedback TEXT NOT NULL
);

CREATE TABLE risk_governance_tasks (
  task_id INTEGER PRIMARY KEY REFERENCES tasks(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  scenario TEXT NOT NULL,
  feedback TEXT NOT NULL
);

-- 4. Controlled-choice options (shared).
CREATE TABLE task_options (
  id SERIAL PRIMARY KEY,
  task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  kind VARCHAR(20) NOT NULL CHECK (kind IN ('answer', 'decision', 'reason')),
  label TEXT NOT NULL,
  score INTEGER NOT NULL CHECK (score BETWEEN 0 AND 100),
  sort_order INTEGER NOT NULL DEFAULT 0
);

-- 5. Attempts.
CREATE TABLE task_attempts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  answer TEXT,
  rationale TEXT,
  answer_option_id INTEGER REFERENCES task_options(id) ON DELETE CASCADE,
  decision_option_id INTEGER REFERENCES task_options(id) ON DELETE CASCADE,
  reason_option_id INTEGER REFERENCES task_options(id) ON DELETE CASCADE,
  task_title VARCHAR(255) NOT NULL,
  score INTEGER NOT NULL CHECK (score BETWEEN 0 AND 100),
  passed BOOLEAN NOT NULL DEFAULT FALSE,
  practice BOOLEAN NOT NULL DEFAULT FALSE,
  feedback TEXT NOT NULL,
  xp_earned INTEGER NOT NULL DEFAULT 0 CHECK (xp_earned >= 0),
  submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 6. Progression columns for tiers.
ALTER TABLE user_progress
  ADD COLUMN IF NOT EXISTS tier VARCHAR(20) NOT NULL DEFAULT 'Novice'
    CHECK (tier IN ('Novice', 'Developing', 'Proficient', 'Advanced'));
ALTER TABLE user_progress
  ADD COLUMN IF NOT EXISTS tier_tasks_completed INTEGER NOT NULL DEFAULT 0
    CHECK (tier_tasks_completed >= 0);
ALTER TABLE user_progress
  ADD COLUMN IF NOT EXISTS readiness_score INTEGER NOT NULL DEFAULT 0
    CHECK (readiness_score BETWEEN 0 AND 100);

-- 7. Indexes.
CREATE INDEX IF NOT EXISTS idx_tasks_feature_track ON tasks(feature, track_id);
CREATE INDEX IF NOT EXISTS idx_verification_tasks_difficulty ON verification_tasks(difficulty);
CREATE INDEX IF NOT EXISTS idx_task_options_task ON task_options(task_id, kind, sort_order);
CREATE INDEX IF NOT EXISTS idx_task_attempts_user ON task_attempts(user_id, submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_task_attempts_user_task ON task_attempts(user_id, task_id);
