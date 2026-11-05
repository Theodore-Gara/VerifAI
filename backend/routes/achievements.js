const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { getAchievements, getCatalog, goneMilestones } = require('../controllers/achievementsController');

const router = express.Router();
router.get('/', verifyFirebaseToken, getCatalog);
// Deprecated: the roadmap moved to GET /api/roadmap. 410 for one release.
router.get('/milestones', verifyFirebaseToken, goneMilestones);
router.get('/me', verifyFirebaseToken, getAchievements);
module.exports = router;
