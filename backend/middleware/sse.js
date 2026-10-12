// Minimal Server-Sent Events helpers for streaming AI replies.
function openStream(res) {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache, no-transform');
  res.setHeader('Connection', 'keep-alive');
  if (typeof res.flushHeaders === 'function') res.flushHeaders();
}

function sendEvent(res, data) {
  res.write(`data: ${JSON.stringify(data)}\n\n`);
}

function endStream(res) {
  res.write('data: [DONE]\n\n');
  res.end();
}

module.exports = { openStream, sendEvent, endStream };
