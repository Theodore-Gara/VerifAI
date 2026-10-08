const express = require('express');
const { verifyFirebaseToken } = require('../middleware/auth');
const { getQuestions, markPracticed } = require('../controllers/interviewController');

const router = express.Router();
router.get('/questions', verifyFirebaseToken, getQuestions);
router.post('/questions/:id/practice', verifyFirebaseToken, markPracticed);
module.exports = router;