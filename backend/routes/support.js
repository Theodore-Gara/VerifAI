const express = require('express');
const optionalAuth = require('../middleware/optionalAuth');
const { contactLimit, supportEventLimit } = require('../middleware/rateLimits');
const {
  listHelp, getHelp, listFaqs, listGuides, getGuide, getAbout, getTour, postContact, postEvent,
} = require('../controllers/supportController');

const router = express.Router();

// Support content is public so About and Help can be opened from the login
// screen. optionalAuth only identifies the caller when a valid token is sent
// (so a message or event can be linked to, and deleted with, their account).
router.use(optionalAuth);

router.get('/help', listHelp);
router.get('/help/:slug', getHelp);
router.get('/faqs', listFaqs);
router.get('/industry-guides', listGuides);
router.get('/industry-guides/:slug', getGuide);
router.get('/about', getAbout);
router.get('/tour', getTour);

router.post('/contact', contactLimit, postContact);
router.post('/events', supportEventLimit, postEvent);

module.exports = router;
