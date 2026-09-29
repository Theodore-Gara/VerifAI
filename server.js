require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const healthRoutes = require('./routes/health');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const trackRoutes = require('./routes/tracks');
const errorHandler = require('./middleware/errorHandler');

const app = express();

const allowedOrigins = (process.env.ALLOWED_ORIGINS || '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

app.use(helmet());
app.use(
  cors({
    origin: allowedOrigins.length ? allowedOrigins : true, // fall back to allow all
  })
);
app.use(express.json());

// Route mounting 
// GET /api/health · POST /api/auth/sync · GET /api/users/me · PUT /api/users/profile · GET /api/tracks
app.use('/api/health', healthRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/tracks', trackRoutes);

// 404 for anything that doesn't match a route above
app.use((req, res) => {
  res.status(404).json({ error: `Route not found: ${req.method} ${req.originalUrl}` });
});

// Must be registered last identifies it as an error handler by its 4 arguments
app.use(errorHandler);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`VerifAI API listening on port ${PORT}`);
});

module.exports = app;
