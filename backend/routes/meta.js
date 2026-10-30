const express = require('express');
const router = express.Router();

// GET /api/meta — public app metadata: the client's rate budgets, the error
// codes the API can return, and build info. Unauthenticated by design: it
// tells the app how to behave before the learner signs in.
//
// The limits mirror middleware/rateLimits.js. Keep the two in agreement:
// this route reads nothing at runtime, it documents the constants.
const AI_LIMIT_PER_MINUTE = 8;
const WRITE_LIMIT_PER_MINUTE = 30;

const ERROR_CODES = {
  AI_UNAVAILABLE: 'An AI service is briefly unavailable. Try again shortly.',
  AI_RATE_LIMITED: 'AI request limit reached. Try again shortly.',
  ACCOUNT_SUSPENDED: 'Your account is suspended.',
  ACCOUNT_BANNED: 'Your account is banned.',
  MAINTENANCE_MODE: 'VerifAI is briefly offline for scheduled maintenance.',
  VALIDATION_ERROR: 'The request was not valid.',
  NOT_FOUND: 'That item does not exist (or is not available on your track).',
  RATE_LIMITED: 'Too many requests. Slow down and try again shortly.',
};

router.get('/', (req, res) => {
  res.status(200).json({
    app: 'VerifAI',
    limits: {
      ai_requests_per_minute: AI_LIMIT_PER_MINUTE,
      write_requests_per_minute: WRITE_LIMIT_PER_MINUTE,
    },
    error_codes: ERROR_CODES,
    request_id: req.requestId,
  });
});

module.exports = router;