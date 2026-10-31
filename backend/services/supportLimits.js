// Constants for the support surface. They live in one module so the validators,
// the rate limiter and GET /api/meta read the same values and cannot drift.

// Contact form: 5 messages per hour per signed-in account (or per client IP
// when signed out).
const CONTACT_RATE_PER_HOUR = 5;

const CONTACT_CATEGORIES = ['bug', 'account', 'content', 'verification', 'feedback', 'other'];

const CONTACT_LIMITS = {
  nameMin: 1,
  nameMax: 100,
  emailMax: 254,
  subjectMin: 3,
  subjectMax: 150,
  messageMin: 10,
  messageMax: 4000,
  appVersionMax: 40,
};

const EXPECTED_REPLY = '1–2 working days';

// Analytics events are best effort and tolerate a burst from one screen, but a
// runaway client must not fill the table.
const EVENTS_RATE_PER_MINUTE = 60;

// Help and FAQ vocabularies, used to validate admin edits.
const HELP_CATEGORIES = ['start', 'navigation', 'industry', 'features', 'progress', 'troubleshooting'];
const FAQ_TOPICS = ['basics', 'industry', 'onboarding', 'learning', 'verification', 'vera', 'progress', 'account'];
const MESSAGE_STATUSES = ['new', 'in_progress', 'resolved'];

// Retention (scripts/prune-support.js). Environment overrides are for tests and
// for a stricter policy; the defaults are documented in the README.
const RETENTION = {
  resolvedMessageMonths: Number(process.env.SUPPORT_MESSAGE_RETENTION_MONTHS) || 24,
  eventMonths: Number(process.env.SUPPORT_EVENT_RETENTION_MONTHS) || 12,
};

module.exports = {
  CONTACT_RATE_PER_HOUR,
  CONTACT_CATEGORIES,
  CONTACT_LIMITS,
  EXPECTED_REPLY,
  EVENTS_RATE_PER_MINUTE,
  HELP_CATEGORIES,
  FAQ_TOPICS,
  MESSAGE_STATUSES,
  RETENTION,
};
