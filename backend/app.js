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
const verificationRoutes = require('./routes/verification');
const labRoutes = require('./routes/lab');
const workshopRoutes = require('./routes/workshop');
const rewardsRoutes = require('./routes/rewards');
const veraRoutes = require('./routes/vera');
const industryPracticeRoutes = require('./routes/industryPractice');
const historyRoutes = require('./routes/history');
const adminRoutes = require('./routes/admin');
const { maintenanceGate } = require('./middleware/adminRoles');
const errorHandler = require('./middleware/errorHandler');

const app = express();

app.disable('x-powered-by');
// The client sits behind Cloudflare AND Render's load balancer, so the real
// client IP is two trusted hops away. With 1, req.ip resolved to a Cloudflare
// edge address that varies per request, which defeated per-IP rate limiting
// entirely: the counter never went down monotonically.
app.set('trust proxy', 2);

app.use((req, res, next) => {
  req.requestId = req.headers['x-request-id'] || uuidv4();
  res.setHeader('X-Request-Id', req.requestId);
  next();
});

app.use(helmet());

// The admin dashboard is a single-page app with an inline script, so it needs
// a CSP that allows same-origin + inline scripts. Scoped to /admin only; the
// API keeps helmet's strict default.
app.use('/admin', helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      connectSrc: ["'self'", 'https://*.googleapis.com', 'https://*.firebaseapp.com'],
      imgSrc: ["'self'", 'data:'],
    },
  },
  crossOriginResourcePolicy: false,
}));

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

// Path-scoped parsers run first so avatar images and long documents are not
// capped by the small global limit; body-parser skips paths already parsed.
// The verification route accepts a 10MB document (base64 inflates it ~33%), so
// it gets a 14MB ceiling.
app.use(['/api/users/avatar'], express.json({ limit: '3mb' }));
app.use(['/api/verification/analyze'], express.json({ limit: '14mb' }));
app.use(express.json({ limit: '32kb' }));
app.use(express.urlencoded({ extended: false, limit: '16kb' }));

// Rate limits are counted per account, not per IP. The client is a signed-in
// mobile app, and shared proxy addresses meant one busy client could throttle
// everyone else (and the health checks).
//
// The bearer token's payload is decoded WITHOUT verifying its signature. That
// is deliberate: this only decides which bucket a request counts against, never
// whether it is allowed - verifyFirebaseToken still gates every protected
// route, and a forged uid would only earn the sender its own fresh bucket.
function rateLimitKey(req) {
  const [scheme, token] = (req.headers.authorization || '').split(' ');
  if (scheme === 'Bearer' && token) {
    const payload = token.split('.')[1];
    if (payload) {
      try {
        const claims = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
        const uid = claims.user_id || claims.sub;
        if (uid) return `user:${uid}`;
      } catch {
        // Malformed token - fall through to the IP bucket.
      }
    }
  }
  const ip = req.ip || req.socket?.remoteAddress || 'unknown';
  // Mask IPv6 to its /64 so one client cannot rotate through its own subnet.
  const masked = ip.includes(':')
    ? `${ip.split(':').slice(0, 4).join(':')}::/64`
    : ip;
  return `ip:${masked}`;
}

// Health checks are polled by Render to decide whether a deploy is healthy, so
// they must never be rate limited: a 429 here marks the service unhealthy,
// which restarts it and causes the cold starts clients then see.
app.use('/api/health', healthRoutes);

