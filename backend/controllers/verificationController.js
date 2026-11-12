const pool = require('../db/pool');
const { requiredString, optionalString, clampInt } = require('../middleware/validate');
const { findUserByFirebaseUid } = require('../db/users');
const { extractDocument, fetchUrl } = require('../services/extract');
const { webSearch } = require('../services/tavily');
const { extractClaims, searchClaims, judgeClaims } = require('../services/verification/claims');
const { deriveReport, shapeAnalysisRow } = require('../services/verification/report');
const { handleAiError } = require('../middleware/aiError');
const { apiError } = require('../utils/apiError');

const KINDS = new Set(['document', 'claim', 'ai_response', 'source']);
const SOURCE_TYPES = new Set(['text', 'url', 'citation', 'document']);
const MAX_CONTENT_LENGTH = 60000;
const MAX_CONTEXT_LENGTH = 5000;
const MAX_TOTAL_CHARS = 120000;
// A linked page with less readable text than this cannot be analysed. Without
// the guard the pipeline "succeeds" on a navigation strip and reports
// "not enough evidence", which reads like a verdict on the page.
const MIN_LINK_CHARS = 40;

function bad(status, code, message, options) {
  return apiError(status, code, message, options);
}

// Words that carry no matching weight when deciding whether a citation lookup
// is relevant to a claim.
const STOP_WORDS = new Set([
  'the', 'and', 'for', 'that', 'this', 'with', 'from', 'have', 'has', 'was', 'were',
  'are', 'not', 'but', 'its', 'their', 'they', 'you', 'your', 'our', 'about', 'into',
  'over', 'under', 'than', 'then', 'when', 'where', 'which', 'who', 'what', 'how',
  'section', 'according', 'report', 'study',
]);

function significantWords(value) {
  return new Set(
    String(value || '')
      .toLowerCase()
      .match(/[a-z0-9]{4,}/g)
      ?.filter((word) => !STOP_WORDS.has(word)) || [],
  );
}

// User-supplied citations are a distinct evidence set. A citation lookup is
// attached to a claim when their wording overlaps; either way it is counted in
// `checks.citations_checked`, so the app can show that lookups ran.
function attachCitations(claims, citationSearches) {
  if (!citationSearches.length) return;
  for (const claim of claims) {
    const claimWords = significantWords(claim.text);
    for (const citation of citationSearches) {
      const overlap = [...significantWords(citation.query)].filter((word) => claimWords.has(word));
      if (overlap.length < 2) continue;
      for (const source of citation.sources) {
        if (!claim.evidence.some((item) => item.url === source.url)) claim.evidence.push(source);
      }
    }
  }
}

// Resolves the submitted material into one analysable document plus structured
// input metadata. Each input type is handled here: uploaded documents are
// parsed, links are fetched, citations are looked up. Nothing is persisted.
async function buildEvidence(req) {
  const pieces = [];
  const inputs = [];
  const citationSearches = [];
  let documentName = optionalString(req.body.document_name, 'document_name', 255) ?? null;

  const contextText = optionalString(req.body.context, 'context', MAX_CONTEXT_LENGTH);
  if (contextText) {
    pieces.push({ label: 'Context from the user', text: contextText });
    inputs.push({ type: 'context', label: 'Context', chars: contextText.length });
  }

  const sources = [];
  const legacy = optionalString(req.body.content, 'content', MAX_CONTENT_LENGTH);
  if (legacy) sources.push({ type: 'text', text: legacy });
  if (Array.isArray(req.body.sources)) sources.push(...req.body.sources.slice(0, 20));

  for (const source of sources) {
    const type = String((source && source.type) || '').toLowerCase();
    if (!SOURCE_TYPES.has(type)) {
      throw bad(400, 'no_input', `Unknown source type: ${type || '(missing)'}.`, {
        publicMessage: `Unknown source type: ${type || '(missing)'}.`,
        hint: 'Use one of text, url, citation or document.',
        retryable: false,
      });
    }

    if (type === 'text') {
      const text = requiredString(source.text, 'source.text', MAX_CONTENT_LENGTH);
      const label = optionalString(source.label, 'source.label', 120) || 'Pasted text';
      pieces.push({ label, text });
      inputs.push({ type: 'text', label, chars: text.length });
    } else if (type === 'url') {
      const url = requiredString(source.url, 'source.url', 2000);
      const fetched = await fetchUrl(url);
      const readable = String(fetched.text || '').replace(/\s+/g, '');
      if (readable.length < MIN_LINK_CHARS) {
        throw bad(422, 'link_no_text', `The linked page yielded ${readable.length} readable characters.`, {
          publicMessage: 'We could not read any text at that link.',
          hint: 'The page may build its content with JavaScript or sit behind a login. Paste the text instead.',
          retryable: false,
        });
      }
      pieces.push({ label: `Linked page: ${fetched.label}`, text: fetched.text });
      inputs.push({ type: 'url', label: fetched.url, chars: fetched.text.length });
    } else if (type === 'citation') {
      const citation = requiredString(source.text, 'source.text', 1000);
      const results = await webSearch(citation, { maxResults: 4 });
      citationSearches.push({ query: citation, sources: results });
      const text = results.length
        ? results.map((r, i) => `${i + 1}. ${r.title} (${r.url}) - ${r.content}`).join('\n')
        : 'No matching sources found.';
      pieces.push({ label: `Citation lookup: ${citation}`, text });
      inputs.push({ type: 'citation', label: citation, chars: text.length });
    } else if (type === 'document') {
      const doc = await extractDocument({ base64: source.base64, mime: source.mime, name: source.name });
      pieces.push({ label: `Document: ${doc.label}`, text: doc.text });
      inputs.push({
        type: 'document',
        label: doc.label,
        chars: doc.text.length,
        pages: doc.pages,
        pages_read: doc.pagesRead,
        truncated: doc.truncated,
        quality: doc.quality,
        ...(doc.warning ? { warning: doc.warning } : {}),
      });
      if (!documentName) documentName = doc.label;
    }
  }

  if (!pieces.length) {
    throw bad(400, 'no_input', 'No content, context or source was supplied.', {
      publicMessage: 'Provide content, context or at least one source to analyse.',
      hint: 'Paste text, upload a document, or add a link.',
      retryable: false,
    });
  }

  let combined = pieces.map((p) => `## ${p.label}\n${p.text}`).join('\n\n');
  if (combined.length > MAX_TOTAL_CHARS) combined = combined.slice(0, MAX_TOTAL_CHARS);

  return {
    combined,
    inputs,
    citationSearches,
    documentName,
    citationsChecked: citationSearches.length,
  };
}

