const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { writeLimit } = require('../middleware/rateLimits');
const {
  listMood,
  saveMood,
  listJournal,
  saveJournal,
  listActivities,
  logActivity,
} = require('../controllers/wellnessController');

const router = express.Router();

router.get('/mood', verifyFirebaseToken, listMood);
router.put('/mood', verifyFirebaseToken, writeLimit, saveMood);
router.get('/journal', verifyFirebaseToken, listJournal);
router.put('/journal', verifyFirebaseToken, writeLimit, saveJournal);
router.get('/activities', verifyFirebaseToken, listActivities);
router.post('/activities', verifyFirebaseToken, writeLimit, logActivity);

module.exports = router;
