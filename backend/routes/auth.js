const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { syncUser } = require('../controllers/authController');

const router = express.Router();
router.post('/sync', verifyFirebaseToken, syncUser);
module.exports = router;
