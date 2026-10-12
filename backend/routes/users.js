const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { getMe, updateProfile, uploadAvatar, getAvatar } = require('../controllers/usersController');

const router = express.Router();
router.get('/me', verifyFirebaseToken, getMe);
router.put('/profile', verifyFirebaseToken, updateProfile);
router.post('/avatar', verifyFirebaseToken, uploadAvatar);
router.get('/avatar', verifyFirebaseToken, getAvatar);
module.exports = router;
