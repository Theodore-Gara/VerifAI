const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const requireUser = require('../middleware/requireUser');
const { writeLimit } = require('../middleware/rateLimits');
const { listCases, getCase, markRead } = require('../controllers/industryPracticeController');

const router = express.Router();

router.get('/cases', verifyFirebaseToken, requireUser, listCases);
router.get('/cases/:id', verifyFirebaseToken, requireUser, getCase);
router.post('/cases/:id/read', verifyFirebaseToken, requireUser, writeLimit, markRead);

module.exports = router;