// POST /api/verification/analyze
// Body: { kind, content?|sources[]|context?, document_name?, web_search? }
// Stores metadata + the report only. The submitted content is never persisted.
async function analyzeVerification(req, res, next) {
  try {
    const kind = requiredString(req.body.kind, 'kind', 20).toLowerCase();
    if (!KINDS.has(kind)) {
      throw bad(400, 'no_input', `Invalid kind: ${kind}.`, {
        publicMessage: 'kind must be one of document, claim, ai_response, source.',
        hint: 'Send a supported kind and retry.',
        retryable: false,
      });
    }

    const user = await findUserByFirebaseUid(pool, req.firebaseUser.uid);
    if (!user) {
      throw bad(404, 'user_not_found', 'User not found. Call /api/auth/sync first.', {
        publicMessage: 'User not found. Call /api/auth/sync first.',
        retryable: false,
      });
    }

    const evidence = await buildEvidence(req);

    // BF-1: find claims first, then search per claim - never the document body.
    const claims = await extractClaims({ material: evidence.combined, requestId: req.requestId });

    let searched = { claims: claims.map((claim) => ({ ...claim, evidence: [] })), sources: [], searchesRun: 0 };
    const useWeb = req.body.web_search !== false;
    if (useWeb && claims.length) {
      searched = await searchClaims(claims);
    }
    attachCitations(searched.claims, evidence.citationSearches);

    // Citation lookups are evidence too; keep one de-duplicated source list.
    const byUrl = new Map();
    for (const source of searched.sources) byUrl.set(source.url, { title: source.title, url: source.url });
    for (const citation of evidence.citationSearches) {
      for (const source of citation.sources) {
        if (!byUrl.has(source.url)) byUrl.set(source.url, { title: source.title, url: source.url });
      }
    }
    const sources = [...byUrl.values()];

    const verdicts = await judgeClaims({ material: evidence.combined, claims: searched.claims, requestId: req.requestId });
    const webSearched = useWeb && claims.length > 0;
    const report = deriveReport({
      kind,
      documentName: evidence.documentName,
      claims: verdicts,
      checks: { claims_checked: verdicts.length, sources_found: sources.length },
      citationsChecked: evidence.citationsChecked,
      webSearched,
      webSearchRequested: useWeb,
    });

    const inserted = await pool.query(
      `INSERT INTO verification_analyses
        (user_id, kind, document_name, overall_status, items_requiring_review, sources_confirmed, summary, report)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       RETURNING id, kind, document_name, overall_status, items_requiring_review, sources_confirmed, summary, report, created_at`,
      [
        user.id,
        kind,
        evidence.documentName,
        report.overall_status,
        report.claims.filter((claim) => claim.verdict !== 'supported').length,
        report.sources_confirmed,
        report.summary,
        JSON.stringify(report),
      ],
    );

    return res.status(201).json({
      analysis: {
        ...inserted.rows[0],
        version: report.version,
        checks: report.checks,
        claims: report.claims,
        sources_confirmed: report.sources_confirmed,
        summary: report.summary,
        overall_status: report.overall_status,
      },
      sources,
      inputs: evidence.inputs,
      web_searched: webSearched,
      request_id: req.requestId,
    });
  } catch (err) {
    return handleAiError(err, req, res, next);
  }
}

// GET /api/verification/analyses?limit=
async function listAnalyses(req, res, next) {
  try {
    const limit = clampInt(req.query.limit, 20, 1, 50);
    const user = await findUserByFirebaseUid(pool, req.firebaseUser.uid);
    if (!user) {
      throw bad(404, 'user_not_found', 'User not found. Call /api/auth/sync first.', {
        publicMessage: 'User not found. Call /api/auth/sync first.',
        retryable: false,
      });
    }

    const result = await pool.query(
      `SELECT id, kind, document_name, overall_status, items_requiring_review,
              sources_confirmed, summary, report, created_at
       FROM verification_analyses
       WHERE user_id = $1
       ORDER BY created_at DESC, id DESC
       LIMIT $2`,
      [user.id, limit],
    );

    return res.status(200).json({
      analyses: result.rows.map(shapeAnalysisRow),
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { analyzeVerification, listAnalyses, buildEvidence };
