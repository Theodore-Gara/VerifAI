-- 028_user_activity_view.sql
--
-- The learner timeline (GET /api/history) and the daily activity chart
-- (GET /api/progress/me/activity) each spelled out the same three-way UNION
-- over task_attempts, lab_activity_attempts and lab_capstone_attempts. Two
-- copies drift: adding a column or a filter to one silently made the two views
-- of "what the learner did" disagree.
--
-- One view now defines it. It stays a plain (non-materialised) view so it reads
-- live rows; each caller filters/sorts it as needed.

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
