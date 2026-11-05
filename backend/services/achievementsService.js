// Achievement awarding, shared by every path that can move a threshold:
// task submission, capstone submission, AI Lab activity grading and the daily
// streak/XP rollover (awardXp). Keeping it in one place is what makes a badge
// arrive at the same moment the dashboard shows the qualifying value (BF-9).
//
// The insert is idempotent twice over: `NOT EXISTS` filters already-earned rows
// and `ON CONFLICT DO NOTHING` absorbs a concurrent award. Token grants are
// keyed on the achievement code, so a double call cannot double-credit.
const { grantTokens, achievementGrants } = require('./rewardTokens');

async function awardAchievements(client, userId) {
  const earned = await client.query(
    `WITH stats AS (
       SELECT
         (SELECT COUNT(DISTINCT task_id)::int
            FROM task_attempts WHERE user_id = $1 AND passed AND practice = FALSE) AS passed_tasks,
         (SELECT COUNT(DISTINCT t.feature)::int
            FROM task_attempts ta JOIN tasks t ON t.id = ta.task_id
           WHERE ta.user_id = $1 AND ta.passed AND ta.practice = FALSE
             AND t.feature IN ('verification', 'judgement', 'risk_governance')) AS features_passed,
         (SELECT COUNT(DISTINCT ta.task_id)::int
            FROM task_attempts ta JOIN tasks t ON t.id = ta.task_id
           WHERE ta.user_id = $1 AND ta.passed AND ta.practice = FALSE
             AND t.feature = 'verification') AS verification_passed,
         (SELECT COUNT(DISTINCT ta.task_id)::int
            FROM task_attempts ta JOIN tasks t ON t.id = ta.task_id
           WHERE ta.user_id = $1 AND ta.passed AND ta.practice = FALSE
             AND t.feature = 'judgement') AS judgement_passed,
         (SELECT COUNT(DISTINCT ta.task_id)::int
            FROM task_attempts ta JOIN tasks t ON t.id = ta.task_id
           WHERE ta.user_id = $1 AND ta.passed AND ta.practice = FALSE
             AND t.feature = 'risk_governance') AS risk_passed,
         -- XP/level/streak come from user_progress: that is the number the
         -- dashboard shows and it includes capstone/activity/reward XP.
         (SELECT COALESCE(xp, 0) FROM user_progress WHERE user_id = $1) AS xp,
         (SELECT COALESCE(level, 1) FROM user_progress WHERE user_id = $1) AS level,
         (SELECT COALESCE(streak, 0) FROM user_progress WHERE user_id = $1) AS streak,
         (SELECT industry_track_id FROM users WHERE id = $1) AS track_id,
         (SELECT COUNT(*)::int FROM tasks t
           WHERE t.published
             AND t.track_id = (SELECT industry_track_id FROM users WHERE id = $1)) AS track_total,
         (SELECT COUNT(DISTINCT ta.task_id)::int
            FROM task_attempts ta JOIN tasks t ON t.id = ta.task_id
           WHERE ta.user_id = $1 AND ta.passed AND ta.practice = FALSE
             AND t.published
             AND t.track_id = (SELECT industry_track_id FROM users WHERE id = $1)) AS track_passed,
         (SELECT COUNT(*)::int FROM lab_capstone_attempts
           WHERE user_id = $1 AND passed) AS capstones_passed,
         (SELECT COUNT(*)::int FROM interview_practice WHERE user_id = $1) AS interview_practised
     ), eligible AS (
       SELECT a.id, a.code, a.name, a.description
       FROM achievements a, stats s
       WHERE ((a.code = 'first-task' AND s.passed_tasks >= 1)
          OR (a.code = 'five-tasks' AND s.passed_tasks >= 5)
          OR (a.code = 'ten-tasks' AND s.passed_tasks >= 10)
          OR (a.code = 'xp-250' AND s.xp >= 250)
          OR (a.code = 'xp-500' AND s.xp >= 500)
          OR (a.code = 'xp-1000' AND s.xp >= 1000)
          OR (a.code = 'xp-2000' AND s.xp >= 2000)
          OR (a.code = 'dimension-80' AND s.track_id IS NOT NULL
              AND (SELECT COALESCE(MAX(score), 0) FROM skill_scores
                    WHERE user_id = $1 AND track_id = s.track_id) >= 80)
          OR (a.code = 'streak-7' AND s.streak >= 7)
          OR (a.code = 'streak-30' AND s.streak >= 30)
          OR (a.code = 'level-5' AND s.level >= 5)
          OR (a.code = 'all-features' AND s.features_passed >= 3)
          OR (a.code = 'verification-10' AND s.verification_passed >= 10)
          OR (a.code = 'judgement-10' AND s.judgement_passed >= 10)
          OR (a.code = 'risk-10' AND s.risk_passed >= 10)
          OR (a.code = 'capstone-1' AND s.capstones_passed >= 1)
          OR (a.code = 'interview-5' AND s.interview_practised >= 5)
          -- Track Master is per active track: completing Finance must never
          -- award the Legal variant.
          OR (a.code = 'track-master' AND s.track_id IS NOT NULL
              AND s.track_total > 0 AND s.track_passed >= s.track_total))
         AND NOT EXISTS (
           SELECT 1 FROM user_achievements ua
            WHERE ua.user_id = $1 AND ua.achievement_id = a.id
         )
     ), inserted AS (
       INSERT INTO user_achievements (user_id, achievement_id)
       SELECT $1, id FROM eligible
       ON CONFLICT DO NOTHING
       RETURNING achievement_id
     )
     SELECT e.id, e.code, e.name, e.description
     FROM eligible e JOIN inserted i ON i.achievement_id = e.id`,
    [userId],
  );

  const newlyEarned = earned.rows;
  if (newlyEarned.length) {
    await grantTokens(client, userId, achievementGrants(newlyEarned));
  }
  return newlyEarned;
}

module.exports = { awardAchievements };
