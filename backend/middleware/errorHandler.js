function errorHandler(err, req, res, next) {
  // A malformed JSON body is a client error. Its parser message quotes part of
  // the body, and bodies on some routes (the support contact form) are private,
  // so neither the log nor the response repeats it.
  if (err && err.type === 'entity.parse.failed') {
    console.error(`[${req.requestId || 'no-request-id'}] malformed JSON body on ${req.method} ${req.path}`);
    return res.status(400).json({
      error: 'Request body is not valid JSON.',
      code: 'invalid_json',
      request_id: req.requestId,
    });
  }

  console.error(`[${req.requestId || 'no-request-id'}]`, err.stack || err);

  const status = Number(err.status) || 500;
  const isProduction = process.env.NODE_ENV === 'production';

  res.status(status).json({
    error: status >= 500 && isProduction ? 'Internal server error.' : (err.message || 'Internal server error.'),
    request_id: req.requestId,
  });
}

module.exports = errorHandler;
