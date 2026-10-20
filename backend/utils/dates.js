// Calendar-date helpers anchored to the deployment's activity timezone
// (STREAK_TIMEZONE). Analytics and streak logic must agree on what "today" is,
// so the date a row belongs to is computed here and stored in a plain DATE
// column instead of being derived per row at query time.
const { STREAK_TIMEZONE } = require('../services/streak');

const formatter = new Intl.DateTimeFormat('en-CA', {
  timeZone: STREAK_TIMEZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
});

/** YYYY-MM-DD for `date` (default: now) in the activity timezone. */
function activityDate(date = new Date()) {
  const value = date instanceof Date ? date : new Date(date);
  if (Number.isNaN(value.getTime())) return null;
  return formatter.format(value);
}

/** YYYY-MM-DD shifted by `days`, in the activity timezone. */
function activityDateOffset(days) {
  const now = new Date(Date.now() + days * 24 * 60 * 60 * 1000);
  return activityDate(now);
}

module.exports = { activityDate, activityDateOffset, ACTIVITY_TIMEZONE: STREAK_TIMEZONE };
