const express = require('express');
const optionalAuth = require('../middleware/optionalAuth');
const { verifyFirebaseToken } = require('../middleware/auth');
const { contactLimit, supportEventLimit } = require('../middleware/rateLimits');
const {
  listHelp, getHelp, listFaqs, listGuides, getGuide, getAbout, getTour, postContact, postEvent,
  listMyTickets, getMyTicket, markMyTicketRead, getMyUnreadCount,
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

// Signed-in users can read their own ticket conversations. Admin replies are
// read-only for now; the schema supports user replies for a later release.
router.get('/tickets', verifyFirebaseToken, listMyTickets);
router.get('/tickets/unread-count', verifyFirebaseToken, getMyUnreadCount);
router.get('/tickets/:ref', verifyFirebaseToken, getMyTicket);
router.post('/tickets/:ref/read', verifyFirebaseToken, markMyTicketRead);

router.post('/contact', contactLimit, postContact);
router.post('/events', supportEventLimit, postEvent);

module.exports = router;
