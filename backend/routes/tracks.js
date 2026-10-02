const express = require('express');
const { getTracks } = require('../controllers/tracksController');

const router = express.Router();
router.get('/', getTracks);
module.exports = router;
