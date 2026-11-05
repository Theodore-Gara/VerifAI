// Child-process entry point for document extraction.
//
// pdf-parse's bundled pdf.js cannot initialise inside a worker_thread, so the
// pool in documentParser.js uses forked children instead. Children are long
// lived and reused, so the ~200 ms process start is paid once per slot.
const pdf = require('pdf-parse/lib/pdf-parse.js');
const mammoth = require('mammoth');
const { htmlToMarkdown } = require('./docxMarkdown');

// Prefix every page with `[page N]` so a claim can say where it came from and
// the claim extractor can chunk long documents by page (BF-1/BF-4). The text of
// one page is rebuilt line by line from the PDF text items: items sharing a
// vertical position stay on the same line, a new position starts a new line.
async function renderPage(pageData) {
  const content = await pageData.getTextContent({
    normalizeWhitespace: false,
    disableCombineTextItems: false,
  });
  let lastY;
  let text = '';
  for (const item of content.items) {
    const y = item.transform ? item.transform[5] : undefined;
    if (lastY === undefined || Math.abs(y - lastY) < 1) {
      text += item.str;
    } else {
      text += `\n${item.str}`;
    }
    lastY = y;
  }
  return `[page ${(pageData.pageIndex || 0) + 1}]\n${text}`;
}

async function parse({ kind, b64, maxPages }) {
  const buffer = Buffer.from(b64, 'base64');
  if (kind === 'pdf') {
    const parsed = await pdf(buffer, { max: maxPages, pagerender: renderPage });
    return { text: String(parsed.text || ''), pages: Number(parsed.numpages) || null };
  }

  // DOCX: headings, lists and table rows survive as markdown. If the richer
  // conversion fails, fall back to raw text rather than failing the upload.
  try {
    const result = await mammoth.convertToHtml({ buffer });
    return { text: htmlToMarkdown(result.value || ''), pages: null };
  } catch {
    const result = await mammoth.extractRawText({ buffer });
    return { text: String(result.value || ''), pages: null };
  }
}

process.on('message', async (job) => {
  try {
    const result = await parse(job);
    process.send({ id: job.id, ok: true, ...result });
  } catch (err) {
    process.send({ id: job.id, ok: false, error: err && err.message ? err.message : 'parse failed' });
  }
});
