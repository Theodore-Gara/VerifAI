const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

function loadServiceAccount() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    try {
      return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
    } catch (err) {
      throw new Error(`FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON: ${err.message}`);
    }
  }

  const filePath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './firebase-service-account.json';
  const resolved = path.resolve(filePath);

  if (!fs.existsSync(resolved)) {
    throw new Error(
      `Firebase service account not found at ${resolved}. Set FIREBASE_SERVICE_ACCOUNT_PATH ` +
      `or FIREBASE_SERVICE_ACCOUNT_JSON.`
    );
  }

  return JSON.parse(fs.readFileSync(resolved, 'utf8'));
}

function getFirebaseAdmin() {
  if (!admin.apps.length) {
    const serviceAccount = loadServiceAccount();
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  }
  return admin;
}

module.exports = { getFirebaseAdmin };
