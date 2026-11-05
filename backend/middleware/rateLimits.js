const { sendApiError } = require('../utils/apiError');
const rateLimit = require('express-rate-limit');
const { PostgresRateLimitStore } = require('../utils/pgRateStore');
const {
  CONTACT_RATE_PER_HOUR,
  EVENTS_RATE_PER_MINUTE,
} = require('../services/supportLimits');

// Per-account limits for authenticated routes. `verifyFirebaseToken` must run
// before these so req.firebaseUser exists.
function uidRateLimit({ windowMs, limit, message, name = 'uid' }) {
  return rateLimit({
    windowMs,
    limit,
    keyGenerator: (req) => req.firebaseUser.uid,
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => sendApiError(
      req,
      res,
      429,
      'rate_limited',
      message,
      { retryable: true }
    ),
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

// Public support routes work signed out, so they are keyed by the verified
// account when optionalAuth identified one and by client IP otherwise. IPv6
// addresses are masked to their /64 so one client cannot rotate through its own
// subnet (the same rule the global limiter in app.js applies).
function clientKey(req) {
  if (req.firebaseUser && req.firebaseUser.uid) {
    return `user:${req.firebaseUser.uid}`;
  }

  const ip = req.ip || req.socket?.remoteAddress || 'unknown';
  const masked = ip.includes(':')
    ? `${ip.split(':').slice(0, 4).join(':')}::/64`
    : ip;

  return `ip:${masked}`;
}

function clientRateLimit({ windowMs, limit, message, name, handler }) {
  return rateLimit({
    windowMs,
    limit,
    keyGenerator: clientKey,
    standardHeaders: true,
    legacyHeaders: false,
    ...(handler
      ? { handler }
      : {
          handler: (req, res) => sendApiError(
            req,
            res,
            429,
            'rate_limited',
            message,
            { retryable: true }
          ),
        }),
    store: new PostgresRateLimitStore({ prefix: name }),
  });
}

// Contact form: the limit is the exported constant, which GET /api/meta also
// reports. The message is deliberately generic so it does not reveal whether a
// honeypot or the limiter produced a refusal.
const contactLimit = clientRateLimit({
  windowMs: 60 * 60 * 1000,
  limit: CONTACT_RATE_PER_HOUR,
  message: 'Too many messages. Please try again later.',
  name: 'support-contact',
});

// Analytics is best effort: over the limit the event is dropped with a normal
// 202, so a throttled screen never shows an error.
const supportEventLimit = clientRateLimit({
  windowMs: 60 * 1000,
  limit: EVENTS_RATE_PER_MINUTE,
  name: 'support-events',
  handler: (req, res) => res.status(202).json({
    recorded: false,
    request_id: req.requestId,
  }),
});

module.exports = {
  uidRateLimit,
  aiLimit,
  writeLimit,
  clientKey,
  clientRateLimit,
  contactLimit,
  supportEventLimit,
  CONTACT_RATE_PER_HOUR,
};
