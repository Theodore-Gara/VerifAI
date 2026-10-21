// Child-process entry point for document extraction.
//
// pdf-parse's bundled pdf.js cannot initialise inside a worker_thread, so the
// pool in documentParser.js uses forked children instead. Children are long
// lived and reused, so the ~200 ms process start is paid once per slot.
const pdf = require('pdf-parse/lib/pdf-parse.js');
const mammoth = require('mammoth');

async function parse({ kind, b64, maxPages }) {
  const buffer = Buffer.from(b64, 'base64');
  if (kind === 'pdf') {
    const parsed = await pdf(buffer, { max: maxPages });
    return { text: String(parsed.text || ''), pages: Number(parsed.numpages) || null };
  }
  const result = await mammoth.extractRawText({ buffer });
  return { text: String(result.value || ''), pages: null };
}

process.on('message', async (job) => {
  try {
    const result = await parse(job);
    process.send({ id: job.id, ok: true, ...result });
  } catch (err) {
    process.send({ id: job.id, ok: false, error: err && err.message ? err.message : 'parse failed' });
  }
});
