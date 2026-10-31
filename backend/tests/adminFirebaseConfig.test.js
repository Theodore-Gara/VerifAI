const assert = require('node:assert/strict');
const { test } = require('node:test');
const request = require('supertest');
const app = require('../app');

test('admin Firebase config is served from runtime configuration', async () => {
  const originalKey = process.env.FIREBASE_WEB_API_KEY;

  try {
    delete process.env.FIREBASE_WEB_API_KEY;
    const unavailable = await request(app).get('/admin/firebase-config.js');
    assert.equal(unavailable.status, 200);
    assert.match(unavailable.headers['cache-control'], /no-store/);
    assert.match(unavailable.text, /window\.verifaiFirebaseConfig = null/);

    process.env.FIREBASE_WEB_API_KEY = 'test-firebase-web-key';
    const configured = await request(app).get('/admin/firebase-config.js');
    assert.equal(configured.status, 200);
    assert.match(configured.headers['content-type'], /javascript/);
    assert.match(configured.text, /test-firebase-web-key/);
    assert.match(configured.text, /"projectId":"verif-ai-5a435"/);
  } finally {
    if (originalKey === undefined) delete process.env.FIREBASE_WEB_API_KEY;
    else process.env.FIREBASE_WEB_API_KEY = originalKey;
  }
});
