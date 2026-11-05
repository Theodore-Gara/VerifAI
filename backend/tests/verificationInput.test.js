const assert = require('node:assert/strict');
const { test } = require('node:test');
const {
  extractDocument, detectFormat, assessQuality, htmlToMarkdown, MAX_FILE_BYTES,
} = require('../services/extract');

const b64 = (value) => Buffer.from(value).toString('base64');

test('allowlist: legacy .doc is rejected with a save-as hint', () => {
  assert.throws(
    () => detectFormat({ name: 'brief.doc', mime: 'application/msword', buffer: Buffer.from('x') }),
    (err) => err.status === 415 && err.apiCode === 'document_unsupported' && /Save the file as \.docx/.test(err.hint),
  );
});

test('allowlist: slides, spreadsheets and images each get an actionable code and hint', () => {
  for (const [name, needle] of [
    ['deck.pptx', /Export the slides/],
    ['sheet.xlsx', /Copy the cells/],
    ['scan.png', /Images cannot be read/],
  ]) {
    assert.throws(
      () => detectFormat({ name, mime: '', buffer: Buffer.from('x') }),
      (err) => err.status === 415
        && err.apiCode === 'document_unsupported'
        && needle.test(err.hint),
    );
  }
});

test('magic bytes: a fake PDF or DOCX is rejected before parsing', () => {
  assert.throws(
    () => detectFormat({ name: 'fake.pdf', mime: 'application/pdf', buffer: Buffer.from('not a pdf') }),
    (err) => err.status === 415 && err.apiCode === 'document_unsupported' && /not a valid PDF/.test(err.publicMessage),
  );
  assert.throws(
    () => detectFormat({ name: 'fake.docx', mime: '', buffer: Buffer.from('not a zip') }),
    (err) => err.status === 415 && err.apiCode === 'document_unsupported' && /not a valid \.docx/.test(err.publicMessage),
  );
});

test('magic bytes: a real header selects the parser', () => {
  assert.equal(
    detectFormat({ name: 'text.pdf', mime: '', buffer: Buffer.concat([Buffer.from('%PDF-1.7'), Buffer.from('\nrest')]) }),
    'pdf',
  );
  assert.equal(
    detectFormat({ name: 'text.docx', mime: '', buffer: Buffer.from([0x50, 0x4b, 0x03, 0x04, 0x00]) }),
    'docx',
  );
  assert.equal(detectFormat({ name: 'notes.txt', mime: 'text/plain', buffer: Buffer.from('hello world') }), 'txt');
});

test('binary content renamed .txt is rejected', () => {
  assert.throws(
    () => detectFormat({ name: 'notes.txt', mime: 'text/plain', buffer: Buffer.from([0x41, 0x00, 0x42]) }),
    (err) => err.status === 415 && err.apiCode === 'document_unsupported',
  );
});

test('an empty upload is no_input and an oversize one is document_too_large', async () => {
  await assert.rejects(
    () => extractDocument({ base64: '', name: 'x.txt' }),
    (err) => err.status === 400 && err.apiCode === 'no_input',
  );

  // Base64 longer than the decoded byte ceiling.
  const oversize = 'A'.repeat(Math.ceil((MAX_FILE_BYTES * 4) / 3) + 2048);
  await assert.rejects(
    () => extractDocument({ base64: oversize, name: 'big.txt' }),
    (err) => err.status === 413 && err.apiCode === 'document_too_large' && /5MB/.test(err.hint),
  );
});

test('a file with no readable text is 422 document_no_text, never sent to the model', async () => {
  await assert.rejects(
    () => extractDocument({ base64: b64('   '), mime: 'text/plain', name: 'scan.txt' }),
    (err) => err.status === 422 && err.apiCode === 'document_no_text' && /scanned PDF/.test(err.hint),
  );
});

test('a text file returns metadata and a quality flag', async () => {
  const text = 'The quarterly report says revenue grew 15% in 2024 and costs fell by 4%.';
  const doc = await extractDocument({ base64: b64(text), mime: 'text/plain', name: 'q3.txt' });
  assert.equal(doc.format, 'txt');
  assert.equal(doc.quality, 'good');
  assert.equal(doc.truncated, false);
  assert.equal(doc.pages, null);
  assert.equal(doc.pagesRead, null);
  assert.equal(doc.text, text);
});

test('gibberish extraction is flagged low quality rather than looking clean', () => {
  const gibberish = '\uFFFD\uFFFD \u25A0\u25A0 \u25A0 \u0001 \u0002 '.repeat(30);
  assert.equal(assessQuality(gibberish).quality, 'low');
  assert.equal(assessQuality('This is ordinary readable English prose with several words.').quality, 'good');
});

test('DOCX structure survives as lightweight markdown', () => {
  const html = [
    '<h1>Findings</h1>',
    '<p>Revenue grew.</p>',
    '<ul><li>First point</li><li>Second point</li></ul>',
    '<table><tr><th>Year</th><th>Revenue</th></tr><tr><td>2024</td><td>R12m</td></tr></table>',
  ].join('');
  const markdown = htmlToMarkdown(html);
  assert.match(markdown, /# Findings/);
  assert.match(markdown, /- First point/);
  assert.match(markdown, /\| Year \| Revenue \|/);
  assert.match(markdown, /\| 2024 \| R12m \|/);
});
