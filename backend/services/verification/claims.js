// BF-1: separate *finding claims* from *checking claims*.
//
// The old pipeline sent the opening paragraph of the document to Tavily as the
// search query, so the search had no claim to match. This module extracts up to
// eight discrete claims (page-aware, sampled across the whole document), runs a
// capped number of searches - one per claim - de-duplicates the URLs while
// keeping the per-claim association, and asks the model only for a verdict per
// claim. The overall status is derived separately in report.js (BF-3).
const { completeJsonCompletion } = require('../nvidiaAssistant');
const { webSearch: defaultSearch } = require('../tavily');
const { apiError } = require('../../utils/apiError');
const { parseJsonLoose, normaliseVerdicts } = require('./report');
const prompts = require('./prompts');
const metrics = require('./metrics');

const MAX_CLAIMS = 8;
const FALLBACK_CLAIMS = 6;
const CHUNK_CHARS = 6000;
const MAX_SAMPLED_WINDOWS = 6;
const SEARCH_BUDGET_MS = 20000;
const SEARCH_RESULTS = 3;
const CLAIM_KINDS = new Set(['statistic', 'date', 'name', 'quote', 'causal']);

// ---------------------------------------------------------------------------
// Chunking
// ---------------------------------------------------------------------------
function splitPageSections(text) {
  const source = String(text || '');
  const marker = /\[page (\d+)\]/gi;
  const matches = [...source.matchAll(marker)];
  if (!matches.length) return null;
  return matches.map((match, index) => {
    const start = match.index + match[0].length;
    const end = index + 1 < matches.length ? matches[index + 1].index : source.length;
    return { page: Number(match[1]), body: source.slice(start, end).trim() };
  }).filter((section) => section.body);
}

function chunkText(text, maxChars = CHUNK_CHARS) {
  const source = String(text || '').trim();
  if (!source) return [];
  if (source.length <= maxChars) return [source];

  const paragraphs = source.split(/\n{2,}/);
  const chunks = [];
  let current = '';
  const push = () => {
    if (current.trim()) chunks.push(current.trim());
    current = '';
  };

  for (const paragraph of paragraphs) {
    if (paragraph.length > maxChars) {
      push();
      // A single huge paragraph: split on sentence boundaries, then hard-slice
      // anything still over the cap.
      const sentences = paragraph.split(/(?<=[.!?])\s+/);
      let buffer = '';
      for (const sentence of sentences) {
        if (sentence.length > maxChars) {
          if (buffer.trim()) chunks.push(buffer.trim());
          buffer = '';
          for (let i = 0; i < sentence.length; i += maxChars) {
            chunks.push(sentence.slice(i, i + maxChars));
          }
        } else if ((buffer + ' ' + sentence).trim().length > maxChars) {
          chunks.push(buffer.trim());
          buffer = sentence;
        } else {
          buffer = `${buffer} ${sentence}`.trim();
        }
      }
      if (buffer.trim()) chunks.push(buffer.trim());
      continue;
    }
    if ((current + '\n\n' + paragraph).trim().length > maxChars) {
      push();
      current = paragraph;
    } else {
      current = `${current}\n\n${paragraph}`.trim();
    }
  }
  push();
  return chunks;
}

// Returns [{ page: number|null, text }]. Page markers from the extractor keep
// the claim's page number meaningful; text without markers yields null pages.
function chunkMaterial(text, maxChars = CHUNK_CHARS) {
  const sections = splitPageSections(text);
  if (!sections) {
    return chunkText(text, maxChars).map((chunk) => ({ page: null, text: chunk }));
  }
  return sections.flatMap((section) => chunkText(section.body, maxChars)
    .map((chunk) => ({ page: section.page, text: chunk })));
}

// Evenly sample windows so a long document is represented across its whole
// length rather than only its first 60,000 characters.
function selectWindows(windows, max = MAX_SAMPLED_WINDOWS) {
  if (!windows.length) return [];
  if (windows.length <= max) return windows;
  const picked = [];
  for (let i = 0; i < max; i += 1) {
    const index = Math.round((i * (windows.length - 1)) / (max - 1));
    if (!picked.includes(windows[index])) picked.push(windows[index]);
  }
  return picked;
}

