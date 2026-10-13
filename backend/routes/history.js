const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { getHistory } = require('../controllers/historyController');

const router = express.Router();

router.get('/', verifyFirebaseToken, getHistory);

module.exports = router;
