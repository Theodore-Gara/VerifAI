const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { getProgress, getActivityHistory } = require('../controllers/progressController');

const router = express.Router();
router.get('/me', verifyFirebaseToken, getProgress);
router.get('/me/activity', verifyFirebaseToken, getActivityHistory);
module.exports = router;
