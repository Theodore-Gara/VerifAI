// Minimal Server-Sent Events helpers for streaming AI replies.
//
// Long silences are normal: the model can think for many seconds before the
// first token, and reasoning models pause mid-stream. Proxies (Render, mobile
// carriers) close idle connections, so a comment heartbeat keeps the pipe open.
// Writing to a socket the client already closed throws an unhandled stream
// error, so every helper checks `writableEnded` / a tracked closed flag first.
const HEARTBEAT_MS = 15000;

function openStream(res) {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache, no-transform');
  res.setHeader('Connection', 'keep-alive');
  // Disable proxy buffering (nginx) so chunks reach the client as they arrive.
  res.setHeader('X-Accel-Buffering', 'no');
  if (typeof res.flushHeaders === 'function') res.flushHeaders();

  let closed = false;
  const heartbeat = setInterval(() => {
    if (closed) return;
    try {
      res.write(': ping\n\n');
    } catch {
      closed = true;
    }
  }, HEARTBEAT_MS);
  // Never hold the process open for a client that went away.
  if (typeof heartbeat.unref === 'function') heartbeat.unref();

  const finish = () => {
    closed = true;
    clearInterval(heartbeat);
  };
  res.on('close', finish);
  res.on('finish', finish);
  res.on('error', finish);

  // Lets sendEvent/endStream stop writing to a dead socket.
  res.locals = res.locals || {};
  res.locals.sseClosed = () => closed || res.writableEnded;
}

function sendEvent(res, data) {
  if (res.writableEnded || (res.locals && res.locals.sseClosed && res.locals.sseClosed())) return false;
  try {
    res.write(`data: ${JSON.stringify(data)}\n\n`);
    return true;
  } catch {
    return false;
  }
}

function endStream(res) {
  if (res.writableEnded || (res.locals && res.locals.sseClosed && res.locals.sseClosed())) return;
  try {
    res.write('data: [DONE]\n\n');
    res.end();
  } catch {
    // Client is gone; nothing left to close.
  }
}

module.exports = { openStream, sendEvent, endStream, HEARTBEAT_MS };
