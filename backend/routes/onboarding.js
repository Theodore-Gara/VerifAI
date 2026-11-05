const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { getTourState, putTourState } = require('../controllers/onboardingController');

const router = express.Router();
router.get('/tour', verifyFirebaseToken, getTourState);
router.put('/tour', verifyFirebaseToken, putTourState);
module.exports = router;
