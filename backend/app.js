const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { v4: uuidv4 } = require('uuid');

const healthRoutes = require('./routes/health');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const trackRoutes = require('./routes/tracks');
const taskRoutes = require('./routes/tasks');
const progressRoutes = require('./routes/progress');
const achievementRoutes = require('./routes/achievements');
const leaderboardRoutes = require('./routes/leaderboard');
const interviewRoutes = require('./routes/interview');
const assistantRoutes = require('./routes/assistant');
const errorHandler = require('./middleware/errorHandler');

const app = express();

app.disable('x-powered-by');
app.set('trust proxy', 1);

app.use((req, res, next) => {
  req.requestId = req.headers['x-request-id'] || uuidv4();
  res.setHeader('X-Request-Id', req.requestId);
  next();
});

app.use(helmet());

const allowedOrigins = (process.env.ALLOWED_ORIGINS || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(cors({
  origin(origin, callback) {
    if (!origin || allowedOrigins.length === 0 || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(new Error('CORS origin not allowed'));
  },
}));

app.use(express.json({ limit: '32kb' }));
app.use(express.urlencoded({ extended: false, limit: '16kb' }));

const windowMs = Number(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000;
const max = Number(process.env.RATE_LIMIT_MAX) || 200;
app.use('/api', rateLimit({ windowMs, limit: max, standardHeaders: true, legacyHeaders: false }));

app.get('/', (req, res) => {
  res.status(200).json({
    name: 'VerifAI API',
    version: '2.0.0',
    status: 'ok',
    docs: '/api/docs',
  });
});

app.use('/api/health', healthRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/tracks', trackRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/progress', progressRoutes);
app.use('/api/achievements', achievementRoutes);
app.use('/api/leaderboard', leaderboardRoutes);
app.use('/api/interview', interviewRoutes);
app.use('/api/assistant', assistantRoutes);

app.get('/api/docs', (req, res) => {
  res.json({
    name: 'VerifAI API',
    documentation: 'See backend/API.md in the repository.',
    endpoints: [
      'GET /api/health',
      'POST /api/auth/sync',
      'GET /api/users/me',
      'PUT /api/users/profile',
      'GET /api/tracks',
      'GET /api/tasks/next',
      'POST /api/tasks/:id/attempt',
      'GET /api/progress/me',
      'GET /api/progress/me/activity',
      'GET /api/leaderboard',
      'GET /api/achievements/me',
      'GET /api/achievements',
      'GET /api/achievements/milestones',
      'GET /api/interview/questions',
      'POST /api/interview/questions/:id/practice',
      'POST /api/assistant/chat',
    ],
  });
});

app.use((req, res) => {
  res.status(404).json({
    error: 'Route not found',
    request_id: req.requestId,
  });
});

app.use(errorHandler);

module.exports = app;
