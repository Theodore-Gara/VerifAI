// Maps errors raised by the AI service / validators into API responses. AI
// transport errors carry a `status` (502 upstream, 503 unconfigured/rate,
// 504 timeout); validation errors carry 400. Anything else falls through to
// the global error handler.
function handleAiError(err, req, res, next) {
  if (err && [400, 413, 422, 502, 503, 504].includes(err.status)) {
    return res.status(err.status).json({ error: err.message, request_id: req.requestId });
  }
  return next(err);
}

module.exports = { handleAiError };
