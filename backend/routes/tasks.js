const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { getNextTask, submitAttempt, getHistory } = require('../controllers/tasksController');

const router = express.Router();
router.get('/next', verifyFirebaseToken, getNextTask);
router.get('/history', verifyFirebaseToken, getHistory);
router.post('/:id/attempt', verifyFirebaseToken, submitAttempt);
module.exports = router;
