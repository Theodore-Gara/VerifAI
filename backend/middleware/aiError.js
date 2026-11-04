const { sendApiError } = require('../utils/apiError');

// Maps errors raised by the AI service / validators into standard API responses.
function handleAiError(err, req, res, next) {
  if (err && [400, 413, 422, 502, 503, 504].includes(err.status)) {
    const status = err.status;

    const code = err.apiCode
      || (status >= 500 ? 'ai_service_error' : 'ai_request_invalid');

    const message = status >= 500
      ? 'The AI service could not complete your request.'
      : (err.publicMessage || err.message || 'The AI request is invalid.');

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

  return next(err);
}

module.exports = { handleAiError };

