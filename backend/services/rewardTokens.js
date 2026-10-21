// Reward tokens: a spendable currency earned from milestones. XP is never
// spent; tokens are. Grants are written to an append-only ledger whose
// UNIQUE(user_id, reason, ref) constraint makes them idempotent, so a retried
// submission cannot double-credit.
const XP_PER_LEVEL_TOKENS = Number(process.env.TOKENS_PER_LEVEL) || 10;
const TOKENS_PER_ACHIEVEMENT = Number(process.env.TOKENS_PER_ACHIEVEMENT) || 5;

// Applies every grant in one statement (one round trip instead of N), skipping
// ones already recorded, then adds the net new total to the user's balance.
// Returns the number of tokens actually granted.
async function grantTokens(client, userId, grants) {
  if (!grants || !grants.length) return 0;
  const result = await client.query(
    `WITH pending AS (
       INSERT INTO reward_token_events (user_id, delta, reason, ref)
       SELECT $1, g.delta, g.reason, g.ref
       FROM UNNEST($2::int[], $3::text[], $4::text[]) AS g(delta, reason, ref)
       ON CONFLICT (user_id, reason, ref) DO NOTHING
       RETURNING delta
     ), total AS (
       SELECT COALESCE(SUM(delta), 0)::int AS granted FROM pending
     ), wallet AS (
       UPDATE user_progress
       SET tokens = tokens + (SELECT granted FROM total)
       WHERE user_id = $1 AND (SELECT granted FROM total) > 0
     )
     SELECT granted FROM total`,
    [
      userId,
      grants.map((grant) => grant.delta),
      grants.map((grant) => grant.reason),
      grants.map((grant) => grant.ref),
    ],
  );
  return Number(result.rows[0] && result.rows[0].granted) || 0;
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
