const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { getLeaderboard } = require('../controllers/leaderboardController');

const router = express.Router();
router.get('/', verifyFirebaseToken, getLeaderboard);
module.exports = router;