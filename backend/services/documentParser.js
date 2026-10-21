// A small pool of child processes for PDF/DOCX text extraction.
//
// Parsing is CPU-bound and used to run inside the request handler, blocking the
// event loop for as long as the document took to read (seconds for a scanned
// PDF). Uploads are now handed to a fixed pool of long-lived children: the API
// stays responsive, work is bounded by pool size, and an over-long parse is
// killed instead of pinning a slot forever.
//
// pdf-parse's bundled pdf.js fails to initialise inside a worker_thread, which
// is why this uses `child_process.fork` rather than `worker_threads`. Children
// are lazy (nothing spawns until the first document) and `unref`ed, so they
// never keep the process or the test runner alive.
const path = require('node:path');
const { fork } = require('node:child_process');

const CHILD_FILE = path.join(__dirname, 'documentParseChild.js');
const POOL_SIZE = Math.max(1, Number(process.env.DOCUMENT_PARSE_WORKERS) || 2);
const MAX_QUEUE = Math.max(POOL_SIZE, Number(process.env.DOCUMENT_PARSE_QUEUE) || 8);
const PARSE_TIMEOUT_MS = Number(process.env.DOCUMENT_PARSE_TIMEOUT_MS) || 20000;

let nextJobId = 1;
let shuttingDown = false;
const queue = [];
const slots = [];

function busyError() {
  const error = new Error('The document reader is busy. Please try again in a moment.');
  error.status = 503;
  return error;
}

function timeoutError() {
  const error = new Error('Reading the document took too long. Try a smaller file.');
  error.status = 422;
  return error;
}

class Slot {
  constructor() {
    this.child = null;
    this.job = null;
    this.timer = null;
  }

  ensureChild() {
    if (this.child) return this.child;
    const child = fork(CHILD_FILE, [], {
      stdio: ['ignore', 'ignore', 'ignore', 'ipc'],
      env: process.env,
    });
    child.unref();
    if (child.channel) child.channel.unref();
    child.on('message', (message) => this.onMessage(message));
    child.on('error', (err) => this.fail(err));
    child.on('exit', (code) => this.onExit(code));
    this.child = child;
    return child;
  }

  run(job) {
    this.job = job;
    this.timer = setTimeout(() => {
      const pending = this.job;
      this.job = null;
      // A hung parser is unrecoverable: drop the child and let the next job
      // spawn a clean one.
      this.detach(pending, timeoutError());
    }, PARSE_TIMEOUT_MS);
    this.ensureChild().send({
      id: job.id,
      kind: job.kind,
      b64: job.buffer.toString('base64'),
      maxPages: job.maxPages,
    });
  }

  onMessage(message) {
    if (!this.job || message.id !== this.job.id) return;
    const job = this.job;
    this.job = null;
    this.clearTimer();
    if (message.ok) job.resolve({ text: message.text, pages: message.pages });
    else job.reject(new Error(message.error));
    pump();
  }

  onExit(code) {
    this.child = null;
    const job = this.job;
    this.job = null;
    this.clearTimer();
    if (job) job.reject(new Error(`Document parser exited (${code}).`));
    if (!shuttingDown) pump();
  }

  fail(err) {
    const job = this.job;
    this.job = null;
    this.clearTimer();
    if (job) job.reject(err);
  }

  clearTimer() {
    if (this.timer) clearTimeout(this.timer);
    this.timer = null;
  }

  detach(job, err) {
    this.clearTimer();
    if (this.child) this.child.kill();
    this.child = null;
    if (job) job.reject(err);
    pump();
  }
}

function pump() {
  if (shuttingDown) return;
  while (queue.length) {
    let slot = slots.find((candidate) => !candidate.job && candidate.child);
    if (!slot) {
      if (slots.length >= POOL_SIZE) return;
      slot = new Slot();
      slots.push(slot);
    }
    slot.run(queue.shift());
  }
}

/**
 * Parses a document off the request thread.
 *
 * @param {{ kind: 'pdf'|'docx', buffer: Buffer, maxPages?: number }} input
 * @returns {Promise<{ text: string, pages: number|null }>}
 */
function parseDocument({ kind, buffer, maxPages }) {
  if (shuttingDown) return Promise.reject(busyError());
  if (queue.length >= MAX_QUEUE) return Promise.reject(busyError());
  return new Promise((resolve, reject) => {
    queue.push({ id: nextJobId++, kind, buffer, maxPages, resolve, reject });
    pump();
  });
}

// Used by tests and graceful shutdown: fails anything still queued.
async function closeDocumentParser() {
  shuttingDown = true;
  while (queue.length) queue.shift().reject(busyError());
  for (const slot of slots) {
    slot.clearTimer();
    if (slot.job) slot.job.reject(busyError());
    slot.job = null;
    if (slot.child) slot.child.kill();
    slot.child = null;
  }
  slots.length = 0;
  shuttingDown = false;
}

module.exports = { parseDocument, closeDocumentParser, POOL_SIZE, PARSE_TIMEOUT_MS };
