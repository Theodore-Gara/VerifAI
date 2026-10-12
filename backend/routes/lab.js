const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { aiLimit, writeLimit } = require('../middleware/rateLimits');
const {
  listLessons,
  getLesson,
  recordProgress,
  submitAssessment,
  coach,
} = require('../controllers/labController');

const router = express.Router();

router.get('/lessons', verifyFirebaseToken, listLessons);
router.get('/lessons/:code', verifyFirebaseToken, getLesson);
router.post('/lessons/:code/progress', verifyFirebaseToken, writeLimit, recordProgress);
router.post('/lessons/:code/assessment', verifyFirebaseToken, writeLimit, submitAssessment);
router.post('/coach', verifyFirebaseToken, aiLimit, coach);

module.exports = router;
