const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { getAchievements } = require('../controllers/achievementsController');

const router = express.Router();
router.get('/me', verifyFirebaseToken, getAchievements);
module.exports = router;
