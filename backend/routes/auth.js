const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { syncUser, me } = require('../controllers/authController');

const router = express.Router();
router.post('/sync', verifyFirebaseToken, syncUser);
router.get('/me', verifyFirebaseToken, me);
module.exports = router;
