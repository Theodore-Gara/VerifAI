const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { getMe, updateProfile } = require('../controllers/usersController');

const router = express.Router();
router.get('/me', verifyFirebaseToken, getMe);
router.put('/profile', verifyFirebaseToken, updateProfile);
module.exports = router;
