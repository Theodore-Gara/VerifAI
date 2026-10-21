const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const requireUser = require('../middleware/requireUser');
const { getHistory, getAttempt } = require('../controllers/historyController');

const router = express.Router();

router.get('/', verifyFirebaseToken, requireUser, getHistory);
router.get('/attempts/:id', verifyFirebaseToken, requireUser, getAttempt);

module.exports = router;
