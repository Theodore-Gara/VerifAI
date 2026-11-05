-- 031_track_scoped_progress.sql
--
-- BF-6: competency is scoped to the industry track, progression stays global.
--
-- Before this migration `skill_scores` was keyed on (user_id, dimension) and
-- `user_progress.readiness_score` mixed every track's skill rows while dividing
-- by the current track's modules. Switching Finance -> Legal therefore showed
-- Finance's readiness and skill bars under Legal.
--
-- After it:
--   * skill_scores is keyed on (user_id, track_id, dimension)
--   * user_track_progress holds per-track readiness (and the best-ever value the
--     roadmap needs, so a weak retake cannot take a completed stage back)
--   * user_progress keeps the global signals (xp, level, streak, tokens) and its
--     readiness/tier columns stay as a mirror of the active track for older
--     read paths.
--
-- Idempotent: every statement guards on the current shape.

-- ---------------------------------------------------------------------------
-- skill_scores: add track_id, backfill, replace the unique key
-- ---------------------------------------------------------------------------
ALTER TABLE skill_scores
  ADD COLUMN IF NOT EXISTS track_id INTEGER REFERENCES industry_tracks(id) ON DELETE CASCADE;

-- Backfill from the track the learner actually attempted that skill in: the
-- track with the most attempts for the matching feature. This is the only
-- defensible source - it is real evidence, not the industry they happen to be
-- on today.
UPDATE skill_scores ss
SET track_id = best.track_id
FROM (
  SELECT ta.user_id,
         t.feature,
         t.track_id,
         ROW_NUMBER() OVER (
           PARTITION BY ta.user_id, t.feature
           ORDER BY COUNT(*) DESC, t.track_id ASC
         ) AS rn
  FROM task_attempts ta
  JOIN tasks t ON t.id = ta.task_id
  GROUP BY ta.user_id, t.feature, t.track_id
) best
WHERE ss.track_id IS NULL
  AND ss.user_id = best.user_id
  AND best.rn = 1
  AND ss.dimension = CASE best.feature
        WHEN 'verification' THEN 'Verification'
        WHEN 'judgement' THEN 'AI Judgement'
        WHEN 'risk_governance' THEN 'Risk & Governance'
        WHEN 'prompt_design' THEN 'Prompt Design'
      END;

-- Rows with no attempt at all fall back to the user's current track.
UPDATE skill_scores ss
SET track_id = u.industry_track_id
FROM users u
WHERE ss.track_id IS NULL
  AND ss.user_id = u.id
  AND u.industry_track_id IS NOT NULL;

-- A row that still has no track belongs to a user with no industry; there is no
-- track to scope it to, so drop it rather than keep an unscoped duplicate.
DELETE FROM skill_scores WHERE track_id IS NULL;

ALTER TABLE skill_scores ALTER COLUMN track_id SET NOT NULL;

ALTER TABLE skill_scores DROP CONSTRAINT IF EXISTS skill_scores_user_id_dimension_key;
CREATE UNIQUE INDEX IF NOT EXISTS skill_scores_user_track_dimension_key
  ON skill_scores (user_id, track_id, dimension);
CREATE INDEX IF NOT EXISTS idx_skill_scores_user_track
  ON skill_scores (user_id, track_id);

-- ---------------------------------------------------------------------------
-- user_track_progress
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_track_progress (
  user_id            INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  track_id           INTEGER NOT NULL REFERENCES industry_tracks(id) ON DELETE CASCADE,
  readiness_score    INTEGER NOT NULL DEFAULT 0 CHECK (readiness_score BETWEEN 0 AND 100),
  readiness_best     INTEGER NOT NULL DEFAULT 0 CHECK (readiness_best BETWEEN 0 AND 100),
  tier               VARCHAR(20) NOT NULL DEFAULT 'Novice'
                       CHECK (tier IN ('Novice', 'Developing', 'Proficient', 'Advanced')),
  tasks_completed    INTEGER NOT NULL DEFAULT 0 CHECK (tasks_completed >= 0),
  last_activity_date DATE,
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, track_id)
);

-- Backfill the active track from the mirrored user_progress value, plus the
-- track's passed-task count. Historical attempts elsewhere will be recomputed
-- lazily by refreshReadiness when that track is next opened.
INSERT INTO user_track_progress
  (user_id, track_id, readiness_score, readiness_best, tier, tasks_completed, last_activity_date)
SELECT u.id,
       u.industry_track_id,
       COALESCE(p.readiness_score, 0),
       COALESCE(p.readiness_score, 0),
       COALESCE(p.tier, 'Novice'),
       COALESCE((
         SELECT COUNT(DISTINCT ta.task_id)
         FROM task_attempts ta
         JOIN tasks t ON t.id = ta.task_id
         WHERE ta.user_id = u.id
           AND ta.passed = TRUE
           AND ta.practice = FALSE
           AND t.track_id = u.industry_track_id
       ), 0),
       p.last_activity_date
FROM users u
JOIN user_progress p ON p.user_id = u.id
WHERE u.industry_track_id IS NOT NULL
ON CONFLICT (user_id, track_id) DO NOTHING;

-- The global row keeps xp/level/streak/tokens; mark the mirrored columns so a
-- future read path does not mistake them for the source of truth.
COMMENT ON COLUMN user_progress.readiness_score IS
  'Deprecated mirror of the active track''s user_track_progress.readiness_score. Read user_track_progress.';
COMMENT ON COLUMN user_progress.tier IS
  'Deprecated mirror of the active track''s user_track_progress.tier. Read user_track_progress.';

-- ---------------------------------------------------------------------------
-- user_activity: expose track_id so /history can filter by track
-- ---------------------------------------------------------------------------
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
       ta.submitted_at            AS created_at,
       t.track_id                 AS track_id
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
       aa.submitted_at,
       l.track_id
FROM lab_activity_attempts aa
JOIN lab_activities a ON a.id = aa.activity_id
LEFT JOIN lab_lessons l ON l.id = a.lesson_id
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
       ca.submitted_at,
       c.track_id
FROM lab_capstone_attempts ca
JOIN lab_capstone_assessments c ON c.id = ca.assessment_id
WHERE ca.submitted_at IS NOT NULL;
