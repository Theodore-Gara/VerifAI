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
  status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'banned')),
  status_reason TEXT,
  status_updated_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Audit trail of admin actions (account moderation + task management).
CREATE TABLE IF NOT EXISTS moderation_events (
  id SERIAL PRIMARY KEY,
  admin_email VARCHAR(255) NOT NULL,
  target_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  target_email VARCHAR(255),
  action VARCHAR(30) NOT NULL CHECK (action IN ('suspend', 'ban', 'activate',
    'task_create', 'task_update', 'task_delete', 'task_import', 'task_publish',
    'task_approve', 'task_reject',
    'user_grant', 'user_export', 'user_delete', 'user_firebase',
    'workshop_delete', 'workshop_hide',
    'lab_update',
    'config_update',
    'admin_add', 'admin_remove')),
  reason TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_moderation_events_target
  ON moderation_events (target_user_id, created_at DESC);

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
  published BOOLEAN NOT NULL DEFAULT TRUE,
  approval VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (approval IN ('pending', 'approved', 'rejected')),
  approved_by VARCHAR(255),
  approved_at TIMESTAMP,
  approval_note TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Runtime platform configuration (maintenance mode, feature flags), editable
-- from the admin dashboard without a redeploy.
CREATE TABLE IF NOT EXISTS app_config (
  key VARCHAR(80) PRIMARY KEY,
  value TEXT,
  updated_by VARCHAR(255),
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Admin panel role registry. ADMIN_EMAILS grants baseline access; a row here
-- can raise the role to 'super' or scope it to 'moderator'.
CREATE TABLE IF NOT EXISTS admin_accounts (
  email VARCHAR(255) PRIMARY KEY,
  role VARCHAR(20) NOT NULL DEFAULT 'admin' CHECK (role IN ('super', 'admin', 'moderator')),
  added_by VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------------
-- Per-feature content tables
-- ---------------------------------------------------------------------------

-- `format` selects the interaction: 'choice' (options in task_options) or
-- 'line_text' (tap the flawed line(s) + typed fix + typed reason).
CREATE TABLE IF NOT EXISTS verification_tasks (
  task_id INTEGER PRIMARY KEY REFERENCES tasks(id) ON DELETE CASCADE,
  format VARCHAR(20) NOT NULL DEFAULT 'choice' CHECK (format IN ('choice', 'line_text')),
  title VARCHAR(255) NOT NULL,
  scenario TEXT NOT NULL,
  embedded_flaw TEXT NOT NULL,
  expected_answer TEXT NOT NULL,
  feedback TEXT NOT NULL,
  difficulty VARCHAR(20) NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
  ai_output_lines TEXT[],
  flaw_lines INTEGER[],
  fix_keywords TEXT[],
  reason_keywords TEXT[]
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
  selected_lines INTEGER[],
  task_title VARCHAR(255) NOT NULL,
  score INTEGER NOT NULL CHECK (score BETWEEN 0 AND 100),
  passed BOOLEAN NOT NULL DEFAULT FALSE,
  practice BOOLEAN NOT NULL DEFAULT FALSE,
  feedback TEXT NOT NULL,
  xp_earned INTEGER NOT NULL DEFAULT 0 CHECK (xp_earned >= 0),
  submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- Calendar day in STREAK_TIMEZONE, written by the API (utils/dates.js) so
  -- analytics can group on an indexed column instead of converting per row.
  submitted_date DATE
);

-- ---------------------------------------------------------------------------
-- Answer log (per-department answer tracking)
-- ---------------------------------------------------------------------------
-- One denormalised row per graded answer so department analytics never join
-- through task_attempts at query time. Written by the attempt scorer.

CREATE TABLE IF NOT EXISTS answer_logs (
  id SERIAL PRIMARY KEY,
  attempt_id INTEGER REFERENCES task_attempts(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  department_id INTEGER REFERENCES industry_tracks(id) ON DELETE SET NULL,
  feature VARCHAR(30) NOT NULL,
  score INTEGER NOT NULL CHECK (score BETWEEN 0 AND 100),
  passed BOOLEAN NOT NULL,
  practice BOOLEAN NOT NULL DEFAULT FALSE,
  answer_summary TEXT,
  submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  submitted_date DATE
);

CREATE INDEX IF NOT EXISTS idx_answer_logs_dept ON answer_logs (department_id, submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_answer_logs_feature ON answer_logs (feature, submitted_at DESC);

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
  tokens INTEGER NOT NULL DEFAULT 0 CHECK (tokens >= 0),
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
-- Product Hub: Verification Studio, AI Lab, Workshop, Reward tokens, avatars
-- (see db/migrations/007_product_hub.sql for the same DDL applied to existing
-- databases)
-- ---------------------------------------------------------------------------

-- Verification Studio stores metadata + report only, never the raw input.
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

CREATE TABLE IF NOT EXISTS lab_lessons (
  id SERIAL PRIMARY KEY,
  code VARCHAR(120) NOT NULL UNIQUE,
  track_id INTEGER REFERENCES industry_tracks(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  summary TEXT NOT NULL,
  estimated_minutes INTEGER NOT NULL DEFAULT 5 CHECK (estimated_minutes > 0),
  level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
  is_original BOOLEAN NOT NULL DEFAULT TRUE,
  reviewed_by TEXT,
  competency VARCHAR(40),
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Textbook structure: book (lab_lessons) > chapter (parent_id NULL) > topic
-- (child of a chapter) > subtopic (child of a topic). The topic reader renders
-- all of a topic's subtopics together.
CREATE TABLE IF NOT EXISTS lab_lesson_sections (
  id SERIAL PRIMARY KEY,
  lesson_id INTEGER NOT NULL REFERENCES lab_lessons(id) ON DELETE CASCADE,
  parent_id INTEGER REFERENCES lab_lesson_sections(id) ON DELETE CASCADE,
  heading VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0
);

-- Practice activities: graded recall checks (multiple choice, true/false,
-- fill-in-the-blank, matching, ordering). `correct` is never sent to the app.
-- `source_id` FK is added after content_sources is created, below.
CREATE TABLE IF NOT EXISTS lab_activities (
  id SERIAL PRIMARY KEY,
  lesson_id INTEGER NOT NULL REFERENCES lab_lessons(id) ON DELETE CASCADE,
  type VARCHAR(20) NOT NULL CHECK (type IN ('multiple_choice', 'true_false', 'matching', 'fill_blank', 'ordering')),
  prompt TEXT NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  correct JSONB NOT NULL,
  explanation TEXT NOT NULL,
  source_id UUID,
  xp_reward INTEGER NOT NULL DEFAULT 10 CHECK (xp_reward >= 0),
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS lab_activity_attempts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity_id INTEGER NOT NULL REFERENCES lab_activities(id) ON DELETE CASCADE,
  passed BOOLEAN NOT NULL,
  xp_awarded INTEGER NOT NULL DEFAULT 0 CHECK (xp_awarded >= 0),
  submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  submitted_date DATE
);

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
  last_viewed_at TIMESTAMPTZ,
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

CREATE TABLE IF NOT EXISTS reward_token_events (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  delta INTEGER NOT NULL CHECK (delta <> 0),
  reason VARCHAR(30) NOT NULL CHECK (reason IN ('level_up', 'achievement', 'redemption', 'adjustment', 'capstone')),
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

CREATE TABLE IF NOT EXISTS user_avatars (
  user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  mime VARCHAR(50) NOT NULL,
  bytes BYTEA NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------------
-- AI Lab content sources + licensing
-- ---------------------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$ BEGIN
  CREATE TYPE license_code AS ENUM ('CC0', 'PUBLIC_DOMAIN', 'CC_BY_4', 'CC_BY_SA_4');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE industry_code AS ENUM ('FINANCE', 'LEGAL', 'IT_SOFTWARE', 'BUSINESS_CONSULTING', 'CROSS_INDUSTRY');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS content_sources (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title         TEXT          NOT NULL,
  author        TEXT          NOT NULL,
  publisher     TEXT,
  edition       TEXT,
  source_url    TEXT          NOT NULL,
  license       license_code  NOT NULL,
  license_url   TEXT          NOT NULL,
  industry      industry_code NOT NULL,
  checked_on    DATE          NOT NULL DEFAULT CURRENT_DATE,
  notes         TEXT
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_content_sources_title ON content_sources(title);

DO $$ BEGIN
  ALTER TABLE lab_activities
    ADD CONSTRAINT lab_activities_source_fk FOREIGN KEY (source_id) REFERENCES content_sources(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS lesson_sources (
  lesson_id     INTEGER NOT NULL REFERENCES lab_lessons(id)      ON DELETE CASCADE,
  source_id     UUID    NOT NULL REFERENCES content_sources(id)  ON DELETE RESTRICT,
  use_type      TEXT    NOT NULL CHECK (use_type IN ('linked', 'inspired_by', 'adapted', 'copied')),
  changes_made  TEXT,
  PRIMARY KEY (lesson_id, source_id)
);

CREATE OR REPLACE VIEW lessons_needing_share_alike AS
SELECT DISTINCT l.id, l.title
FROM lab_lessons l
JOIN lesson_sources ls ON ls.lesson_id = l.id
JOIN content_sources cs ON cs.id = ls.source_id
WHERE cs.license = 'CC_BY_SA_4'
  AND ls.use_type IN ('adapted', 'copied');

CREATE OR REPLACE VIEW lesson_attributions AS
SELECT
    ls.lesson_id,
    format(
        '"%s"%s by %s, %s%s',
        cs.title,
        COALESCE(' (' || cs.edition || ')', ''),
        cs.author,
        CASE cs.license
            WHEN 'CC_BY_4'       THEN 'licensed under CC BY 4.0'
            WHEN 'CC_BY_SA_4'    THEN 'licensed under CC BY-SA 4.0'
            WHEN 'CC0'           THEN 'dedicated to the public domain (CC0)'
            WHEN 'PUBLIC_DOMAIN' THEN 'public domain'
        END,
        CASE WHEN ls.use_type IN ('adapted', 'copied') AND ls.changes_made IS NOT NULL
             THEN '. Changes: ' || ls.changes_made ELSE '' END
    ) AS credit_line,
    cs.source_url,
    cs.license_url,
    cs.title,
    cs.license,
    ls.use_type
FROM lesson_sources ls
JOIN content_sources cs ON cs.id = ls.source_id;

-- ---------------------------------------------------------------------------
-- AI Lab capstone assessments (module-level, scenario-based)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS lab_capstone_assessments (
  id SERIAL PRIMARY KEY,
  code VARCHAR(120) NOT NULL UNIQUE,
  track_id INTEGER REFERENCES industry_tracks(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  summary TEXT NOT NULL,
  scenario JSONB,
  instructions JSONB,
  total_marks INTEGER NOT NULL DEFAULT 0,
  grade_bands JSONB,
  time_limit_seconds INTEGER NOT NULL DEFAULT 2400 CHECK (time_limit_seconds > 0),
  pass_score INTEGER NOT NULL DEFAULT 60 CHECK (pass_score BETWEEN 0 AND 100),
  max_attempts INTEGER NOT NULL DEFAULT 3 CHECK (max_attempts > 0),
  xp_reward INTEGER NOT NULL DEFAULT 70 CHECK (xp_reward >= 0),
  token_reward INTEGER NOT NULL DEFAULT 15 CHECK (token_reward >= 0),
  achievement_code VARCHAR(100),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS lab_capstone_questions (
  id SERIAL PRIMARY KEY,
  assessment_id INTEGER NOT NULL REFERENCES lab_capstone_assessments(id) ON DELETE CASCADE,
  type VARCHAR(20) NOT NULL CHECK (type IN ('multiple_choice', 'true_false', 'matching', 'fill_blank', 'ordering', 'numeric', 'multi_select', 'extended_response')),
  section VARCHAR(40),
  scenario TEXT,
  prompt TEXT NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  correct JSONB,
  explanation TEXT,
  rubric JSONB,
  model_answer TEXT,
  code_lines JSONB,
  word_limit JSONB,
  competency VARCHAR(40),
  cognitive_level VARCHAR(40),
  source_refs JSONB,
  marks INTEGER NOT NULL DEFAULT 1 CHECK (marks > 0),
  marking VARCHAR(10) NOT NULL DEFAULT 'auto' CHECK (marking IN ('auto', 'rubric')),
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
  status VARCHAR(20) NOT NULL DEFAULT 'marked' CHECK (status IN ('pending_marking', 'marked')),
  auto_marks INTEGER,
  marks_awarded INTEGER,
  marking JSONB,
  marked_by TEXT,
  marked_at TIMESTAMPTZ,
  analysis JSONB,
  analyzed_at TIMESTAMPTZ,
  timed_out BOOLEAN NOT NULL DEFAULT FALSE,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  submitted_at TIMESTAMPTZ,
  submitted_date DATE
);

-- ---------------------------------------------------------------------------
-- Learning Assistant — per-task chat history
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS assistant_sessions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  message_count INTEGER NOT NULL DEFAULT 0 CHECK (message_count >= 0),
  UNIQUE (user_id, task_id)
);

CREATE TABLE IF NOT EXISTS assistant_messages (
  id SERIAL PRIMARY KEY,
  session_id INTEGER NOT NULL REFERENCES assistant_sessions(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(10) NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_assistant_sessions_user ON assistant_sessions(user_id, last_active_at DESC);
CREATE INDEX IF NOT EXISTS idx_assistant_messages_session ON assistant_messages(session_id, created_at);

-- ---------------------------------------------------------------------------
-- Vera — AI assistant memory (sessions, messages, durable memories)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS vera_sessions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  context VARCHAR(30) NOT NULL DEFAULT 'assistant',
  title VARCHAR(255),
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  message_count INTEGER NOT NULL DEFAULT 0 CHECK (message_count >= 0),
  summary TEXT,
  summary_upto_message_id INTEGER
);

CREATE TABLE IF NOT EXISTS vera_messages (
  id SERIAL PRIMARY KEY,
  session_id INTEGER NOT NULL REFERENCES vera_sessions(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(10) NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS vera_memories (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind VARCHAR(20) NOT NULL CHECK (kind IN ('preference', 'struggle', 'strength', 'goal', 'fact')),
  content TEXT NOT NULL,
  source VARCHAR(30) NOT NULL DEFAULT 'chat',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, kind, content)
);

CREATE TABLE IF NOT EXISTS vera_profiles (
  user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  profile TEXT NOT NULL DEFAULT '',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- Industry Practice — informational workplace blunder case studies
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS industry_cases (
  id SERIAL PRIMARY KEY,
  track_id INTEGER REFERENCES industry_tracks(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  scenario TEXT NOT NULL,
  cause TEXT NOT NULL,
  solution TEXT NOT NULL,
  source_title VARCHAR(255),
  source_url TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_industry_cases_title ON industry_cases(title);

CREATE TABLE IF NOT EXISTS industry_case_reads (
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  case_id INTEGER NOT NULL REFERENCES industry_cases(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, case_id)
);

-- ---------------------------------------------------------------------------
-- Wellness — mood check-ins, private journal, self-care activity log
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS wellness_mood_checkins (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  check_in_date DATE NOT NULL,
  mood VARCHAR(20) NOT NULL CHECK (mood IN ('Great', 'Calm', 'Okay', 'Stressed', 'Tired', 'Low')),
  note TEXT CHECK (note IS NULL OR char_length(note) <= 200),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, check_in_date)
);

CREATE TABLE IF NOT EXISTS wellness_journal_entries (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  entry_date DATE NOT NULL,
  content TEXT NOT NULL CHECK (char_length(content) BETWEEN 1 AND 1200),
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, entry_date)
);

CREATE TABLE IF NOT EXISTS wellness_activities (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity VARCHAR(20) NOT NULL CHECK (activity IN ('breathing', 'journal', 'step_outside')),
  completed_at TIMESTAMPTZ NOT NULL DEFAULT now()
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
CREATE INDEX IF NOT EXISTS idx_content_sources_industry ON content_sources(industry, title);
CREATE INDEX IF NOT EXISTS idx_lesson_sources_source ON lesson_sources(source_id);
CREATE INDEX IF NOT EXISTS idx_lab_lesson_progress_viewed ON lab_lesson_progress(user_id, last_viewed_at);
CREATE INDEX IF NOT EXISTS idx_lab_activity_attempts ON lab_activity_attempts(user_id, activity_id);
CREATE INDEX IF NOT EXISTS idx_lab_capstone_questions ON lab_capstone_questions(assessment_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_lab_capstone_attempts ON lab_capstone_attempts(user_id, assessment_id);
CREATE INDEX IF NOT EXISTS idx_vera_sessions_user ON vera_sessions(user_id, last_active_at DESC);
CREATE INDEX IF NOT EXISTS idx_vera_messages_session ON vera_messages(session_id, created_at);
CREATE INDEX IF NOT EXISTS idx_vera_memories_user ON vera_memories(user_id, kind);
CREATE INDEX IF NOT EXISTS idx_industry_cases_track ON industry_cases(track_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_wellness_mood_user ON wellness_mood_checkins(user_id, check_in_date DESC);
CREATE INDEX IF NOT EXISTS idx_wellness_journal_user ON wellness_journal_entries(user_id, entry_date DESC);
CREATE INDEX IF NOT EXISTS idx_wellness_journal_live ON wellness_journal_entries(user_id, entry_date DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_wellness_activities_user ON wellness_activities(user_id, completed_at DESC);

-- Activity-day indexes: analytics group on the stored calendar day, and the
-- leaderboard reads the progress table in rank order.
CREATE INDEX IF NOT EXISTS idx_task_attempts_submitted_date ON task_attempts(submitted_date);
CREATE INDEX IF NOT EXISTS idx_answer_logs_submitted_date ON answer_logs(submitted_date);
CREATE INDEX IF NOT EXISTS idx_lab_activity_attempts_submitted_date ON lab_activity_attempts(submitted_date);
CREATE INDEX IF NOT EXISTS idx_task_attempts_user_graded ON task_attempts(user_id, submitted_at DESC) WHERE practice = FALSE;
CREATE INDEX IF NOT EXISTS idx_lab_activity_attempts_user_submitted ON lab_activity_attempts(user_id, submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_progress_leaderboard ON user_progress(xp DESC, readiness_score DESC, user_id);

-- ---------------------------------------------------------------------------
-- Shared rate-limit counters (see utils/pgRateStore.js)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS rate_limit_hits (
  key          VARCHAR(200) NOT NULL,
  window_start TIMESTAMP NOT NULL,
  hits         INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (key, window_start)
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_hits_window ON rate_limit_hits(window_start);

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

DROP TRIGGER IF EXISTS trg_lab_lesson_progress_updated_at ON lab_lesson_progress;
CREATE TRIGGER trg_lab_lesson_progress_updated_at
BEFORE UPDATE ON lab_lesson_progress
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_user_avatars_updated_at ON user_avatars;
CREATE TRIGGER trg_user_avatars_updated_at
BEFORE UPDATE ON user_avatars
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_vera_memories_updated_at ON vera_memories;
CREATE TRIGGER trg_vera_memories_updated_at
BEFORE UPDATE ON vera_memories
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_vera_profiles_updated_at ON vera_profiles;
CREATE TRIGGER trg_vera_profiles_updated_at
BEFORE UPDATE ON vera_profiles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_wellness_mood_checkins_updated_at ON wellness_mood_checkins;
CREATE TRIGGER trg_wellness_mood_checkins_updated_at
BEFORE UPDATE ON wellness_mood_checkins
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_wellness_journal_entries_updated_at ON wellness_journal_entries;
CREATE TRIGGER trg_wellness_journal_entries_updated_at
BEFORE UPDATE ON wellness_journal_entries
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Learner activity timeline (task attempts, lab practice, capstones).
CREATE OR REPLACE VIEW user_activity AS
SELECT ta.user_id,
       'task'::text               AS type,
       ta.id,
       ta.task_title              AS title,
       t.feature                  AS feature,
       ta.score                   AS score,
       ta.passed                  AS passed,
       ta.practice                AS practice,
       ta.xp_earned               AS xp_earned,
       ta.submitted_at            AS created_at
FROM task_attempts ta
JOIN tasks t ON t.id = ta.task_id
UNION ALL
SELECT aa.user_id,
       'activity'::text,
       aa.id,
       a.prompt,
       NULL,
       NULL,
       aa.passed,
       FALSE,
       aa.xp_awarded,
       aa.submitted_at
FROM lab_activity_attempts aa
JOIN lab_activities a ON a.id = aa.activity_id
UNION ALL
SELECT ca.user_id,
       'capstone'::text,
       ca.id,
       c.title,
       'capstone',
       ca.score,
       ca.passed,
       FALSE,
       CASE WHEN ca.passed THEN c.xp_reward ELSE 0 END,
       ca.submitted_at
FROM lab_capstone_attempts ca
JOIN lab_capstone_assessments c ON c.id = ca.assessment_id
WHERE ca.submitted_at IS NOT NULL;
