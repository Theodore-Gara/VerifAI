-- VerifAI — Product Hub backend (Verification Studio, AI Lab, Workshop, Reward tokens, avatars)
--
-- Fresh databases get this state from db/schema.sql directly and baseline this
-- migration as already-applied; existing databases run it via `npm run db:migrate`.

-- ---------------------------------------------------------------------------
-- Verification Studio
-- ---------------------------------------------------------------------------
-- We deliberately do NOT store the user's raw submitted content: only metadata
-- and the structured report, so confidential documents never persist.
CREATE TABLE IF NOT EXISTS verification_analyses (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind VARCHAR(20) NOT NULL CHECK (kind IN ('document', 'claim', 'ai_response', 'source')),
  document_name VARCHAR(255),
  overall_status VARCHAR(40) NOT NULL,
  items_requiring_review INTEGER NOT NULL DEFAULT 0 CHECK (items_requiring_review >= 0),
  sources_confirmed INTEGER NOT NULL DEFAULT 0 CHECK (sources_confirmed >= 0),
  summary TEXT NOT NULL,
  report JSONB NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------------
-- AI Lab — textbook lessons, activities, assessments, per-user progress
-- ---------------------------------------------------------------------------
-- track_id NULL = a shared lesson available to every industry.
CREATE TABLE IF NOT EXISTS lab_lessons (
  id SERIAL PRIMARY KEY,
  code VARCHAR(120) NOT NULL UNIQUE,
  track_id INTEGER REFERENCES industry_tracks(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  summary TEXT NOT NULL,
  estimated_minutes INTEGER NOT NULL DEFAULT 5 CHECK (estimated_minutes > 0),
  level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS lab_lesson_sections (
  id SERIAL PRIMARY KEY,
  lesson_id INTEGER NOT NULL REFERENCES lab_lessons(id) ON DELETE CASCADE,
  heading VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0
);

-- kind 'task_link' points at a real task so practical work reuses the attempt
-- pipeline; the other kinds are free-form prompts tracked by the learner.
CREATE TABLE IF NOT EXISTS lab_activities (
  id SERIAL PRIMARY KEY,
  lesson_id INTEGER NOT NULL REFERENCES lab_lessons(id) ON DELETE CASCADE,
  kind VARCHAR(30) NOT NULL CHECK (kind IN ('reflection', 'guided_practice', 'task_link', 'artifact')),
  title VARCHAR(255) NOT NULL,
  instructions TEXT NOT NULL,
  task_id INTEGER REFERENCES tasks(id) ON DELETE SET NULL,
  sort_order INTEGER NOT NULL DEFAULT 0
);

-- Assessment questions. `correct_index` is NEVER returned to the app; grading
-- happens in the controller so the answer key stays server-side.
CREATE TABLE IF NOT EXISTS lab_questions (
  id SERIAL PRIMARY KEY,
  lesson_id INTEGER NOT NULL REFERENCES lab_lessons(id) ON DELETE CASCADE,
  prompt TEXT NOT NULL,
  options JSONB NOT NULL,
  correct_index INTEGER NOT NULL CHECK (correct_index >= 0),
  explanation TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS lab_lesson_progress (
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  lesson_id INTEGER NOT NULL REFERENCES lab_lessons(id) ON DELETE CASCADE,
  sections_completed INTEGER NOT NULL DEFAULT 0 CHECK (sections_completed >= 0),
  activities_completed INTEGER NOT NULL DEFAULT 0 CHECK (activities_completed >= 0),
  assessment_best_score INTEGER NOT NULL DEFAULT 0 CHECK (assessment_best_score BETWEEN 0 AND 100),
  status VARCHAR(20) NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed')),
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, lesson_id)
);

CREATE TABLE IF NOT EXISTS lab_assessment_attempts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  lesson_id INTEGER NOT NULL REFERENCES lab_lessons(id) ON DELETE CASCADE,
  score INTEGER NOT NULL CHECK (score BETWEEN 0 AND 100),
  passed BOOLEAN NOT NULL DEFAULT FALSE,
  submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------------
-- Workshop — track-scoped community threads and replies
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS workshop_posts (
  id SERIAL PRIMARY KEY,
  track_id INTEGER NOT NULL REFERENCES industry_tracks(id) ON DELETE CASCADE,
  lesson_id INTEGER REFERENCES lab_lessons(id) ON DELETE SET NULL,
  author_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  parent_id INTEGER REFERENCES workshop_posts(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  hidden BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  edited_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS workshop_reactions (
  post_id INTEGER NOT NULL REFERENCES workshop_posts(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind VARCHAR(20) NOT NULL DEFAULT 'upvote',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (post_id, user_id, kind)
);

CREATE TABLE IF NOT EXISTS workshop_reports (
  id SERIAL PRIMARY KEY,
  post_id INTEGER NOT NULL REFERENCES workshop_posts(id) ON DELETE CASCADE,
  reporter_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason VARCHAR(40) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (post_id, reporter_id)
);

-- ---------------------------------------------------------------------------
-- Reward tokens — spendable currency earned from milestones (XP never spent)
-- ---------------------------------------------------------------------------
ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS tokens INTEGER NOT NULL DEFAULT 0 CHECK (tokens >= 0);

-- Append-only audit ledger. UNIQUE(user_id, reason, ref) makes grants
-- idempotent, so a retried submission can never double-credit tokens.
CREATE TABLE IF NOT EXISTS reward_token_events (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  delta INTEGER NOT NULL CHECK (delta <> 0),
  reason VARCHAR(30) NOT NULL CHECK (reason IN ('level_up', 'achievement', 'redemption', 'adjustment')),
  ref VARCHAR(120) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (user_id, reason, ref)
);

CREATE TABLE IF NOT EXISTS rewards (
  id SERIAL PRIMARY KEY,
  code VARCHAR(120) NOT NULL UNIQUE,
  title VARCHAR(255) NOT NULL,
  subtitle TEXT NOT NULL,
  cost_tokens INTEGER NOT NULL CHECK (cost_tokens > 0),
  image_asset VARCHAR(120) NOT NULL,
  note VARCHAR(255),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS reward_redemptions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reward_id INTEGER NOT NULL REFERENCES rewards(id) ON DELETE RESTRICT,
  cost_tokens INTEGER NOT NULL CHECK (cost_tokens > 0),
  status VARCHAR(20) NOT NULL DEFAULT 'confirmed' CHECK (status IN ('pending', 'confirmed', 'cancelled')),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------------
-- Profile avatars (stored inline; upgrade to object storage if they grow)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_avatars (
  user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  mime VARCHAR(50) NOT NULL,
  bytes BYTEA NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_verification_analyses_user ON verification_analyses(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_lab_lessons_track ON lab_lessons(track_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_lab_sections_lesson ON lab_lesson_sections(lesson_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_lab_activities_lesson ON lab_activities(lesson_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_lab_questions_lesson ON lab_questions(lesson_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_lab_attempts_user ON lab_assessment_attempts(user_id, lesson_id, submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_workshop_posts_track ON workshop_posts(track_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_workshop_posts_parent ON workshop_posts(parent_id, created_at);
CREATE INDEX IF NOT EXISTS idx_reward_token_events_user ON reward_token_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reward_redemptions_user ON reward_redemptions(user_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- updated_at triggers
-- ---------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_lab_lesson_progress_updated_at ON lab_lesson_progress;
CREATE TRIGGER trg_lab_lesson_progress_updated_at
BEFORE UPDATE ON lab_lesson_progress
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_user_avatars_updated_at ON user_avatars;
CREATE TRIGGER trg_user_avatars_updated_at
BEFORE UPDATE ON user_avatars
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
