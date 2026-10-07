-- VerifAI — PostgreSQL schema (per-feature task model)
-- Run on a fresh database before seed.sql and db/seed/*.sql.

-- ---------------------------------------------------------------------------
-- Shared tables
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS industry_tracks (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT
);

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  firebase_uid VARCHAR(128) UNIQUE NOT NULL,
  email VARCHAR(255) NOT NULL,
  display_name VARCHAR(255),
  industry_track_id INTEGER REFERENCES industry_tracks(id) ON DELETE SET NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------------
-- Task anchor
-- ---------------------------------------------------------------------------
-- Holds identity only (no seed content) so task_attempts/skill_scores keep one
-- FK across every feature. `code` is the stable seed key used for idempotency.

CREATE TABLE IF NOT EXISTS tasks (
  id SERIAL PRIMARY KEY,
  code VARCHAR(120) NOT NULL UNIQUE,
  feature VARCHAR(30) NOT NULL CHECK (feature IN ('verification', 'judgement', 'risk_governance', 'prompt_design')),
  track_id INTEGER NOT NULL REFERENCES industry_tracks(id) ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------------
-- Per-feature content tables
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS verification_tasks (
  task_id INTEGER PRIMARY KEY REFERENCES tasks(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  scenario TEXT NOT NULL,
  embedded_flaw TEXT NOT NULL,
  expected_answer TEXT NOT NULL,
  feedback TEXT NOT NULL,
  difficulty VARCHAR(20) NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
  keywords TEXT[]
);

CREATE TABLE IF NOT EXISTS judgement_tasks (
  task_id INTEGER PRIMARY KEY REFERENCES tasks(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  scenario TEXT NOT NULL,
  feedback TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS risk_governance_tasks (
  task_id INTEGER PRIMARY KEY REFERENCES tasks(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  scenario TEXT NOT NULL,
  feedback TEXT NOT NULL
);

-- Controlled-choice options, shared by Verification ('answer'), AI Judgement and
-- Risk & Governance ('decision' + 'reason'). `score` is never returned to the app.
CREATE TABLE IF NOT EXISTS task_options (
  id SERIAL PRIMARY KEY,
  task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  kind VARCHAR(20) NOT NULL CHECK (kind IN ('answer', 'decision', 'reason')),
  label TEXT NOT NULL,
  score INTEGER NOT NULL CHECK (score BETWEEN 0 AND 100),
  sort_order INTEGER NOT NULL DEFAULT 0
);

-- Interview Practice (ungraded, read-only; contributes to readiness via coverage).
CREATE TABLE IF NOT EXISTS interview_questions (
  id SERIAL PRIMARY KEY,
  track_id INTEGER NOT NULL REFERENCES industry_tracks(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  sample_answer TEXT NOT NULL,
  what_employers_test TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS interview_practice (
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  question_id INTEGER NOT NULL REFERENCES interview_questions(id) ON DELETE CASCADE,
  practiced_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, question_id)
);

-- ---------------------------------------------------------------------------
-- Attempts
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS task_attempts (
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

-- ---------------------------------------------------------------------------
-- Progression
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS skill_scores (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  dimension VARCHAR(50) NOT NULL CHECK (dimension IN ('Verification', 'AI Judgement', 'Prompt Design', 'Risk & Governance')),
  score INTEGER NOT NULL DEFAULT 0 CHECK (score BETWEEN 0 AND 100),
  attempts_count INTEGER NOT NULL DEFAULT 0 CHECK (attempts_count >= 0),
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (user_id, dimension)
);

CREATE TABLE IF NOT EXISTS user_progress (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  xp INTEGER NOT NULL DEFAULT 0 CHECK (xp >= 0),
  level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
  streak INTEGER NOT NULL DEFAULT 0 CHECK (streak >= 0),
  last_activity_date DATE,
  tier VARCHAR(20) NOT NULL DEFAULT 'Novice' CHECK (tier IN ('Novice', 'Developing', 'Proficient', 'Advanced')),
  tier_tasks_completed INTEGER NOT NULL DEFAULT 0 CHECK (tier_tasks_completed >= 0),
  readiness_score INTEGER NOT NULL DEFAULT 0 CHECK (readiness_score BETWEEN 0 AND 100),
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS achievements (
  id SERIAL PRIMARY KEY,
  code VARCHAR(100) NOT NULL UNIQUE,
  name VARCHAR(150) NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS user_achievements (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_id INTEGER NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
  earned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (user_id, achievement_id)
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_tasks_feature_track ON tasks(feature, track_id);
CREATE INDEX IF NOT EXISTS idx_verification_tasks_difficulty ON verification_tasks(difficulty);
CREATE INDEX IF NOT EXISTS idx_task_options_task ON task_options(task_id, kind, sort_order);
CREATE INDEX IF NOT EXISTS idx_interview_questions_track ON interview_questions(track_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_task_attempts_user ON task_attempts(user_id, submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_task_attempts_user_task ON task_attempts(user_id, task_id);
CREATE INDEX IF NOT EXISTS idx_skill_scores_user ON skill_scores(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user ON user_achievements(user_id, earned_at DESC);

-- ---------------------------------------------------------------------------
-- updated_at triggers
-- ---------------------------------------------------------------------------

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
