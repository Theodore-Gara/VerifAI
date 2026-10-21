const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const requireUser = require('../middleware/requireUser');
const { writeLimit } = require('../middleware/rateLimits');
const {
  listPosts,
  listReplies,
  createPost,
  react,
  report,
  deletePost,
} = require('../controllers/workshopController');

const router = express.Router();

router.get('/posts', verifyFirebaseToken, requireUser, listPosts);
router.get('/posts/:id/replies', verifyFirebaseToken, requireUser, listReplies);
router.post('/posts', verifyFirebaseToken, requireUser, writeLimit, createPost);
router.post('/posts/:id/react', verifyFirebaseToken, requireUser, writeLimit, react);
router.post('/posts/:id/report', verifyFirebaseToken, requireUser, writeLimit, report);
router.delete('/posts/:id', verifyFirebaseToken, requireUser, writeLimit, deletePost);

module.exports = router;
