function errorHandler(err, req, res, next) {
  console.error(`[${req.requestId || 'no-request-id'}]`, err.stack || err);

  const status = Number(err.status) || 500;
  const isProduction = process.env.NODE_ENV === 'production';

  res.status(status).json({
    error: status >= 500 && isProduction ? 'Internal server error.' : (err.message || 'Internal server error.'),
    request_id: req.requestId,
  });
}

module.exports = errorHandler;
