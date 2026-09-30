const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { getProgress } = require('../controllers/progressController');

const router = express.Router();
router.get('/me', verifyFirebaseToken, getProgress);
module.exports = router;
