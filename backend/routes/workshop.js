const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
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

router.get('/posts', verifyFirebaseToken, listPosts);
router.get('/posts/:id/replies', verifyFirebaseToken, listReplies);
router.post('/posts', verifyFirebaseToken, writeLimit, createPost);
router.post('/posts/:id/react', verifyFirebaseToken, writeLimit, react);
router.post('/posts/:id/report', verifyFirebaseToken, writeLimit, report);
router.delete('/posts/:id', verifyFirebaseToken, writeLimit, deletePost);

module.exports = router;
