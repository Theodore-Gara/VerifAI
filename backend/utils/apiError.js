function sendApiError(req, res, status, code, message, options = {}) {
  const retryable = options.retryable ?? (status === 429 || status >= 500);

  const hint = options.hint
    || (status === 429
      ? 'Please wait before trying again.'
      : status >= 500
        ? 'Please try again later.'
        : 'Check your request and try again.');

  return res.status(status).json({
    error: message,
    code,
    hint,
    retryable,
    request_id: req.requestId || null,
  });
}

module.exports = { sendApiError };
