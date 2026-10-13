const pool = require('../db/pool');
const { clampInt } = require('../middleware/validate');
const { findUserByFirebaseUid } = require('../db/users');
const { xpForLevel } = require('../services/scoringService');

async function requireUser(res, req) {
  const user = await findUserByFirebaseUid(pool, req.firebaseUser.uid);
  if (!user) {
    res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    return null;
  }
  return user;
}

async function loadWallet(executor, userId) {
  const result = await executor.query(
    `SELECT COALESCE(xp, 0)::int AS xp,
            COALESCE(level, 1)::int AS level,
            COALESCE(tokens, 0)::int AS tokens
     FROM user_progress WHERE user_id = $1`,
    [userId],
  );
  return result.rows[0] || { xp: 0, level: 1, tokens: 0 };
}

function walletView(wallet) {
  return { ...wallet, next_level_xp: xpForLevel(wallet.level + 1) };
}

// GET /api/rewards
async function listRewards(req, res, next) {
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const wallet = await loadWallet(pool, user.id);
    const result = await pool.query(
      `SELECT id, code, title, subtitle, cost_tokens, image_asset, note
       FROM rewards WHERE active = TRUE ORDER BY sort_order, id`,
    );

    const rewards = result.rows.map((reward) => ({
      ...reward,
      can_afford: wallet.tokens >= reward.cost_tokens,
    }));

    return res.status(200).json({ rewards, wallet: walletView(wallet), request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// POST /api/rewards/:code/redeem
// Spends tokens only. XP and level are never touched.
async function redeemReward(req, res, next) {
  let client = null;
  try {
    const user = await requireUser(res, req);
    if (!user) return undefined;

    client = await pool.connect();
    await client.query('BEGIN');

    const rewardResult = await client.query(
      `SELECT id, code, title, cost_tokens FROM rewards WHERE code = $1 AND active = TRUE`,
      [req.params.code],
    );
    if (!rewardResult.rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Reward not found.', request_id: req.requestId });
    }
    const reward = rewardResult.rows[0];

    // Lock the balance row so two concurrent redemptions cannot both pass.
    const progress = await client.query(
      `SELECT tokens FROM user_progress WHERE user_id = $1 FOR UPDATE`,
      [user.id],
    );
    const tokens = progress.rows.length ? progress.rows[0].tokens : 0;
    if (tokens < reward.cost_tokens) {
      await client.query('ROLLBACK');
      return res.status(409).json({
        error: 'Not enough reward tokens.',
        tokens,
        cost_tokens: reward.cost_tokens,
        request_id: req.requestId,
      });
    }

    const redemption = await client.query(
      `INSERT INTO reward_redemptions (user_id, reward_id, cost_tokens, status)
       VALUES ($1, $2, $3, 'confirmed')
       RETURNING id, reward_id, cost_tokens, status, created_at`,
      [user.id, reward.id, reward.cost_tokens],
    );
    await client.query(
      `UPDATE user_progress SET tokens = tokens - $1 WHERE user_id = $2`,
      [reward.cost_tokens, user.id],
    );
    await client.query(
      `INSERT INTO reward_token_events (user_id, delta, reason, ref)
       VALUES ($1, $2, 'redemption', $3)`,
      [user.id, -reward.cost_tokens, `redemption-${redemption.rows[0].id}`],
    );

    await client.query('COMMIT');

    const wallet = await loadWallet(pool, user.id);
    return res.status(201).json({
      redemption: { ...redemption.rows[0], reward_code: reward.code, title: reward.title },
      wallet: walletView(wallet),
      request_id: req.requestId,
    });
  } catch (err) {
    if (client) await client.query('ROLLBACK').catch(() => {});
    return next(err);
  } finally {
    if (client) client.release();
  }
}

// GET /api/rewards/tokens — ledger of token grants and spends
async function tokenHistory(req, res, next) {
  try {
    const limit = clampInt(req.query.limit, 20, 1, 100);
    const user = await requireUser(res, req);
    if (!user) return undefined;

    const result = await pool.query(
      `SELECT id, delta, reason, ref, created_at
       FROM reward_token_events
       WHERE user_id = $1
       ORDER BY created_at DESC, id DESC
       LIMIT $2`,
      [user.id, limit],
    );

    const wallet = await loadWallet(pool, user.id);
    return res.status(200).json({ events: result.rows, wallet: walletView(wallet), request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

module.exports = { listRewards, redeemReward, tokenHistory };
