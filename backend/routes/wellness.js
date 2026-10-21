const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const requireUser = require('../middleware/requireUser');
const { writeLimit } = require('../middleware/rateLimits');
const {
  listMood,
  saveMood,
  listJournal,
  saveJournal,
  deleteJournal,
  restoreJournal,
  listActivities,
  logActivity,
} = require('../controllers/wellnessController');

const router = express.Router();

router.get('/mood', verifyFirebaseToken, requireUser, listMood);
router.put('/mood', verifyFirebaseToken, requireUser, writeLimit, saveMood);
router.get('/journal', verifyFirebaseToken, requireUser, listJournal);
router.put('/journal', verifyFirebaseToken, requireUser, writeLimit, saveJournal);
router.delete('/journal/:date', verifyFirebaseToken, requireUser, writeLimit, deleteJournal);
router.post('/journal/:date/restore', verifyFirebaseToken, requireUser, writeLimit, restoreJournal);
router.get('/activities', verifyFirebaseToken, requireUser, listActivities);
router.post('/activities', verifyFirebaseToken, requireUser, writeLimit, logActivity);

module.exports = router;
