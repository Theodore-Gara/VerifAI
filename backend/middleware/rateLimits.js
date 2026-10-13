const rateLimit = require('express-rate-limit');

// Per-account limits for authenticated routes. `verifyFirebaseToken` must run
// before these so req.firebaseUser exists.
function uidRateLimit({ windowMs, limit, message }) {
  return rateLimit({
    windowMs,
    limit,
    keyGenerator: (req) => req.firebaseUser.uid,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: message },
  });
}

// Every call costs an LLM request, so AI routes get a much tighter budget.
const aiLimit = uidRateLimit({
  windowMs: 60 * 1000,
  limit: 8,
  message: 'Assistant request limit reached. Try again shortly.',
});

// Posts, replies, reactions, redemptions and progress writes.
const writeLimit = uidRateLimit({
  windowMs: 60 * 1000,
  limit: 30,
  message: 'Too many requests. Try again shortly.',
});

module.exports = { uidRateLimit, aiLimit, writeLimit };
