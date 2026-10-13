const pool = require('../db/pool');
const { requiredString, optionalString, clampInt } = require('../middleware/validate');
const { findUserByFirebaseUid } = require('../db/users');
const { analyzeContent } = require('../services/nvidiaAssistant');
const { webSearch } = require('../services/tavily');
const { OVERALL_STATUSES } = require('../services/llm/prompts');
const { handleAiError } = require('../middleware/aiError');

const KINDS = new Set(['document', 'claim', 'ai_response', 'source']);
const MAX_CONTENT_LENGTH = 60000;

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

// POST /api/verification/analyze
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
    const content = requiredString(req.body.content, 'content', MAX_CONTENT_LENGTH);
    const documentName = optionalString(req.body.document_name, 'document_name', 255);

    const user = await findUserByFirebaseUid(pool, req.firebaseUser.uid);
    if (!user) {
      return res.status(404).json({ error: 'User not found. Call /api/auth/sync first.', request_id: req.requestId });
    }

    // Vera verifies the input, using live web search as evidence when available.
    const useWeb = req.body.web_search !== false;
    const webResults = useWeb ? await webSearch(content, { maxResults: 5 }) : [];

    const raw = await analyzeContent({ kind, content, webResults });
    const report = parseReport(raw);
    report.sources = webResults.map((r) => ({ title: r.title, url: r.url }));

    const inserted = await pool.query(
      `INSERT INTO verification_analyses
        (user_id, kind, document_name, overall_status, items_requiring_review, sources_confirmed, summary, report)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       RETURNING id, kind, document_name, overall_status, items_requiring_review, sources_confirmed, summary, report, created_at`,
      [
        user.id,
        kind,
        documentName ?? null,
        report.overall_status,
        report.items_requiring_review.length,
        report.sources_confirmed,
        report.summary,
        JSON.stringify(report),
      ],
    );

    return res.status(201).json({
      analysis: inserted.rows[0],
      sources: report.sources,
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

module.exports = { analyzeVerification, listAnalyses };
