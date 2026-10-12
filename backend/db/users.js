// Resolves the authenticated Firebase uid to the local user row. Accepts a
// pool or an in-transaction client (`executor`), so it works for both.
async function findUserByFirebaseUid(executor, firebaseUid) {
  const result = await executor.query(
    `SELECT id, industry_track_id FROM users WHERE firebase_uid = $1`,
    [firebaseUid],
  );
  return result.rows[0] || null;
}

module.exports = { findUserByFirebaseUid };
