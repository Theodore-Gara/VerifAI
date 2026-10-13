const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { aiLimit } = require('../middleware/rateLimits');
const { analyzeVerification, listAnalyses } = require('../controllers/verificationController');

const router = express.Router();

router.post('/analyze', verifyFirebaseToken, aiLimit, analyzeVerification);
router.get('/analyses', verifyFirebaseToken, listAnalyses);

module.exports = router;
