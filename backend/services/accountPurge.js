// One deletion path for both "delete my account" and the admin GDPR hard
// delete. The database row goes first (FK cascades remove every trace), then
// the Firebase identity.
//
// Order matters: the old self-delete deleted the Firebase identity first, so a
// failed database delete left the PII behind with nobody able to sign in and
// retry. The old admin delete removed only the row, so the person could sign
// straight back in and silently get a fresh empty account.
const pool = require('../db/pool');
const { getFirebaseAuth } = require('../db/firebase');

async function purgeAccount({ userId = null, firebaseUid = null } = {}) {
  const identified = await pool.query(
    `SELECT id, email, firebase_uid
       FROM users
      WHERE ($1::int IS NOT NULL AND id = $1)
         OR ($2::text IS NOT NULL AND firebase_uid = $2)
      LIMIT 1`,
    [userId, firebaseUid],
  );
  const user = identified.rows[0] || null;
  const uid = user?.firebase_uid || firebaseUid || null;

  let hadProfile = false;
  if (user) {
    const deleted = await pool.query('DELETE FROM users WHERE id = $1 RETURNING id', [user.id]);
    hadProfile = deleted.rows.length > 0;
  }

  let firebaseDeleted = false;
  let firebaseError = null;
  if (uid) {
    try {
      await getFirebaseAuth().deleteUser(uid);
      firebaseDeleted = true;
    } catch (err) {
      // Already gone in Firebase is the desired end state.
      if (err.code === 'auth/user-not-found') {
        firebaseDeleted = true;
      } else {
        firebaseError = err.message;
        // The profile is already gone, so this cannot be retried by the user;
        // leave a clear signal for ops instead of failing the request.
        console.error(`Account purge: Firebase identity for user ${user?.id ?? '?'} survived deletion: ${err.message}`);
      }
    }
  }

  return {
    hadProfile,
    email: user?.email ?? null,
    firebaseUid: uid,
    firebaseDeleted,
    firebaseError,
  };
}

module.exports = { purgeAccount };
