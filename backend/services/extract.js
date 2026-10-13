// Verification Studio input extraction: turn an uploaded document, a pasted
// URL, or free text into analysable text. Nothing is persisted.
const MAX_FILE_BYTES = 10 * 1024 * 1024; // 10 MB decoded
const MAX_TEXT = 60000;
const MAX_URL_TEXT = 20000;

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
  let buffer;
  try {
    buffer = Buffer.from(base64, 'base64');
  } catch {
    throw errorWith(400, 'document.base64 is not valid base64.');
  }
  if (!buffer.length) throw errorWith(400, 'document is empty.');
  if (buffer.length > MAX_FILE_BYTES) throw errorWith(413, 'Document must be 10MB or smaller.');

  const type = String(mime || '').toLowerCase();
  const lower = String(name || '').toLowerCase();

  try {
    if (type.includes('pdf') || lower.endsWith('.pdf')) {
      const pdf = require('pdf-parse/lib/pdf-parse.js');
      const data = await pdf(buffer);
      return { label: name || 'Document', text: String(data.text || '').replace(/\s+\n/g, '\n').trim().slice(0, MAX_TEXT) };
    }
    if (type.includes('word') || type.includes('officedocument') || lower.endsWith('.docx')) {
      const mammoth = require('mammoth');
      const result = await mammoth.extractRawText({ buffer });
      return { label: name || 'Document', text: String(result.value || '').trim().slice(0, MAX_TEXT) };
    }
    // txt / md / anything else: treat as UTF-8 text.
    return { label: name || 'Document', text: buffer.toString('utf8').trim().slice(0, MAX_TEXT) };
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

module.exports = { extractDocument, fetchUrl, stripHtml, MAX_FILE_BYTES, MAX_TEXT };
