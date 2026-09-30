-- VerifAI Deliverable 4 migration for the team's original prototype database.
-- IMPORTANT: Back up the database before running this script.
-- Run once against the existing prototype database, then run seed.sql.

BEGIN;

ALTER TABLE users ADD COLUMN IF NOT EXISTS industry_track_id INTEGER;

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

-- Preserve prototype score data rather than deleting it.
DO $$
BEGIN
  IF to_regclass('public.scores') IS NOT NULL AND to_regclass('public.legacy_scores') IS NULL THEN
    ALTER TABLE scores RENAME TO legacy_scores;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS skill_scores (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  dimension VARCHAR(50) NOT NULL,
  score INTEGER NOT NULL DEFAULT 0 CHECK (score BETWEEN 0 AND 100),
  attempts_count INTEGER NOT NULL DEFAULT 0 CHECK (attempts_count >= 0),
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (user_id, dimension)
);

INSERT INTO skill_scores (user_id, dimension, score, attempts_count, updated_at)
SELECT user_id, dimension, GREATEST(0, LEAST(100, score)), 0, CURRENT_TIMESTAMP
FROM legacy_scores
ON CONFLICT (user_id, dimension) DO UPDATE
SET score = EXCLUDED.score,
    updated_at = CURRENT_TIMESTAMP;

-- Preserve prototype submissions rather than deleting them.
DO $$
BEGIN
  IF to_regclass('public.task_submissions') IS NOT NULL AND to_regclass('public.legacy_task_submissions') IS NULL THEN
    ALTER TABLE task_submissions RENAME TO legacy_task_submissions;
  END IF;
END $$;

ALTER TABLE tasks ADD COLUMN IF NOT EXISTS feedback TEXT;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS difficulty VARCHAR(20) DEFAULT 'medium';
UPDATE tasks
SET feedback = COALESCE(feedback, 'Review the source evidence, reasoning and relevant risk controls before relying on an AI output.')
WHERE feedback IS NULL;

-- Existing prototype tasks must have reference answers before they can be scored.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM tasks WHERE correct_answer IS NULL) THEN
    RAISE EXCEPTION 'Migration stopped: one or more existing tasks have NULL correct_answer. Add reference answers before rerunning db/migrate_d4.sql.';
  END IF;
  IF EXISTS (SELECT 1 FROM tasks WHERE feedback IS NULL) THEN
    RAISE EXCEPTION 'Migration stopped: one or more existing tasks have NULL feedback.';
  END IF;
END $$;

ALTER TABLE tasks ALTER COLUMN track_id SET NOT NULL;
ALTER TABLE tasks ALTER COLUMN correct_answer SET NOT NULL;
ALTER TABLE tasks ALTER COLUMN feedback SET NOT NULL;
ALTER TABLE tasks ALTER COLUMN difficulty SET NOT NULL;

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

INSERT INTO task_attempts (user_id, task_id, answer, score, feedback, xp_earned, submitted_at)
SELECT l.user_id,
       l.task_id,
       l.answer,
       GREATEST(0, LEAST(100, COALESCE(l.score, 0))),
       COALESCE(t.feedback, l.explanation, 'Assessment completed.'),
       GREATEST(10, LEAST(70, 20 + ROUND(COALESCE(l.score, 0) * 0.5))),
       COALESCE(l.submitted_at, CURRENT_TIMESTAMP)
FROM legacy_task_submissions l
JOIN tasks t ON t.id = l.task_id;

CREATE TABLE IF NOT EXISTS user_progress (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  xp INTEGER NOT NULL DEFAULT 0 CHECK (xp >= 0),
  level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
  streak INTEGER NOT NULL DEFAULT 0 CHECK (streak >= 0),
  last_activity_date DATE,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO user_progress (user_id, xp, level, streak, last_activity_date)
SELECT u.id,
       COALESCE(SUM(ta.xp_earned), 0)::int,
       GREATEST(1, FLOOR(COALESCE(SUM(ta.xp_earned), 0) / 250) + 1)::int,
       0,
       MAX(ta.submitted_at::date)
FROM users u
LEFT JOIN task_attempts ta ON ta.user_id = u.id
GROUP BY u.id
ON CONFLICT (user_id) DO NOTHING;

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

COMMIT;
