// Single home for "this learner did something" bookkeeping: XP balance, level,
// reward tokens for levels gained, and the daily streak.
//
// Every graded activity (scored task attempts, AI Lab practice, capstones and
// admin adjustments) goes through here — the task pipeline used to carry a
// second, slightly different copy of this logic, which is how the level could
// desync from the XP balance.
const { calculateLevel } = require('./scoringService');
const { grantTokens, levelGrants } = require('./rewardTokens');
const { computeStreak, STREAK_TIMEZONE } = require('./streak');

// amount === 0 is meaningful: a graded-but-unscored attempt (a failed task)
// marks the day as active without paying out anything. Admin adjustments pass
// advanceStreak: false so a grant never fabricates a study streak.
async function awardXp(client, userId, amount, { advanceStreak = true } = {}) {
  const xp = Math.max(0, Math.floor(Number(amount) || 0));

  const ensured = await client.query(
    `INSERT INTO user_progress (user_id, xp, level)
     VALUES ($1, 0, 1)
     ON CONFLICT (user_id) DO UPDATE SET user_id = EXCLUDED.user_id
     RETURNING id, xp, level, streak, last_activity_date`,
    [userId],
  );
  const row = ensured.rows[0];
  const newXp = Number(row.xp) + xp;
  const newLevel = calculateLevel(newXp);
  const newStreak = advanceStreak ? await computeStreak(client, row) : Number(row.streak) || 0;

  if (newLevel > Number(row.level)) {
    await grantTokens(client, userId, levelGrants(Number(row.level), newLevel));
  }

  const updated = await client.query(
    `UPDATE user_progress
     SET xp = $1, level = $2, streak = $3,
         last_activity_date = CASE WHEN $6::boolean
                                   THEN (NOW() AT TIME ZONE $5)::date
                                   ELSE last_activity_date END,
         updated_at = CURRENT_TIMESTAMP
     WHERE user_id = $4
     RETURNING xp, level, streak, last_activity_date, readiness_score, tier, tokens`,
    [newXp, newLevel, newStreak, userId, STREAK_TIMEZONE, advanceStreak],
  );
  return { ...updated.rows[0], xp_earned: xp };
}

module.exports = { awardXp };