// A generous per-account backstop. Task and progress routes are the point of
// the app, so they are not tightly limited; the assistant keeps its own, much
// stricter limit because every call costs an LLM request.
const windowMs = Number(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000;
const max = Number(process.env.RATE_LIMIT_MAX) || 600;
app.use('/api', rateLimit({
  windowMs,
  limit: max,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: rateLimitKey,
}));

app.get('/', (req, res) => {
  res.status(200).json({
    name: 'VerifAI API',
    version: '2.0.0',
    status: 'ok',
    docs: '/api/docs',
  });
});

// Maintenance mode: when switched on from the admin dashboard, learner-facing
// API traffic is refused with 503. Health, auth (so admins can still sign in
// to turn it off) and admin routes stay live.
app.use(maintenanceGate);

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/tracks', trackRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/progress', progressRoutes);
app.use('/api/achievements', achievementRoutes);
app.use('/api/leaderboard', leaderboardRoutes);
app.use('/api/interview', interviewRoutes);
app.use('/api/assistant', assistantRoutes);
app.use('/api/verification', verificationRoutes);
app.use('/api/lab', labRoutes);
app.use('/api/workshop', workshopRoutes);
app.use('/api/rewards', rewardsRoutes);
app.use('/api/vera', veraRoutes);
app.use('/api/industry-practice', industryPracticeRoutes);
app.use('/api/history', historyRoutes);
app.use('/api/admin', adminRoutes);

// Admin dashboard: a static single-page app served by the API itself.
const path = require('path');
app.use('/admin', express.static(path.join(__dirname, 'public', 'admin')));

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
      'GET /api/tasks/history',
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
      'POST /api/verification/analyze',
      'GET /api/verification/analyses',
      'GET /api/lab/lessons',
      'GET /api/lab/lessons/next',
      'GET /api/lab/lessons/:code',
      'POST /api/lab/lessons/:code/progress',
      'POST /api/lab/lessons/:code/assessment',
      'POST /api/lab/activities/:id/attempt',
      'GET /api/lab/assessments',
      'GET /api/lab/assessments/:code',
      'POST /api/lab/assessments/:code/start',
      'POST /api/lab/assessments/:code/submit',
      'POST /api/lab/assessments/:code/attempts/:id/mark',
      'GET /api/lab/sources',
      'GET /api/lab/sources/:id',
      'GET /api/lab/library',
      'POST /api/lab/coach',
      'GET /api/workshop/posts',
      'GET /api/workshop/posts/:id/replies',
      'POST /api/workshop/posts',
      'POST /api/workshop/posts/:id/react',
      'POST /api/workshop/posts/:id/report',
      'DELETE /api/workshop/posts/:id',
      'GET /api/rewards',
      'GET /api/rewards/tokens',
      'POST /api/rewards/:code/redeem',
      'POST /api/users/avatar',
      'GET /api/users/avatar',
      'POST /api/vera/chat',
      'GET /api/vera/sessions',
      'GET /api/vera/sessions/:id',
      'GET /api/vera/memory',
      'POST /api/vera/memory',
      'DELETE /api/vera/memory/:id',
      'GET /api/vera/tips',
      'POST /api/lab/assessments/:code/attempts/:id/ai-mark',
      'POST /api/lab/assessments/:code/attempts/:id/analysis',
      'GET /api/industry-practice/cases',
      'GET /api/industry-practice/cases/:id',
      'POST /api/industry-practice/cases/:id/read',
      'GET /api/history',
      'GET /api/admin/overview',
      'GET /api/admin/tasks',
      'GET /api/admin/tasks/:id',
      'GET /api/admin/tasks/:id/answers',
      'POST /api/admin/tasks',
      'PUT /api/admin/tasks/:id',
      'POST /api/admin/tasks/import',
      'POST /api/admin/tasks/:id/approval',
      'DELETE /api/admin/tasks/:id',
      'GET /api/admin/approvals',
      'GET /api/admin/answers/summary',
      'GET /api/admin/answers',
      'GET /api/admin/analytics',
      'GET /api/admin/track-progress',
      'GET /api/admin/users',
      'GET /api/admin/users/:id',
      'POST /api/admin/users/:id/status',
      'GET /api/admin/moderation',
      'GET /api/admin/workshop',
      'GET /api/admin/lab',
      'GET /api/admin/system',
      'GET /api/admin/config',
      'PUT /api/admin/config',
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
