const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { aiLimit } = require('../middleware/rateLimits');
const { sendMessage } = require('../controllers/assistantController');

const router = express.Router();

router.post('/chat', verifyFirebaseToken, aiLimit, sendMessage);

module.exports = router;
