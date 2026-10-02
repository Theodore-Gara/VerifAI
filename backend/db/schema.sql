-- VerifAI Deliverable 4 — PostgreSQL schema
-- Eight required application tables. Run on a fresh database before seed.sql.

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

CREATE TABLE IF NOT EXISTS tasks (
  id SERIAL PRIMARY KEY,
  track_id INTEGER NOT NULL REFERENCES industry_tracks(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  scenario TEXT NOT NULL,
  correct_answer TEXT NOT NULL,
  feedback TEXT NOT NULL,
  dimension VARCHAR(50) NOT NULL CHECK (dimension IN ('Verification', 'AI Judgement', 'Prompt Design', 'Risk & Governance')),
  difficulty VARCHAR(20) NOT NULL DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS task_attempts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  answer TEXT NOT NULL,
  score INTEGER NOT NULL CHECK (score BETWEEN 0 AND 100),
  feedback TEXT NOT NULL,
  xp_earned INTEGER NOT NULL DEFAULT 0 CHECK (xp_earned >= 0),
  submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

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

CREATE INDEX IF NOT EXISTS idx_tasks_track_difficulty ON tasks(track_id, difficulty, id);
CREATE INDEX IF NOT EXISTS idx_task_attempts_user ON task_attempts(user_id, submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_task_attempts_user_task ON task_attempts(user_id, task_id);
CREATE INDEX IF NOT EXISTS idx_skill_scores_user ON skill_scores(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user ON user_achievements(user_id, earned_at DESC);

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
