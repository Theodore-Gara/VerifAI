// Pure report logic for Verification Studio v2 (BF-3).
//
// The model supplies per-claim verdicts; the server decides the overall status.
// This is the honesty requirement: a report can never say "appears sound" when
// no source was found, and a report with no checkable claims can never be sound.
const VERDICTS = ['supported', 'contradicted', 'unverified'];

// Model output is untrusted text. Accept fenced JSON or JSON with prose around
// it, but return null rather than guessing when there is no object.
function parseJsonLoose(raw) {
  let text = String(raw == null ? '' : raw).trim();
  if (!text) return null;

  const fence = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fence) text = fence[1].trim();

  // Fast path: the whole reply is JSON.
  try {
    const parsed = JSON.parse(text);
    return parsed && typeof parsed === 'object' ? parsed : null;
  } catch {
    // Fall through to extract the outermost object.
  }

  const start = text.indexOf('{');
  const end = text.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    const parsed = JSON.parse(text.slice(start, end + 1));
    return parsed && typeof parsed === 'object' ? parsed : null;
  } catch {
    return null;
  }
}

function validHttpUrl(value) {
  try {
    const url = new URL(String(value));
    return url.protocol === 'http:' || url.protocol === 'https:';
  } catch {
    return false;
  }
}

// Aligns the model's verdict list with the claim list. A verdict that names no
// URL from that claim's evidence is downgraded to unverified: the report must
// not claim corroboration it cannot show.
function normaliseVerdicts(parsed, claims) {
  const rawList = Array.isArray(parsed && parsed.verdicts) ? parsed.verdicts : null;
  if (!rawList) return null;

  const byId = new Map();
  for (const item of rawList) {
    if (!item || typeof item !== 'object') continue;
    const id = Number(item.id);
    if (!Number.isInteger(id) || id < 1 || id > claims.length) continue;
    byId.set(id, item);
  }
  // Every claim must be answered; a missing claim is not a silent "supported".
  if (byId.size !== claims.length) return null;

  return claims.map((claim, index) => {
    const item = byId.get(index + 1);
    let verdict = VERDICTS.includes(item.verdict) ? item.verdict : 'unverified';
    const concern = typeof item.concern === 'string'
      ? item.concern.trim().slice(0, 300)
      : '';
    const claimedUrls = Array.isArray(item.evidence) ? item.evidence.filter(validHttpUrl).map(String) : [];
    const evidenceByUrl = new Map((claim.evidence || []).map((source) => [source.url, source]));
    let evidence = claimedUrls
      .map((url) => evidenceByUrl.get(url))
      .filter(Boolean)
      .map((source) => ({ title: source.title, url: source.url }));

    if ((verdict === 'supported' || verdict === 'contradicted') && evidence.length === 0) {
      // No attributable source: do not overstate what was checked.
      verdict = 'unverified';
      evidence = [];
    }

    return {
      claim: claim.text,
      page: claim.page == null ? null : Number(claim.page),
      verdict,
      concern: concern || (verdict === 'unverified'
        ? 'We could not find a source to confirm or contradict this claim.'
        : ''),
      evidence,
    };
  });
}

// The full derivation matrix from BF-3:
//   any contradicted                                  -> human_review_required
//   claims_checked > 0 and sources_found === 0        -> insufficient_evidence
//   every checked claim supported (and at least one)  -> appears_sound
//   otherwise                                         -> human_review_required
// Plus: zero checkable claims can never be appears_sound.
function deriveStatus({ claims, checks }) {
  if (!claims.length || checks.claims_checked === 0) return 'insufficient_evidence';
  if (claims.some((claim) => claim.verdict === 'contradicted')) return 'human_review_required';
  if (checks.sources_found === 0) return 'insufficient_evidence';
  if (claims.every((claim) => claim.verdict === 'supported')) return 'appears_sound';
  return 'human_review_required';
}

function buildSummary({ claims, checks, status }) {
  if (!claims.length) {
    return 'No checkable factual claims were found in this material, so it could not be verified.';
  }
  if (checks.sources_found === 0) {
    return `We checked ${claims.length} claim${claims.length === 1 ? '' : 's'} but could not find any sources to confirm or contradict them.`;
  }
  const supported = claims.filter((claim) => claim.verdict === 'supported').length;
  const contradicted = claims.filter((claim) => claim.verdict === 'contradicted').length;
  const unverified = claims.length - supported - contradicted;
  const parts = [`${supported} of ${claims.length} claims were supported by a source`];
  if (contradicted) parts.push(`${contradicted} contradicted`);
  if (unverified) parts.push(`${unverified} could not be confirmed`);
  let summary = `${parts.join('; ')}.`;
  if (status === 'human_review_required') {
    summary += ' Review the highlighted claims before relying on this material.';
  }
  return summary;
}

function deriveReport({ kind, documentName, claims, checks, citationsChecked = 0, webSearched }) {
  const sourcesConfirmed = claims.filter((claim) => claim.verdict === 'supported').length;
  const checksBlock = {
    web_search: webSearched === undefined ? checks.claims_checked > 0 : !!webSearched,
    sources_found: Number(checks.sources_found) || 0,
    claims_checked: Number(checks.claims_checked) || 0,
    citations_checked: Number(citationsChecked) || 0,
  };
  const status = deriveStatus({ claims, checks: checksBlock });

  return {
    version: 2,
    kind,
    document_name: documentName || null,
    overall_status: status,
    summary: buildSummary({ claims, checks: checksBlock, status }),
    checks: checksBlock,
    claims,
    sources_confirmed: sourcesConfirmed,
  };
}

const LEGACY_STATUSES = new Set(['appears_sound', 'human_review_required', 'insufficient_evidence']);

// Normalises a stored row for the API. Version-1 rows have no `claims`; they
// keep their old shape and the app treats them as legacy.
function shapeAnalysisRow(row) {
  if (!row) return row;
  const report = row.report && typeof row.report === 'object' ? row.report : {};
  if (Array.isArray(report.claims)) {
    return {
      ...row,
      version: Number(report.version) || 2,
      overall_status: LEGACY_STATUSES.has(report.overall_status) ? report.overall_status : row.overall_status,
      summary: report.summary || row.summary,
      checks: report.checks || null,
      claims: report.claims,
      sources_confirmed: report.sources_confirmed ?? row.sources_confirmed,
    };
  }
  return { ...row, version: 1 };
}

module.exports = {
  VERDICTS,
  parseJsonLoose,
  normaliseVerdicts,
  deriveStatus,
  deriveReport,
  buildSummary,
  shapeAnalysisRow,
};
