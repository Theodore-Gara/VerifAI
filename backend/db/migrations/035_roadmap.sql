-- 035 — Milestone tracker: ordered stages and evidence-based milestones.
--
-- There is deliberately no per-user roadmap table. Status is derived from the
-- learner's existing work on every read (task_attempts, lab_capstone_attempts,
-- industry_case_reads, lab_activity_attempts, user_track_progress,
-- user_tutorials), and that evidence only ever grows, so a derived read cannot
-- drift and nothing a learner earned can be taken back.
--
-- Migration 034 is intentionally skipped: it is reserved for the achievement
-- migration (BF-9) owned by the other backend workstream.

CREATE TABLE IF NOT EXISTS roadmap_stages (
  id SERIAL PRIMARY KEY,
  track_id INTEGER NOT NULL REFERENCES industry_tracks(id) ON DELETE CASCADE,
  code VARCHAR(40) NOT NULL,
  title VARCHAR(120) NOT NULL,
  outcome TEXT NOT NULL,
  description TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  credential_title VARCHAR(120),
  credential_description TEXT,
  UNIQUE (track_id, code)
);

CREATE INDEX IF NOT EXISTS idx_roadmap_stages_track ON roadmap_stages (track_id, sort_order);

CREATE TABLE IF NOT EXISTS roadmap_milestones (
  id SERIAL PRIMARY KEY,
  stage_id INTEGER NOT NULL REFERENCES roadmap_stages(id) ON DELETE CASCADE,
  code VARCHAR(60) NOT NULL,
  title VARCHAR(160) NOT NULL,
  description TEXT NOT NULL,
  requirement_type VARCHAR(40) NOT NULL CHECK (requirement_type IN (
    'tutorial_completed', 'tasks_passed', 'capstone_score',
    'industry_cases_read', 'activities_passed', 'readiness_score'
  )),
  requirement_target INTEGER NOT NULL CHECK (requirement_target > 0),
  requirement_filter JSONB,
  action_label VARCHAR(80),
  -- Shown instead of action_label once the milestone is complete ("Replay tour").
  action_label_done VARCHAR(80),
  action_route VARCHAR(200),
  sort_order INTEGER NOT NULL DEFAULT 0,
  UNIQUE (stage_id, code)
);

CREATE INDEX IF NOT EXISTS idx_roadmap_milestones_stage ON roadmap_milestones (stage_id, sort_order);
