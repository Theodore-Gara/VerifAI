const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { writeLimit } = require('../middleware/rateLimits');
const { listRewards, redeemReward, tokenHistory } = require('../controllers/rewardsController');

const router = express.Router();

router.get('/', verifyFirebaseToken, listRewards);
router.get('/tokens', verifyFirebaseToken, tokenHistory);
router.post('/:code/redeem', verifyFirebaseToken, writeLimit, redeemReward);

module.exports = router;
