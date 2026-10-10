const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { getAchievements, getCatalog, getMilestones } = require('../controllers/achievementsController');

const router = express.Router();
router.get('/', verifyFirebaseToken, getCatalog);
router.get('/milestones', verifyFirebaseToken, getMilestones);
router.get('/me', verifyFirebaseToken, getAchievements);
module.exports = router;
