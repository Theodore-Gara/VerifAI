const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const requireUser = require('../middleware/requireUser');
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

router.get('/lessons', verifyFirebaseToken, requireUser, listLessons);
// `next` must precede `:code` so it is not captured as a lesson code.
router.get('/lessons/next', verifyFirebaseToken, requireUser, getNextLesson);
router.get('/lessons/:code', verifyFirebaseToken, requireUser, getLesson);
router.post('/lessons/:code/progress', verifyFirebaseToken, requireUser, writeLimit, recordProgress);
router.post('/lessons/:code/assessment', verifyFirebaseToken, requireUser, writeLimit, submitAssessment);
router.post('/activities/:id/attempt', verifyFirebaseToken, requireUser, writeLimit, submitActivity);

router.get('/assessments', verifyFirebaseToken, requireUser, listAssessments);
router.get('/assessments/:code', verifyFirebaseToken, requireUser, getAssessmentPaper);
router.post('/assessments/:code/start', verifyFirebaseToken, requireUser, writeLimit, startAssessment);
router.post('/assessments/:code/submit', verifyFirebaseToken, requireUser, writeLimit, submitCapstone);
// Finalising a rubric attempt awards XP, tokens and readiness, so it is a
// reviewer action: admins/moderators only, never the learner whose work it is.
router.post('/assessments/:code/attempts/:id/mark', requireAdminAuth, requireRole('moderator'), writeLimit, markCapstone);
router.post('/assessments/:code/attempts/:id/ai-mark', verifyFirebaseToken, requireUser, aiLimit, aiMarkCapstone);
router.post('/assessments/:code/attempts/:id/analysis', verifyFirebaseToken, requireUser, aiLimit, getAssessmentAnalysis);

router.get('/sources', verifyFirebaseToken, requireUser, listSources);
router.get('/sources/:id', verifyFirebaseToken, requireUser, getSource);
router.get('/library', verifyFirebaseToken, requireUser, getLibrary);

router.post('/coach', verifyFirebaseToken, requireUser, aiLimit, coach);

module.exports = router;
