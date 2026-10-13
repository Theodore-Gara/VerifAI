// Awards XP outside the task pipeline (e.g. passing an AI Lab practice
// activity). Updates the balance, recomputes the level and credits any reward
// tokens for levels gained. Streak and tier are intentionally left to tasks.
const { calculateLevel } = require('./scoringService');
const { grantTokens, levelGrants } = require('./rewardTokens');

async function awardXp(client, userId, amount) {
  const xp = Math.max(0, Math.floor(Number(amount) || 0));
  if (xp === 0) return null;

  const ensured = await client.query(
    `INSERT INTO user_progress (user_id, xp, level)
     VALUES ($1, 0, 1)
     ON CONFLICT (user_id) DO UPDATE SET user_id = EXCLUDED.user_id
     RETURNING xp, level`,
    [userId],
  );
  const currentXp = Number(ensured.rows[0].xp);
  const currentLevel = Number(ensured.rows[0].level);
  const newXp = currentXp + xp;
  const newLevel = calculateLevel(newXp);

  await grantTokens(client, userId, levelGrants(currentLevel, newLevel));

  const updated = await client.query(
    `UPDATE user_progress
     SET xp = $1, level = $2, updated_at = CURRENT_TIMESTAMP
     WHERE user_id = $3
     RETURNING xp, level, tokens`,
    [newXp, newLevel, userId],
  );
  return { ...updated.rows[0], xp_earned: xp };
}

module.exports = { awardXp };
