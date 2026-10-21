// Verification Studio input extraction: turn an uploaded document, a pasted
// URL, or free text into analysable text. Nothing is persisted.
const { parseDocument } = require('./documentParser');
// 5 MB decoded is a 40-page text PDF or a long DOCX. The previous 10 MB ceiling
// meant a 14 MB JSON body and a parser run that could hold a whole instance.
const MAX_FILE_BYTES = Number(process.env.VERIFICATION_MAX_DOCUMENT_BYTES) || 5 * 1024 * 1024;
// Base64 inflates by ~4/3; reject oversized payloads before allocating a buffer.
const MAX_BASE64_CHARS = Math.ceil((MAX_FILE_BYTES * 4) / 3) + 1024;
const MAX_TEXT = 60000;
const MAX_URL_TEXT = 20000;
// Parsing stops after this many PDF pages, so a 2,000-page upload cannot make
// the worker read the whole file before the character cap applies.
const MAX_PDF_PAGES = Number(process.env.VERIFICATION_MAX_PDF_PAGES) || 40;

function errorWith(status, message) {
  const error = new Error(message);
  error.status = status;
  return error;
}

// Minimal HTML -> text: drop script/style, strip tags, decode a few entities.
function stripHtml(html) {
  return String(html)
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<!--[\s\S]*?-->/g, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/gi, "'")
    .replace(/\s+/g, ' ')
    .trim();
}

async function extractDocument({ base64, mime, name } = {}) {
  if (typeof base64 !== 'string' || !base64.trim()) {
    throw errorWith(400, 'document.base64 is required.');
  }
  if (base64.length > MAX_BASE64_CHARS) {
    throw errorWith(413, 'Document must be 5MB or smaller.');
  }
  let buffer;
  try {
    buffer = Buffer.from(base64, 'base64');
  } catch {
    throw errorWith(400, 'document.base64 is not valid base64.');
  }
  if (!buffer.length) throw errorWith(400, 'document is empty.');
  if (buffer.length > MAX_FILE_BYTES) throw errorWith(413, 'Document must be 5MB or smaller.');

  const type = String(mime || '').toLowerCase();
  const lower = String(name || '').toLowerCase();
  const isPdf = type.includes('pdf') || lower.endsWith('.pdf');
  const isDocx = type.includes('word') || type.includes('officedocument') || lower.endsWith('.docx');
  const label = name || 'Document';

  try {
    if (isPdf || isDocx) {
      // Parsed on a worker thread: pdf-parse and mammoth are CPU-bound and used
      // to block the API's event loop for the length of the document.
      const parsed = await parseDocument({
        kind: isPdf ? 'pdf' : 'docx',
        buffer,
        maxPages: MAX_PDF_PAGES,
      });
      const text = String(parsed.text || '');
      return {
        label,
        text: (isPdf ? text.replace(/\s+\n/g, '\n') : text).trim().slice(0, MAX_TEXT),
        pages: parsed.pages,
        truncated: text.length > MAX_TEXT || (isPdf && parsed.pages > MAX_PDF_PAGES),
      };
    }
    // txt / md / anything else: treat as UTF-8 text.
    return { label, text: buffer.toString('utf8').trim().slice(0, MAX_TEXT) };
  } catch (err) {
    if (err && err.status) throw err;
    throw errorWith(422, `Could not read the document: ${err.message}`);
  }
}

async function fetchUrl(url, { fetchImpl = fetch } = {}) {
  let parsed;
  try {
    parsed = new URL(String(url));
  } catch {
    throw errorWith(400, 'url is not a valid URL.');
  }
  if (!/^https?:$/.test(parsed.protocol)) throw errorWith(400, 'url must be http or https.');

  let response;
  try {
    response = await fetchImpl(parsed.toString(), {
      redirect: 'follow',
      headers: { 'User-Agent': 'VerifAI/1.0 (+https://verifai)' },
      signal: AbortSignal.timeout(12000),
    });
  } catch (cause) {
    throw errorWith(502, `Could not open the link (${cause.name === 'TimeoutError' ? 'timed out' : 'unreachable'}).`);
  }
  if (!response.ok) throw errorWith(502, `The link returned HTTP ${response.status}.`);
  const html = await response.text();
  return { label: parsed.hostname, url: parsed.toString(), text: stripHtml(html).slice(0, MAX_URL_TEXT) };
}

module.exports = {
  extractDocument,
  fetchUrl,
  stripHtml,
  MAX_FILE_BYTES,
  MAX_TEXT,
  MAX_PDF_PAGES,
};
