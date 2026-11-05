// One error envelope for every 4xx/5xx the app can render.
//
// Shape (frozen in SPRINT2_BACKEND.md):
//   { error, code, hint, retryable, request_id }
// `error` stays human-readable so older builds keep working; `code` is the
// machine-readable field the app maps to an action. Provider/stack text must
// never reach a response body - callers pass stable copy.

const RETRYABLE_STATUSES = new Set([429, 500, 502, 503, 504]);

const DEFAULT_HINTS = {
  400: 'Check your request and try again.',
  401: 'Sign in again and retry.',
  403: 'You do not have access to this resource.',
  404: 'The item may have moved or been removed.',
  409: 'Refresh the screen and try again.',
  413: 'Choose a smaller file or paste the text instead.',
  415: 'Upload one of the supported formats.',
  422: 'Check the file and try again.',
  429: 'Please wait before trying again.',
};

function defaultHint(status) {
  if (DEFAULT_HINTS[status]) return DEFAULT_HINTS[status];
  return status >= 500 ? 'Please try again later.' : 'Check your request and try again.';
}

function sendApiError(req, res, status, code, message, options = {}) {
  const numericStatus = Number(status) || 500;
  const retryable = options.retryable ?? RETRYABLE_STATUSES.has(numericStatus);
  const hint = options.hint || defaultHint(numericStatus);

  return res.status(numericStatus).json({
    error: message,
    code,
    hint,
    retryable,
    request_id: req.requestId || null,
  });
}

// Build an Error that the shared middleware can turn into the envelope. The
// constructor message is what the server logs; `publicMessage` is the only text
// allowed to reach the client for a 5xx.
function apiError(status, code, message, options = {}) {
  const error = new Error(message);
  error.status = Number(status) || 500;
  error.apiCode = code;
  if (options.publicMessage) error.publicMessage = options.publicMessage;
  if (options.hint) error.hint = options.hint;
  if (options.retryable !== undefined) error.retryable = options.retryable;
  if (options.cause) error.cause = options.cause;
  return error;
}

module.exports = { sendApiError, apiError, defaultHint, RETRYABLE_STATUSES };
