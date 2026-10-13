const pool = require('../db/pool');
const { requiredString, optionalString, clampInt } = require('../middleware/validate');
const { findUserByFirebaseUid } = require('../db/users');
const { analyzeContent } = require('../services/nvidiaAssistant');
const { webSearch } = require('../services/tavily');
const { extractDocument, fetchUrl } = require('../services/extract');
const { OVERALL_STATUSES } = require('../services/llm/prompts');
const { handleAiError } = require('../middleware/aiError');

const KINDS = new Set(['document', 'claim', 'ai_response', 'source']);
const SOURCE_TYPES = new Set(['text', 'url', 'citation', 'document']);
const MAX_CONTENT_LENGTH = 60000;
const MAX_CONTEXT_LENGTH = 5000;
const MAX_TOTAL_CHARS = 120000;

// The model is asked for strict JSON but is not trusted: parse defensively and
// coerce every field into the report schema.
function parseReport(raw) {
  let text = String(raw || '').trim();
  const fence = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fence) text = fence[1].trim();
  const start = text.indexOf('{');
  const end = text.lastIndexOf('}');
  if (start >= 0 && end > start) text = text.slice(start, end + 1);

  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch {
    const error = new Error('The AI service returned an unreadable report.');
    error.status = 502;
    throw error;
  }

  const overallStatus = OVERALL_STATUSES.includes(parsed.overall_status)
    ? parsed.overall_status
    : 'human_review_required';
  const items = Array.isArray(parsed.items_requiring_review)
    ? parsed.items_requiring_review
        .filter((item) => item && typeof item.claim === 'string' && typeof item.concern === 'string')
        .map((item) => ({
          claim: item.claim.trim().slice(0, 500),
          concern: item.concern.trim().slice(0, 1000),
        }))
    : [];
  const sourcesConfirmed =
    Number.isInteger(parsed.sources_confirmed) && parsed.sources_confirmed >= 0
      ? parsed.sources_confirmed
      : 0;
  const summary =
    typeof parsed.summary === 'string' && parsed.summary.trim()
      ? parsed.summary.trim().slice(0, 2000)
      : '';

  return { overall_status: overallStatus, items_requiring_review: items, sources_confirmed: sourcesConfirmed, summary };
}

function bad(message) {
  const error = new Error(message);
  error.status = 400;
  return error;
}

// Resolves the submitted material into one analysable document. Each input type
// is handled here: uploaded documents are parsed, links are fetched, citations
// are looked up. Nothing is persisted.
async function buildEvidence(req) {
  const pieces = [];
  const inputs = [];
  const citationResults = [];
  let documentName = optionalString(req.body.document_name, 'document_name', 255) ?? null;
  let primaryQuery = null;

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
    if (!SOURCE_TYPES.has(type)) throw bad(`Unknown source type: ${type || '(missing)'}.`);

    if (type === 'text') {
      const text = requiredString(source.text, 'source.text', MAX_CONTENT_LENGTH);
      const label = optionalString(source.label, 'source.label', 120) || 'Pasted text';
      pieces.push({ label, text });
      inputs.push({ type: 'text', label, chars: text.length });
      if (!primaryQuery) primaryQuery = text;
    } else if (type === 'url') {
      const url = requiredString(source.url, 'source.url', 2000);
      const fetched = await fetchUrl(url);
      pieces.push({ label: `Linked page: ${fetched.label}`, text: fetched.text || '(no readable text)' });
      inputs.push({ type: 'url', label: fetched.url, chars: fetched.text.length });
      if (!primaryQuery) primaryQuery = fetched.text;
    } else if (type === 'citation') {
      const citation = requiredString(source.text, 'source.text', 1000);
      const results = await webSearch(citation, { maxResults: 4 });
      const text = results.length
        ? results.map((r, i) => `${i + 1}. ${r.title} (${r.url}) - ${r.content}`).join('\n')
        : 'No matching sources found.';
      pieces.push({ label: `Citation lookup: ${citation}`, text });
      inputs.push({ type: 'citation', label: citation, chars: text.length });
      citationResults.push(...results);
      if (!primaryQuery) primaryQuery = citation;
    } else if (type === 'document') {
      const doc = await extractDocument({ base64: source.base64, mime: source.mime, name: source.name });
      pieces.push({ label: `Document: ${doc.label}`, text: doc.text || '(no readable text)' });
      inputs.push({ type: 'document', label: doc.label, chars: doc.text.length });
      if (!documentName) documentName = doc.label;
      if (!primaryQuery) primaryQuery = doc.text;
    }
  }

  if (!pieces.length) throw bad('Provide content, context or at least one source to analyse.');

  let combined = pieces.map((p) => `## ${p.label}\n${p.text}`).join('\n\n');
  if (combined.length > MAX_TOTAL_CHARS) combined = combined.slice(0, MAX_TOTAL_CHARS);

  return { combined, inputs, citationResults, documentName, primaryQuery: primaryQuery || combined };
}

// POST /api/verification/analyze
// Body: { kind, content?|sources[]|context?, document_name?, web_search? }
// Stores metadata + the report only. The submitted content is never persisted.
async function analyzeVerification(req, res, next) {
  try {
    const kind = requiredString(req.body.kind, 'kind', 20).toLowerCase();
    if (!KINDS.has(kind)) {
      return res.status(400).json({
        error: 'kind must be one of document, claim, ai_response, source.',
        request_id: req.requestId,
      });
    }

    const user = await findUserByFirebaseUid(pool, req.firebaseUser.uid);
    if (!user) {
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }

    const evidence = await buildEvidence(req);

    // Live web search of the primary material, plus any citation lookups.
    const useWeb = req.body.web_search !== false;
    const searched = useWeb ? await webSearch(evidence.primaryQuery, { maxResults: 5 }) : [];
    const byUrl = new Map();
    for (const r of [...evidence.citationResults, ...searched]) {
      if (!byUrl.has(r.url)) byUrl.set(r.url, { title: r.title, url: r.url });
    }
    const webResults = [...byUrl.values()];

    const raw = await analyzeContent({ kind, content: evidence.combined, webResults });
    const report = parseReport(raw);
    report.sources = webResults;

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
        report.items_requiring_review.length,
        report.sources_confirmed,
        report.summary,
        JSON.stringify(report),
      ],
    );

    return res.status(201).json({
      analysis: inserted.rows[0],
      sources: webResults,
      inputs: evidence.inputs,
      web_searched: webResults.length > 0,
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
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
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

    return res.status(200).json({ analyses: result.rows, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

module.exports = { analyzeVerification, listAnalyses, buildEvidence };
