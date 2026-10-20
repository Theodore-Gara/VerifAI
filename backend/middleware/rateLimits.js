const rateLimit = require('express-rate-limit');
const { PostgresRateLimitStore } = require('../utils/pgRateStore');

// Per-account limits for authenticated routes. `verifyFirebaseToken` must run
// before these so req.firebaseUser exists.
function uidRateLimit({ windowMs, limit, message, name = 'uid' }) {
  return rateLimit({
    windowMs,
    limit,
    keyGenerator: (req) => req.firebaseUser.uid,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: message },
    // Shared across instances: each limiter gets its own key prefix so the AI
    // budget and the write budget never count against each other.
    store: new PostgresRateLimitStore({ prefix: name }),
  });
}

// Every call costs an LLM request, so AI routes get a much tighter budget.
const aiLimit = uidRateLimit({
  windowMs: 60 * 1000,
  limit: 8,
  message: 'Assistant request limit reached. Try again shortly.',
  name: 'ai',
});

// Posts, replies, reactions, redemptions and progress writes.
const writeLimit = uidRateLimit({
  windowMs: 60 * 1000,
  limit: 30,
  message: 'Too many requests. Try again shortly.',
  name: 'write',
});

module.exports = { uidRateLimit, aiLimit, writeLimit };
