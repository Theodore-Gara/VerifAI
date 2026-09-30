const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { getNextTask, submitAttempt } = require('../controllers/tasksController');

const router = express.Router();
router.get('/next', verifyFirebaseToken, getNextTask);
router.post('/:id/attempt', verifyFirebaseToken, submitAttempt);
module.exports = router;
