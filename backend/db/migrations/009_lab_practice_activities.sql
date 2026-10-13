-- VerifAI AI Lab — practice activities as graded recall checks
--
-- lab_activities becomes a per-lesson bank of recall activities (multiple
-- choice, true/false, fill-in-the-blank, matching, ordering). Each is graded
-- server-side; a first non-practice pass awards XP (default 10).

-- The old free-form practical columns are replaced by typed recall content.
ALTER TABLE lab_activities DROP CONSTRAINT IF EXISTS lab_activities_kind_check;
ALTER TABLE lab_activities DROP COLUMN IF EXISTS kind;
ALTER TABLE lab_activities DROP COLUMN IF EXISTS title;
ALTER TABLE lab_activities DROP COLUMN IF EXISTS instructions;
ALTER TABLE lab_activities DROP COLUMN IF EXISTS task_id;

ALTER TABLE lab_activities ADD COLUMN IF NOT EXISTS type VARCHAR(20);
ALTER TABLE lab_activities ADD COLUMN IF NOT EXISTS prompt TEXT;
ALTER TABLE lab_activities ADD COLUMN IF NOT EXISTS payload JSONB NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE lab_activities ADD COLUMN IF NOT EXISTS correct JSONB;
ALTER TABLE lab_activities ADD COLUMN IF NOT EXISTS explanation TEXT;
ALTER TABLE lab_activities ADD COLUMN IF NOT EXISTS source_id UUID REFERENCES content_sources(id) ON DELETE SET NULL;
ALTER TABLE lab_activities ADD COLUMN IF NOT EXISTS xp_reward INTEGER NOT NULL DEFAULT 10 CHECK (xp_reward >= 0);

DO $$ BEGIN
  ALTER TABLE lab_activities ADD CONSTRAINT lab_activities_type_check
    CHECK (type IS NULL OR type IN ('multiple_choice', 'true_false', 'matching', 'fill_blank', 'ordering'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS lab_activity_attempts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity_id INTEGER NOT NULL REFERENCES lab_activities(id) ON DELETE CASCADE,
  passed BOOLEAN NOT NULL,
  xp_awarded INTEGER NOT NULL DEFAULT 0 CHECK (xp_awarded >= 0),
  submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_lab_activity_attempts ON lab_activity_attempts(user_id, activity_id);
