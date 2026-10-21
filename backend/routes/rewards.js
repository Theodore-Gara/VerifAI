const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const requireUser = require('../middleware/requireUser');
const { writeLimit } = require('../middleware/rateLimits');
const { listRewards, redeemReward, tokenHistory } = require('../controllers/rewardsController');

const router = express.Router();

router.get('/', verifyFirebaseToken, requireUser, listRewards);
router.get('/tokens', verifyFirebaseToken, requireUser, tokenHistory);
router.post('/:code/redeem', verifyFirebaseToken, requireUser, writeLimit, redeemReward);

module.exports = router;
