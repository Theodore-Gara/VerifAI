const express = require('express');
const rateLimit = require('express-rate-limit');
const { verifyFirebaseToken } = require('../middleware/auth');
const { sendMessage } = require('../controllers/assistantController');

const router = express.Router();
const assistantLimit = rateLimit({
  windowMs: 60 * 1000,
  limit: 8,
  keyGenerator: (req) => req.firebaseUser.uid,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Assistant request limit reached. Try again shortly.' },
});

router.post('/chat', verifyFirebaseToken, assistantLimit, sendMessage);

module.exports = router;
