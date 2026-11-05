const { sendApiError } = require('../utils/apiError');

// Stable copy per status. Provider text (a model's own error message) is never
// forwarded: it is logged below and replaced with one of these.
const FALLBACK_CODE = {
  400: 'no_input',
  409: 'same_track',
  413: 'document_too_large',
  415: 'document_unsupported',
  422: 'document_parse_failed',
  429: 'rate_limited',
  502: 'ai_unavailable',
  503: 'ai_unavailable',
  504: 'ai_timeout',
};

const FALLBACK_MESSAGE = {
  ai_unavailable: 'The AI service is temporarily unavailable.',
  ai_timeout: 'The AI service took too long to respond.',
  report_unreadable: 'The AI service returned a report we could not read.',
  document_too_large: 'That document is too large.',
  document_unsupported: 'That file type is not supported.',
  document_parse_failed: 'We could not read that document.',
  document_no_text: 'We could not read any text in that document.',
  rate_limited: 'Too many requests. Please try again later.',
  same_track: 'You are already on that industry track.',
  no_input: 'Provide something to check first.',
};

const HANDLED_STATUSES = new Set([400, 409, 413, 415, 422, 429, 502, 503, 504]);

// Maps errors raised by the AI service / validators into the standard API
// envelope. Anything unrecognised falls through to the global handler.
function handleAiError(err, req, res, next) {
  const status = Number(err && err.status);
  if (!HANDLED_STATUSES.has(status)) return next(err);

  const code = err.apiCode || FALLBACK_CODE[status] || 'request_failed';
  // A 4xx validator message is our own copy and is safe to show. A 5xx message
  // may contain upstream/provider detail, so only `publicMessage` is exposed.
  const message = status >= 500
    ? (err.publicMessage || FALLBACK_MESSAGE[code] || 'The request could not be completed.')
    : (err.publicMessage || err.message || FALLBACK_MESSAGE[code] || 'The request is invalid.');

  // Server-side diagnostics only: status, code and the provider message. Never
  // document text or model output.
  console.error(
    `[${req.requestId || 'no-request-id'}] verification error ${status} ${code}: ${err.message}`,
  );

  return sendApiError(req, res, status, code, message, {
    hint: err.hint,
    retryable: err.retryable,
  });
}

module.exports = { handleAiError, FALLBACK_CODE, FALLBACK_MESSAGE };
