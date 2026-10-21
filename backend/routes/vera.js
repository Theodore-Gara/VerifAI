const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const requireUser = require('../middleware/requireUser');
const { aiLimit, writeLimit } = require('../middleware/rateLimits');
const {
  chat,
  listSessions,
  getSession,
  listMemory,
  addMemory,
  deleteMemory,
  tips,
} = require('../controllers/veraController');

const router = express.Router();

router.post('/chat', verifyFirebaseToken, requireUser, aiLimit, chat);
router.get('/sessions', verifyFirebaseToken, requireUser, listSessions);
router.get('/sessions/:id', verifyFirebaseToken, requireUser, getSession);
router.get('/memory', verifyFirebaseToken, requireUser, listMemory);
router.post('/memory', verifyFirebaseToken, requireUser, writeLimit, addMemory);
router.delete('/memory/:id', verifyFirebaseToken, requireUser, writeLimit, deleteMemory);
router.get('/tips', verifyFirebaseToken, requireUser, tips);

module.exports = router;
