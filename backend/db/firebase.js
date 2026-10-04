const { cert, getApps, initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
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
  if (!getApps().length) {
    const serviceAccount = loadServiceAccount();
    initializeApp({ credential: cert(serviceAccount) });
  }
  return getApps()[0];
}

function getFirebaseAuth() {
  return getAuth(getFirebaseAdmin());
}

module.exports = { getFirebaseAuth };
