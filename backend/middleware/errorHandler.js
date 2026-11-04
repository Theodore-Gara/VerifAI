const { sendApiError } = require('../utils/apiError');

function errorHandler(err, req, res, next) {
  // Malformed JSON: never log or return the submitted body.
  if (err && err.type === 'entity.parse.failed') {
    console.error(
      `[${req.requestId || 'no-request-id'}] malformed JSON body on ${req.method} ${req.path}`
    );

    return sendApiError(
      req,
      res,
      400,
      'invalid_json',
      'Request body is not valid JSON.',
      { retryable: false }
    );
  }

  // Log diagnostic information, but do not expose stack traces to clients.
  console.error(
    `[${req.requestId || 'no-request-id'}]`,
    err.stack || err
  );

  const status = Number(err.status) || 500;

  const message = status >= 500
    ? 'Internal server error.'
    : (err.publicMessage || err.message || 'Request failed.');

  const code = err.apiCode
    || (status >= 500 ? 'internal_error' : 'request_failed');

  return sendApiError(
    req,
    res,
    status,
    code,
    message,
    {
      hint: err.hint,
      retryable: err.retryable,
    }
  );
}

module.exports = errorHandler;