// ---------------------------------------------------------------------------
// Deterministic fallback: no model, no second failure mode.
// ---------------------------------------------------------------------------
function sentenceScore(sentence) {
  let score = 0;
  if (/\d/.test(sentence)) score += 3;
  if (/\b\d{1,3}(?:[.,]\d+)?\s?%/.test(sentence)) score += 2;
  if (/\b(?:19|20)\d{2}\b/.test(sentence)) score += 2;
  if (/["“”']/.test(sentence)) score += 1;
  if (/\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+\b/.test(sentence)) score += 2;
  if (/[A-Za-z]{3,}/.test(sentence)) score += 1;
  if (sentence.length >= 40 && sentence.length <= 300) score += 1;
  return score;
}

function kindForSentence(sentence) {
  if (/\b(?:19|20)\d{2}\b/.test(sentence) && !/\d{2,}\s?%/.test(sentence)) return 'date';
  if (/\d/.test(sentence)) return 'statistic';
  if (/["“”']/.test(sentence)) return 'quote';
  if (/\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+/.test(sentence)) return 'name';
  return 'causal';
}

function fallbackClaims(windows, cap = FALLBACK_CLAIMS) {
  // One round per window keeps page coverage even when the first page is dense.
  const perWindow = windows.map((window) => {
    const sentences = String(window.text)
      .replace(/\[page \d+\]/gi, ' ')
      .split(/(?<=[.!?])\s+/)
      .map((sentence) => sentence.replace(/\s+/g, ' ').trim())
      .filter((sentence) => sentence.length >= 20 && sentence.length <= 400)
      .map((sentence) => ({ sentence, score: sentenceScore(sentence) }))
      .filter((entry) => entry.score >= 3)
      .sort((a, b) => b.score - a.score);
    return sentences.map((entry) => ({
      text: entry.sentence.slice(0, 300),
      page: window.page,
      kind: kindForSentence(entry.sentence),
    }));
  });

  const picked = [];
  const seen = new Set();
  let round = 0;
  while (picked.length < cap && perWindow.some((list) => list.length > round)) {
    for (const list of perWindow) {
      const candidate = list[round];
      if (!candidate) continue;
      const key = candidate.text.toLowerCase();
      if (seen.has(key)) continue;
      seen.add(key);
      picked.push(candidate);
      if (picked.length >= cap) break;
    }
    round += 1;
  }
  return picked;
}

// ---------------------------------------------------------------------------
// Claim extraction
// ---------------------------------------------------------------------------
function findPageForClaim(text, windows) {
  const needle = String(text || '').slice(0, 40).toLowerCase().replace(/\s+/g, ' ');
  if (!needle) return null;
  for (const window of windows) {
    const haystack = String(window.text || '').toLowerCase().replace(/\s+/g, ' ');
    if (haystack.includes(needle) && window.page != null) return window.page;
  }
  return null;
}

// A paraphrased claim will not match verbatim. Fall back to the window with the
// strongest word overlap so a document claim still carries a page number
// whenever one window is clearly its source.
function inferPage(text, windows) {
  const exact = findPageForClaim(text, windows);
  if (exact != null) return exact;

  const claimWords = new Set(String(text || '').toLowerCase().match(/[a-z]{4,}/g) || []);
  if (!claimWords.size) return null;
  let best = null;
  let bestScore = 0;
  for (const window of windows) {
    if (window.page == null) continue;
    const words = new Set(String(window.text || '').toLowerCase().match(/[a-z]{4,}/g) || []);
    let overlap = 0;
    for (const word of claimWords) if (words.has(word)) overlap += 1;
    if (overlap > bestScore) {
      bestScore = overlap;
      best = window.page;
    }
  }
  const threshold = Math.max(2, Math.ceil(claimWords.size * 0.3));
  return bestScore >= threshold ? best : null;
}

function normaliseClaims(parsed, windows) {
  const raw = Array.isArray(parsed && parsed.claims) ? parsed.claims : null;
  if (!raw) return [];

  const claims = [];
  const seen = new Set();
  for (const item of raw) {
    if (!item || typeof item !== 'object') continue;
    const text = typeof item.text === 'string' ? item.text.trim().slice(0, 300) : '';
    if (text.length < 10) continue;
    const key = text.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);

    const page = Number.isInteger(Number(item.page)) && item.page !== null && item.page !== ''
      ? Number(item.page)
      : inferPage(text, windows);
    const kind = CLAIM_KINDS.has(item.kind) ? item.kind : 'causal';
    claims.push({ text, page: page == null ? null : Number(page), kind });
    if (claims.length >= MAX_CLAIMS) break;
  }
  return claims;
}

async function extractClaims({ material, complete = completeJsonCompletion, maxClaims = MAX_CLAIMS, requestId = null }) {
  const windows = chunkMaterial(material);
  if (!windows.length) return [];

  const sampled = selectWindows(windows);
  try {
    const result = await complete({
      profile: 'claims',
      system: prompts.claimExtractionSystem(),
      user: prompts.claimExtractionUser(sampled),
    });
    // Diagnostics only: stage, finish reason and token usage. Never document
    // text or model output (BF-2).
    console.info(
      `[${requestId || 'no-request-id'}] verification stage=claims finish=${result && result.finish} tokens=${result && result.usage && result.usage.total_tokens}`,
    );
    const parsed = parseJsonLoose(result && result.content);
    if (parsed && Array.isArray(parsed.claims)) {
      const claims = normaliseClaims(parsed, sampled);
      if (!claims.length) metrics.recordFailure('no_claims');
      return claims.slice(0, maxClaims);
    }
    metrics.recordFailure('parsing');
  } catch (err) {
    metrics.recordFailure('transport');
    console.error(`[${requestId || 'no-request-id'}] verification stage=claims failed: ${err && err.message}`);
  }

  // The model failed in any way: deterministic sentence scan (capped at 6).
  console.warn(`[${requestId || 'no-request-id'}] verification metrics ${JSON.stringify(metrics.snapshot())}`);
  return fallbackClaims(sampled, Math.min(FALLBACK_CLAIMS, maxClaims));
}

// ---------------------------------------------------------------------------
// Evidence searches
// ---------------------------------------------------------------------------
// Sequential on purpose: Tavily and the model provider enforce their own
// concurrency limits, and a hard wall-clock budget bounds the total wait.
async function searchClaims(claims, {
  search = defaultSearch,
  maxResults = SEARCH_RESULTS,
  budgetMs = SEARCH_BUDGET_MS,
  clock = Date.now,
} = {}) {
  const prepared = claims.map((claim) => ({ ...claim, evidence: [] }));
  const byUrl = new Map();
  const started = clock();
  let searchesRun = 0;

  for (let index = 0; index < prepared.length; index += 1) {
    if (index > 0 && clock() - started > budgetMs) break;
    let results = [];
    try {
      results = await search(prepared[index].text, { maxResults });
    } catch (err) {
      console.error(`[verification] claim search failed: ${err && err.message}`);
      results = [];
    }
    searchesRun += 1;
    for (const result of results || []) {
      if (!result || !result.url) continue;
      let source = byUrl.get(result.url);
      if (!source) {
        source = {
          title: String(result.title || result.url).slice(0, 200),
          url: String(result.url).slice(0, 500),
          content: String(result.content || '').replace(/\s+/g, ' ').slice(0, 500),
        };
        byUrl.set(source.url, source);
      }
      prepared[index].evidence.push(source);
    }
  }

  // Public `sources` keeps the frozen contract shape ({ title, url }); the
  // content snippet stays internal and is only shown to the verdict model.
  const sources = [...byUrl.values()].map(({ title, url }) => ({ title, url }));
  return { claims: prepared, sources, searchesRun };
}

// ---------------------------------------------------------------------------
// Verdicts
// ---------------------------------------------------------------------------
function unreadable() {
  return apiError(502, 'report_unreadable', 'Model returned no usable verdict JSON after one repair attempt.', {
    publicMessage: 'The AI service returned a report we could not read.',
    hint: 'Please try again. If it keeps happening, try checking a shorter section.',
    retryable: true,
  });
}

async function judgeClaims({ material, claims, complete = completeJsonCompletion, requestId = null }) {
  if (!claims.length) return [];

  let previous = '';
  for (let attempt = 0; attempt < 2; attempt += 1) {
    const user = attempt === 0
      ? prompts.verdictUser({ material, claims })
      : `${prompts.verdictUser({ material, claims })}\n\n${prompts.repairUser(previous)}`;

    let result;
    try {
      result = await complete({
        profile: 'verification',
        system: prompts.verdictSystem(),
        user,
      });
    } catch (err) {
      metrics.recordFailure('transport');
      console.error(
        `[${requestId || 'no-request-id'}] verification stage=verdicts failed: ${err && err.message}`,
      );
      throw err;
    }

    console.info(
      `[${requestId || 'no-request-id'}] verification stage=verdicts attempt=${attempt + 1} finish=${result && result.finish} tokens=${result && result.usage && result.usage.total_tokens}`,
    );
    previous = (result && result.content) || '';
    const parsed = parseJsonLoose(previous);
    const verdicts = normaliseVerdicts(parsed, claims);
    if (verdicts) return verdicts;
    metrics.recordFailure('parsing');
  }

  // Exactly one repair attempt was made above; now fail honestly.
  console.warn(`[${requestId || 'no-request-id'}] verification metrics ${JSON.stringify(metrics.snapshot())}`);
  throw unreadable();
}

module.exports = {
  MAX_CLAIMS,
  CHUNK_CHARS,
  splitPageSections,
  chunkText,
  chunkMaterial,
  selectWindows,
  fallbackClaims,
  normaliseClaims,
  extractClaims,
  searchClaims,
  judgeClaims,
};
