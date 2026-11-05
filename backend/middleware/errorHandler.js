const { sendApiError } = require('../utils/apiError');

// Body-parser raises these before a controller runs, so they are mapped here
// rather than in a route.
const BODY_ERRORS = {
  'entity.parse.failed': {
    status: 400,
    code: 'invalid_json',
    message: 'Request body is not valid JSON.',
    hint: 'Check the JSON and try again.',
    retryable: false,
  },
  'entity.too.large': {
    status: 413,
    code: 'document_too_large',
    message: 'The request is too large.',
    hint: 'Choose a smaller file or paste the text instead.',
    retryable: false,
  },
};

function errorHandler(err, req, res, next) {
  const requestId = req.requestId || 'no-request-id';

  if (err && BODY_ERRORS[err.type]) {
    const mapped = BODY_ERRORS[err.type];
    // Never log the submitted body: support messages and documents are private.
    console.error(`[${requestId}] ${err.type} on ${req.method} ${req.path}`);
    return sendApiError(req, res, mapped.status, mapped.code, mapped.message, {
      hint: mapped.hint,
      retryable: mapped.retryable,
    });
  }

  // Log diagnostics server-side, but never expose a stack or provider text.
  console.error(`[${requestId}]`, err.stack || err);

  if (res.headersSent) return next(err);

  const status = Number(err.status) || 500;
  const code = err.apiCode || (status >= 500 ? 'internal_error' : 'request_failed');
  const message = status >= 500
    ? (err.publicMessage || 'Internal server error.')
    : (err.publicMessage || err.message || 'Request failed.');

  return sendApiError(req, res, status, code, message, {
    hint: err.hint,
    retryable: err.retryable,
  });
}

module.exports = errorHandler;
