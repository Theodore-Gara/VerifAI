// Lightweight DOCX (mammoth HTML) -> markdown conversion.
//
// mammoth.extractRawText throws away headings, lists and table structure, which
// is exactly the structure a verification report needs to quote. convertToHtml
// keeps it; this module turns that HTML into the small markdown subset the app
// already renders. No new dependency.
function decodeEntities(value) {
  return String(value)
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/gi, "'")
    .replace(/&#x([0-9a-f]+);/gi, (_, hex) => String.fromCodePoint(parseInt(hex, 16)))
    .replace(/&#(\d+);/g, (_, dec) => String.fromCodePoint(Number(dec)));
}

function inlineText(html) {
  return decodeEntities(String(html || '').replace(/<[^>]+>/g, ' '))
    .replace(/\s+/g, ' ')
    .trim();
}

function tableToMarkdown(tableHtml) {
  const rows = [...String(tableHtml).matchAll(/<tr\b[^>]*>([\s\S]*?)<\/tr>/gi)];
  const parsed = rows.map((row) => {
    const cells = [...row[1].matchAll(/<t[dh]\b[^>]*>([\s\S]*?)<\/t[dh]>/gi)]
      .map((cell) => inlineText(cell[1]).replace(/\|/g, '\\|'));
    return cells;
  }).filter((cells) => cells.length);
  if (!parsed.length) return '';
  const width = Math.max(...parsed.map((cells) => cells.length));
  const lines = parsed.map((cells) => {
    const padded = [...cells, ...Array(Math.max(0, width - cells.length)).fill('')];
    return `| ${padded.join(' | ')} |`;
  });
  // Markdown tables need a separator after the first row.
  lines.splice(1, 0, `| ${Array(width).fill('---').join(' | ')} |`);
  return lines.join('\n');
}

function htmlToMarkdown(html) {
  let text = String(html || '');

  // Tables first, before their tags are stripped.
  text = text.replace(/<table\b[^>]*>[\s\S]*?<\/table>/gi, (table) => `\n\n${tableToMarkdown(table)}\n\n`);

  text = text
    .replace(/<h([1-6])\b[^>]*>([\s\S]*?)<\/h\1>/gi, (_, level, body) => `\n\n${'#'.repeat(Number(level))} ${inlineText(body)}\n\n`)
    .replace(/<li\b[^>]*>([\s\S]*?)<\/li>/gi, (_, body) => `\n- ${inlineText(body)}`)
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/(p|div|section|article|blockquote|ul|ol)>/gi, '\n\n')
    .replace(/<(ul|ol)\b[^>]*>/gi, '\n')
    .replace(/<[^>]+>/g, '');

  text = decodeEntities(text)
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
  return text;
}

module.exports = { decodeEntities, inlineText, tableToMarkdown, htmlToMarkdown };
