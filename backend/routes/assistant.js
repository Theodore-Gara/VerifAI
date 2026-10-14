const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { aiLimit } = require('../middleware/rateLimits');
const { sendMessage, getSession } = require('../controllers/assistantController');

const router = express.Router();

router.post('/chat', verifyFirebaseToken, aiLimit, sendMessage);
router.get('/sessions/:taskId', verifyFirebaseToken, getSession);

module.exports = router;
