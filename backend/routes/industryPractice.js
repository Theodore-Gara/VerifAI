const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { writeLimit } = require('../middleware/rateLimits');
const { listCases, getCase, markRead } = require('../controllers/industryPracticeController');

const router = express.Router();

router.get('/cases', verifyFirebaseToken, listCases);
router.get('/cases/:id', verifyFirebaseToken, getCase);
router.post('/cases/:id/read', verifyFirebaseToken, writeLimit, markRead);

module.exports = router;
