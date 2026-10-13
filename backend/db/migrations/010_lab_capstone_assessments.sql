-- VerifAI AI Lab — capstone assessments (module-level, scenario-based).
--
-- One capstone per industry module (track_id NULL = cross-industry). Graded
-- server-side, shuffled, timed, capped at a fixed number of attempts. Passing
-- can award XP, tokens and a badge, and feeds the readiness score.

CREATE TABLE IF NOT EXISTS lab_capstone_assessments (
  id SERIAL PRIMARY KEY,
  code VARCHAR(120) NOT NULL UNIQUE,
  track_id INTEGER REFERENCES industry_tracks(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  summary TEXT NOT NULL,
  time_limit_seconds INTEGER NOT NULL DEFAULT 1200 CHECK (time_limit_seconds > 0),
  pass_score INTEGER NOT NULL DEFAULT 60 CHECK (pass_score BETWEEN 0 AND 100),
  max_attempts INTEGER NOT NULL DEFAULT 3 CHECK (max_attempts > 0),
  xp_reward INTEGER NOT NULL DEFAULT 100 CHECK (xp_reward >= 0),
  token_reward INTEGER NOT NULL DEFAULT 0 CHECK (token_reward >= 0),
  achievement_code VARCHAR(100),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS lab_capstone_questions (
  id SERIAL PRIMARY KEY,
  assessment_id INTEGER NOT NULL REFERENCES lab_capstone_assessments(id) ON DELETE CASCADE,
  type VARCHAR(20) NOT NULL CHECK (type IN ('multiple_choice', 'true_false', 'matching', 'fill_blank', 'ordering')),
  scenario TEXT,
  prompt TEXT NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  correct JSONB NOT NULL,
  explanation TEXT NOT NULL,
  source_id UUID REFERENCES content_sources(id) ON DELETE SET NULL,
  points INTEGER NOT NULL DEFAULT 1 CHECK (points > 0),
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS lab_capstone_attempts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assessment_id INTEGER NOT NULL REFERENCES lab_capstone_assessments(id) ON DELETE CASCADE,
  presentation JSONB NOT NULL,
  answers JSONB,
  score INTEGER CHECK (score BETWEEN 0 AND 100),
  passed BOOLEAN,
  timed_out BOOLEAN NOT NULL DEFAULT FALSE,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  submitted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_lab_capstone_questions ON lab_capstone_questions(assessment_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_lab_capstone_attempts ON lab_capstone_attempts(user_id, assessment_id);

-- Token rewards can now carry a 'capstone' reason.
ALTER TABLE reward_token_events DROP CONSTRAINT IF EXISTS reward_token_events_reason_check;
ALTER TABLE reward_token_events
  ADD CONSTRAINT reward_token_events_reason_check
  CHECK (reason IN ('level_up', 'achievement', 'redemption', 'adjustment', 'capstone'));
