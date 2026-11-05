// Verification Studio input extraction: turn an uploaded document, a pasted
// URL, or free text into analysable text. Nothing is persisted.
//
// Text extraction only - there is deliberately no OCR or vision fallback in
// this sprint. An image-only PDF is rejected honestly with a remedy instead of
// being sent to the model as an empty document.
const { parseDocument } = require('./documentParser');
const { htmlToMarkdown, tableToMarkdown } = require('./docxMarkdown');
const { apiError } = require('../utils/apiError');

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
// Under this much readable text almost certainly means a scan or a corrupt file.
const MIN_USABLE_CHARS = 40;

const ACCEPTED_DOCUMENT_FORMATS = ['pdf', 'docx', 'txt', 'md'];

const PDF_MAGIC = Buffer.from('%PDF-', 'ascii');
const DOCX_MAGIC = Buffer.from([0x50, 0x4b, 0x03, 0x04]); // "PK\x03\x04"

const UNSUPPORTED_HINTS = {
  doc: 'Save the file as .docx and try again.',
  pptx: 'Export the slides as a PDF, or paste the text instead.',
  ppt: 'Export the slides as a PDF, or paste the text instead.',
  xlsx: 'Copy the cells into a document, or paste the text instead.',
  xls: 'Copy the cells into a document, or paste the text instead.',
  csv: 'Save the sheet as a PDF or paste the rows instead.',
  png: 'Images cannot be read yet. Paste the text or upload a text-based PDF.',
  jpg: 'Images cannot be read yet. Paste the text or upload a text-based PDF.',
  jpeg: 'Images cannot be read yet. Paste the text or upload a text-based PDF.',
  webp: 'Images cannot be read yet. Paste the text or upload a text-based PDF.',
  gif: 'Images cannot be read yet. Paste the text or upload a text-based PDF.',
};

function errorWith(status, message) {
  const error = new Error(message);
  error.status = status;
  return error;
}

function extensionOf(name) {
  const match = /\.([a-z0-9]+)$/i.exec(String(name || '').trim());
  return match ? match[1].toLowerCase() : '';
}

function unsupported(format) {
  const hint = UNSUPPORTED_HINTS[format]
    || `Supported formats: ${ACCEPTED_DOCUMENT_FORMATS.join(', ')}. Paste the text if your file is a different type.`;
  return apiError(
    415,
    'document_unsupported',
    `Files of type .${format} are not supported.`,
    {
      publicMessage: `We cannot read .${format} files.`,
      hint,
      retryable: false,
    },
  );
}

