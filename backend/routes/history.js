const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { getHistory, getAttempt } = require('../controllers/historyController');

const router = express.Router();

router.get('/', verifyFirebaseToken, getHistory);
router.get('/attempts/:id', verifyFirebaseToken, getAttempt);

module.exports = router;
