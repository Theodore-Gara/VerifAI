// API contract tests use mocked dependencies so they run without real Firebase or PostgreSQL credentials.
jest.mock('../db/firebase', () => ({
  getFirebaseAdmin: () => ({
    auth: () => ({
      verifyIdToken: jest.fn(async () => ({ uid: 'test-uid', email: 'test@example.com', name: 'Test User' })),
    }),
  }),
}));

jest.mock('../db/pool', () => ({
  query: jest.fn(async (sql) => {
    if (sql.includes('SELECT 1')) return { rows: [{ '?column?': 1 }] };
    if (sql.includes('FROM industry_tracks')) return { rows: [{ id: 1, name: 'Finance', description: 'Finance' }] };
    return { rows: [] };
  }),
  connect: jest.fn(),
  end: jest.fn(async () => {}),
}));

const request = require('supertest');
const app = require('../app');

describe('VerifAI API contract', () => {
  test('GET / returns API metadata', async () => {
    const response = await request(app).get('/');
    expect(response.status).toBe(200);
    expect(response.body.name).toBe('VerifAI API');
  });

  test('GET /api/docs returns documented endpoints', async () => {
    const response = await request(app).get('/api/docs');
    expect(response.status).toBe(200);
    expect(response.body.endpoints).toContain('POST /api/tasks/:id/attempt');
  });

  test('GET /api/health reports database connectivity', async () => {
    const response = await request(app).get('/api/health');
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('ok');
    expect(response.body.db).toBe('connected');
    expect(response.headers['x-request-id']).toBeDefined();
  });

  test('GET /api/tracks returns tracks', async () => {
    const response = await request(app).get('/api/tracks');
    expect(response.status).toBe(200);
    expect(response.body.tracks).toHaveLength(1);
  });

  test('protected endpoint rejects missing Firebase token', async () => {
    const response = await request(app).get('/api/tasks/next');
    expect(response.status).toBe(401);
    expect(response.body.error).toMatch(/Authorization/);
  });

  test('attempt endpoint rejects malformed task id before database access', async () => {
    const response = await request(app)
      .post('/api/tasks/not-a-number/attempt')
      .set('Authorization', 'Bearer test-token')
      .send({ answer: 'test' });
    expect(response.status).toBe(400);
    expect(response.body.error).toMatch(/positive integer/);
  });

  test('unknown routes return 404', async () => {
    const response = await request(app).get('/api/does-not-exist');
    expect(response.status).toBe(404);
    expect(response.body.error).toBe('Route not found');
  });
});
