const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
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

router.post('/chat', verifyFirebaseToken, aiLimit, chat);
router.get('/sessions', verifyFirebaseToken, listSessions);
router.get('/sessions/:id', verifyFirebaseToken, getSession);
router.get('/memory', verifyFirebaseToken, listMemory);
router.post('/memory', verifyFirebaseToken, writeLimit, addMemory);
router.delete('/memory/:id', verifyFirebaseToken, writeLimit, deleteMemory);
router.get('/tips', verifyFirebaseToken, tips);

module.exports = router;
