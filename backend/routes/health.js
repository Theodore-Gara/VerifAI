const express = require('express');
const pool = require('../db/pool');

const router = express.Router();

router.get('/', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    return res.status(200).json({ status: 'ok', db: 'connected', timestamp: new Date().toISOString(), request_id: req.requestId });
  } catch (err) {
    console.error('Health check database ping failed:', err.message);
    return res.status(503).json({ status: 'degraded', db: 'unreachable', timestamp: new Date().toISOString(), request_id: req.requestId });
  }
});

module.exports = router;
