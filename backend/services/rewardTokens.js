// Reward tokens: a spendable currency earned from milestones. XP is never
// spent; tokens are. Grants are written to an append-only ledger whose
// UNIQUE(user_id, reason, ref) constraint makes them idempotent, so a retried
// submission cannot double-credit.
const XP_PER_LEVEL_TOKENS = Number(process.env.TOKENS_PER_LEVEL) || 10;
const TOKENS_PER_ACHIEVEMENT = Number(process.env.TOKENS_PER_ACHIEVEMENT) || 5;

// Applies each grant, skipping ones already recorded, then adds the net new
// total to the user's balance. Returns the number of tokens actually granted.
async function grantTokens(client, userId, grants) {
  let granted = 0;
  for (const grant of grants) {
    const result = await client.query(
      `INSERT INTO reward_token_events (user_id, delta, reason, ref)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id, reason, ref) DO NOTHING`,
      [userId, grant.delta, grant.reason, grant.ref],
    );
    if (result.rowCount) granted += grant.delta;
  }
  if (granted > 0) {
    await client.query(
      `UPDATE user_progress SET tokens = tokens + $1 WHERE user_id = $2`,
      [granted, userId],
    );
  }
  return granted;
}

// One ledger entry per level gained, keyed by the level number so re-running
// the same attempt credits nothing.
function levelGrants(fromLevel, toLevel) {
  const grants = [];
  for (let level = Number(fromLevel) + 1; level <= Number(toLevel); level++) {
    grants.push({ delta: XP_PER_LEVEL_TOKENS, reason: 'level_up', ref: `level-${level}` });
  }
  return grants;
}

function achievementGrants(achievements) {
  return achievements.map((achievement) => ({
    delta: TOKENS_PER_ACHIEVEMENT,
    reason: 'achievement',
    ref: achievement.code,
  }));
}

module.exports = {
  grantTokens,
  levelGrants,
  achievementGrants,
  XP_PER_LEVEL_TOKENS,
  TOKENS_PER_ACHIEVEMENT,
};
