// Streak day-counting, shared so every activity (tasks, AI Lab practice,
// capstones) advances the same daily streak. Days are anchored to the
// configured timezone, not the database server clock (usually UTC).
const STREAK_TIMEZONE = process.env.STREAK_TIMEZONE || 'Africa/Johannesburg';

// Given the current progress row ({ id, streak, last_activity_date }), returns
// the streak after an activity today.
// The pure half, so callers that already fetched the day gap (awardXp reads it
// in the same statement as the progress row) do not need another round trip.
function streakFromGap(progress, rawGap) {
  if (!progress || progress.last_activity_date == null) return 1;
  const gap = Number(rawGap);
  // An unreadable gap keeps the current streak rather than resetting it.
  if (!Number.isFinite(gap)) return Number(progress.streak) || 1;
  if (gap <= 0) return Number(progress.streak) || 1;
  if (gap === 1) return (Number(progress.streak) || 0) + 1;
  return 1;
}

async function computeStreak(client, progress) {
  if (!progress.last_activity_date) return 1;
  const result = await client.query(
    `SELECT (NOW() AT TIME ZONE $2)::date - last_activity_date AS day_gap
     FROM user_progress WHERE id = $1`,
    [progress.id, STREAK_TIMEZONE],
  );
  return streakFromGap(progress, result.rows[0]?.day_gap);
}

module.exports = { computeStreak, streakFromGap, STREAK_TIMEZONE };
