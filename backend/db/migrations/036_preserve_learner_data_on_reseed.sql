-- 036_preserve_learner_data_on_reseed.sql
--
-- Running the seed path (npm run db:setup) must never erase learner history.
-- Before this migration, re-seeding:
--   * deleted task_options, and task_attempts.answer_option_id cascaded, so every
--     scored task attempt disappeared;
--   * deleted lab_activities, cascading lab_activity_attempts;
--   * deleted retired lab_lessons, cascading lab_lesson_progress and
--     lab_assessment_attempts.
--
-- The seeds now skip replacing content that already has learner data attached
-- (see the reseed_* guards in db/seed/00_helpers.sql), and old lessons are
-- retired instead of deleted. This migration adds the retirement flag.
--
-- Idempotent.

-- A retired lesson keeps its rows (and therefore learner progress/attempts) but
-- is hidden from the catalogue and the next-lesson rotation.
ALTER TABLE lab_lessons
  ADD COLUMN IF NOT EXISTS retired BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_lab_lessons_visible
  ON lab_lessons (track_id, sort_order) WHERE retired = FALSE;
