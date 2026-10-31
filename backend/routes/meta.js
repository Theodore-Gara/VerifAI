const express = require('express');
const { getMeta } = require('../controllers/metaController');

const router = express.Router();
router.get('/', getMeta);
module.exports = router;