function detectFormat({ name, mime, buffer }) {
  const ext = extensionOf(name);
  const type = String(mime || '').toLowerCase();

  if (ext === 'doc' || type.includes('msword')) {
    // The legacy binary Word format needs a converter we do not ship.
    throw unsupported('doc');
  }
  if (ext === 'pptx' || ext === 'ppt' || type.includes('presentationml') || type.includes('powerpoint')) {
    throw unsupported(ext || 'pptx');
  }
  if (ext === 'xlsx' || ext === 'xls' || type.includes('spreadsheetml') || type.includes('ms-excel')) {
    throw unsupported(ext || 'xlsx');
  }
  if (['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp', 'heic'].includes(ext)
    || type.startsWith('image/')) {
    throw unsupported(ext || 'png');
  }

  const looksPdf = ext === 'pdf' || type.includes('pdf');
  const looksDocx = ext === 'docx'
    || type.includes('officedocument.wordprocessingml')
    || type.includes('wordprocessingml');
  const looksText = ['txt', 'md', 'markdown'].includes(ext)
    || type.startsWith('text/')
    || (type === 'application/octet-stream' && !looksPdf && !looksDocx);

  if (looksPdf) {
    if (buffer.length < PDF_MAGIC.length || !buffer.subarray(0, PDF_MAGIC.length).equals(PDF_MAGIC)) {
      throw apiError(415, 'document_unsupported', 'File is named as a PDF but has no PDF header.', {
        publicMessage: 'That file is not a valid PDF.',
        hint: 'Re-save or re-export the document as a PDF and try again.',
        retryable: false,
      });
    }
    return 'pdf';
  }
  if (looksDocx) {
    if (buffer.length < DOCX_MAGIC.length || !buffer.subarray(0, DOCX_MAGIC.length).equals(DOCX_MAGIC)) {
      throw apiError(415, 'document_unsupported', 'File is named as a DOCX but is not a ZIP container.', {
        publicMessage: 'That file is not a valid .docx document.',
        hint: 'Open it in Word or Google Docs, save it again as .docx, and retry.',
        retryable: false,
      });
    }
    return 'docx';
  }
  if (looksText) {
    // A binary blob renamed .txt is not text. NUL bytes never appear in a real
    // UTF-8 text file, so they are a reliable signal.
    const sample = buffer.subarray(0, Math.min(buffer.length, 4096));
    if (sample.includes(0)) {
      throw apiError(415, 'document_unsupported', 'Text upload contains NUL bytes (binary content).', {
        publicMessage: 'That file does not look like text.',
        hint: `Upload a ${ACCEPTED_DOCUMENT_FORMATS.join(', ')} file, or paste the text instead.`,
        retryable: false,
      });
    }
    return ext === 'md' || ext === 'markdown' ? 'md' : 'txt';
  }

  throw apiError(415, 'document_unsupported', `Unknown document format (${ext || type || 'none'}).`, {
    publicMessage: 'That file type is not supported.',
    hint: `Supported formats: ${ACCEPTED_DOCUMENT_FORMATS.join(', ')}.`,
    retryable: false,
  });
}

