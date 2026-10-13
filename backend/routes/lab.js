const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { aiLimit, writeLimit } = require('../middleware/rateLimits');
const {
  listLessons,
  getNextLesson,
  getLesson,
  recordProgress,
  submitAssessment,
  submitActivity,
  listAssessments,
  startAssessment,
  submitCapstone,
  getAssessmentPaper,
  markCapstone,
  aiMarkCapstone,
  listSources,
  getSource,
  getLibrary,
  coach,
} = require('../controllers/labController');

const router = express.Router();

router.get('/lessons', verifyFirebaseToken, listLessons);
// `next` must precede `:code` so it is not captured as a lesson code.
router.get('/lessons/next', verifyFirebaseToken, getNextLesson);
router.get('/lessons/:code', verifyFirebaseToken, getLesson);
router.post('/lessons/:code/progress', verifyFirebaseToken, writeLimit, recordProgress);
router.post('/lessons/:code/assessment', verifyFirebaseToken, writeLimit, submitAssessment);
router.post('/activities/:id/attempt', verifyFirebaseToken, writeLimit, submitActivity);

router.get('/assessments', verifyFirebaseToken, listAssessments);
router.get('/assessments/:code', verifyFirebaseToken, getAssessmentPaper);
router.post('/assessments/:code/start', verifyFirebaseToken, writeLimit, startAssessment);
router.post('/assessments/:code/submit', verifyFirebaseToken, writeLimit, submitCapstone);
router.post('/assessments/:code/attempts/:id/mark', verifyFirebaseToken, writeLimit, markCapstone);
router.post('/assessments/:code/attempts/:id/ai-mark', verifyFirebaseToken, aiLimit, aiMarkCapstone);

router.get('/sources', verifyFirebaseToken, listSources);
router.get('/sources/:id', verifyFirebaseToken, getSource);
router.get('/library', verifyFirebaseToken, getLibrary);

router.post('/coach', verifyFirebaseToken, aiLimit, coach);

module.exports = router;
