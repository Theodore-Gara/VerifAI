const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { getDashboard } = require('../controllers/dashboardController');

const router = express.Router();
router.get('/', verifyFirebaseToken, getDashboard);
module.exports = router;
