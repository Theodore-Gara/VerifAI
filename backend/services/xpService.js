// Awards XP outside the task pipeline (AI Lab practice activities, capstone
// passes). Updates the balance, recomputes the level, credits any reward tokens
// for levels gained, and advances the daily streak so hub actions count.
const { calculateLevel } = require('./scoringService');
const { grantTokens, levelGrants } = require('./rewardTokens');
const { computeStreak, STREAK_TIMEZONE } = require('./streak');

async function awardXp(client, userId, amount) {
  const xp = Math.max(0, Math.floor(Number(amount) || 0));
  if (xp === 0) return null;

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
  const newStreak = await computeStreak(client, row);

  await grantTokens(client, userId, levelGrants(Number(row.level), newLevel));

  const updated = await client.query(
    `UPDATE user_progress
     SET xp = $1, level = $2, streak = $3,
         last_activity_date = (NOW() AT TIME ZONE $5)::date,
         updated_at = CURRENT_TIMESTAMP
     WHERE user_id = $4
     RETURNING xp, level, streak, tokens`,
    [newXp, newLevel, newStreak, userId, STREAK_TIMEZONE],
  );
  return { ...updated.rows[0], xp_earned: xp };
}

module.exports = { awardXp };
