const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const requireUser = require('../middleware/requireUser');
const { getRoadmap } = require('../controllers/roadmapController');

const router = express.Router();
router.get('/', verifyFirebaseToken, requireUser, getRoadmap);
module.exports = router;