// ---------------------------------------------------------------------------
// Quality gate
// ---------------------------------------------------------------------------
// Broken font mappings produce gibberish (symbols, lone letters, replacement
// characters) rather than an empty string. Flag it so the report can say the
// extraction was poor instead of presenting a clean-looking result.
function assessQuality(text) {
  const clean = String(text || '').replace(/\[page \d+\]/gi, ' ');
  const chars = clean.replace(/\s/g, '');
  if (!chars.length) return { quality: 'low', reason: 'no_letters' };

  const replacement = (clean.match(/\uFFFD/g) || []).length;
  const letters = (clean.match(/[A-Za-z\u00C0-\u024F]/g) || []).length;
  const symbols = (clean.match(/[^\w\s\u00C0-\u024F.,;:!?'"()\-/%&+]/g) || []).length;
  const tokens = clean.split(/\s+/).filter(Boolean);
  const lone = tokens.filter((token) => token.replace(/[^\w]/g, '').length === 1).length;

  if (replacement / chars.length > 0.01) return { quality: 'low', reason: 'replacement_characters' };
  if (letters / chars.length < 0.45) return { quality: 'low', reason: 'mostly_symbols' };
  if (tokens.length >= 40 && lone / tokens.length > 0.4) return { quality: 'low', reason: 'lone_letters' };
  if (symbols / chars.length > 0.3) return { quality: 'low', reason: 'mostly_symbols' };
  return { quality: 'good', reason: null };
}

// ---------------------------------------------------------------------------
// DOCX conversion lives in services/docxMarkdown.js so the parser child process
// and this module share one implementation.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Extraction
// ---------------------------------------------------------------------------
async function extractDocument({ base64, mime, name } = {}) {
  if (typeof base64 !== 'string' || !base64.trim()) {
    throw apiError(400, 'no_input', 'document.base64 is required.', {
      publicMessage: 'No document was uploaded.',
      hint: 'Choose a file and try again.',
      retryable: false,
    });
  }
  if (base64.length > MAX_BASE64_CHARS) {
    throw apiError(413, 'document_too_large', 'Encoded document exceeds the byte ceiling.', {
      publicMessage: `Document must be ${Math.round(MAX_FILE_BYTES / (1024 * 1024))}MB or smaller.`,
      hint: `The maximum document size is ${Math.round(MAX_FILE_BYTES / (1024 * 1024))}MB. Choose a smaller file or paste the text.`,
      retryable: false,
    });
  }
  let buffer;
  try {
    buffer = Buffer.from(base64, 'base64');
  } catch {
    throw apiError(400, 'no_input', 'document.base64 is not valid base64.', {
      publicMessage: 'That upload could not be decoded.',
      hint: 'Choose the file again.',
      retryable: false,
    });
  }
  if (!buffer.length) {
    throw apiError(400, 'no_input', 'document is empty.', {
      publicMessage: 'That file is empty.',
      hint: 'Choose a file with content.',
      retryable: false,
    });
  }
  if (buffer.length > MAX_FILE_BYTES) {
    throw apiError(413, 'document_too_large', 'Document exceeds the byte ceiling.', {
      publicMessage: `Document must be ${Math.round(MAX_FILE_BYTES / (1024 * 1024))}MB or smaller.`,
      hint: `The maximum document size is ${Math.round(MAX_FILE_BYTES / (1024 * 1024))}MB. Choose a smaller file or paste the text.`,
      retryable: false,
    });
  }

  const label = name || 'Document';
  const format = detectFormat({ name, mime, buffer });

  let rawText = '';
  let pages = null;
  let pagesRead = null;
  let truncated = false;

  try {
    if (format === 'pdf' || format === 'docx') {
      // Parsed on child processes: pdf-parse and mammoth are CPU-bound and used
      // to block the API's event loop for the length of the document.
      const parsed = await parseDocument({
        kind: format,
        buffer,
        maxPages: MAX_PDF_PAGES,
      });
      rawText = String(parsed.text || '');
      pages = parsed.pages == null ? null : Number(parsed.pages);
      if (format === 'pdf') {
        pagesRead = pages == null ? null : Math.min(pages, MAX_PDF_PAGES);
        truncated = (pages != null && pages > MAX_PDF_PAGES);
      }
    } else {
      rawText = buffer.toString('utf8');
    }
  } catch (err) {
    if (err && err.apiCode) throw err;
    throw apiError(422, 'document_parse_failed', `Document parse failed: ${err && err.message}`, {
      publicMessage: 'We could not read that document.',
      hint: 'Try re-saving or re-exporting it, or paste the text instead.',
      retryable: false,
    });
  }

  let text = rawText.trim();
  if (text.length > MAX_TEXT) {
    text = text.slice(0, MAX_TEXT);
    truncated = true;
  }

  const readable = text.replace(/\[page \d+\]/gi, '').replace(/\s+/g, '');
  if (readable.length < MIN_USABLE_CHARS) {
    // The decision for this sprint: no OCR. Say so, and give a remedy.
    throw apiError(422, 'document_no_text', 'Extracted text is empty or too short to analyse.', {
      publicMessage: 'We could not read any text in that document.',
      hint: 'This looks like a scanned PDF. Upload a text-based PDF, a .docx, or paste the text instead.',
      retryable: false,
    });
  }

  const { quality, reason } = assessQuality(text);

  return {
    label,
    format,
    text,
    pages,
    pagesRead,
    truncated,
    quality,
    qualityReason: reason,
    warning: quality === 'low'
      ? 'The text in this document did not extract cleanly, so the report may miss parts of it.'
      : null,
  };
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

module.exports = {
  extractDocument,
  fetchUrl,
  stripHtml,
  htmlToMarkdown,
  tableToMarkdown,
  assessQuality,
  detectFormat,
  MAX_FILE_BYTES,
  MAX_TEXT,
  MAX_PDF_PAGES,
  MIN_USABLE_CHARS,
  ACCEPTED_DOCUMENT_FORMATS,
};
