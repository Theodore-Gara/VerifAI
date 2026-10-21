// Resolves the authenticated Firebase uid to the local user row. Accepts a
// pool or an in-transaction client (`executor`), so it works for both.
//
// The row carries the display name and track name as well: those are read by
// the assistant and profile paths, and fetching them here means the shared
// requireUser middleware can serve every feature router with one query.
async function findUserByFirebaseUid(executor, firebaseUid) {
  const result = await executor.query(
    `/* find_user_by_uid */
     SELECT u.id, u.industry_track_id, u.display_name, u.created_at,
            t.name AS track_name
     FROM users u
     LEFT JOIN industry_tracks t ON t.id = u.industry_track_id
     WHERE u.firebase_uid = $1`,
    [firebaseUid],
  );
  return result.rows[0] || null;
}

module.exports = { findUserByFirebaseUid };
