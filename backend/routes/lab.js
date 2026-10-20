const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { requireAdminAuth } = require('../middleware/admin');
const { requireRole } = require('../middleware/adminRoles');
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
  getAssessmentAnalysis,
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
// Finalising a rubric attempt awards XP, tokens and readiness, so it is a
// reviewer action: admins/moderators only, never the learner whose work it is.
router.post('/assessments/:code/attempts/:id/mark', requireAdminAuth, requireRole('moderator'), writeLimit, markCapstone);
router.post('/assessments/:code/attempts/:id/ai-mark', verifyFirebaseToken, aiLimit, aiMarkCapstone);
router.post('/assessments/:code/attempts/:id/analysis', verifyFirebaseToken, aiLimit, getAssessmentAnalysis);

router.get('/sources', verifyFirebaseToken, listSources);
router.get('/sources/:id', verifyFirebaseToken, getSource);
router.get('/library', verifyFirebaseToken, getLibrary);

router.post('/coach', verifyFirebaseToken, aiLimit, coach);

module.exports = router;
