const assert = require('node:assert/strict');
const { test } = require('node:test');
const {
  deriveStatus, deriveReport, parseJsonLoose, normaliseVerdicts, shapeAnalysisRow,
} = require('../services/verification/report');

const supported = (text = 'A') => ({
  text, page: 1, kind: 'statistic', evidence: [{ title: 'S', url: 'https://example.org/s' }],
});
const claim = (verdict, evidenceUrl = 'https://example.org/s') => ({
  claim: 'x', page: 1, verdict, concern: '', evidence: evidenceUrl ? [{ title: 'S', url: evidenceUrl }] : [],
});

test('derivation matrix: contradicted always needs human review', () => {
  assert.equal(deriveStatus({
    claims: [claim('contradicted'), claim('supported')],
    checks: { claims_checked: 2, sources_found: 1 },
  }), 'human_review_required');
});

test('derivation matrix: claims checked with zero sources is insufficient evidence', () => {
  assert.equal(deriveStatus({
    claims: [claim('supported', null)],
    checks: { claims_checked: 1, sources_found: 0 },
  }), 'insufficient_evidence');
});

test('derivation matrix: all checked claims supported is appears_sound', () => {
  assert.equal(deriveStatus({
    claims: [claim('supported'), claim('supported')],
    checks: { claims_checked: 2, sources_found: 1 },
  }), 'appears_sound');
});

test('derivation matrix: a mix of supported and unverified needs human review', () => {
  assert.equal(deriveStatus({
    claims: [claim('supported'), claim('unverified')],
    checks: { claims_checked: 2, sources_found: 1 },
  }), 'human_review_required');
});

test('appears_sound is unreachable with zero claims or zero sources', () => {
  assert.equal(deriveStatus({ claims: [], checks: { claims_checked: 0, sources_found: 3 } }), 'insufficient_evidence');
  assert.equal(deriveStatus({
    claims: [claim('supported')],
    checks: { claims_checked: 1, sources_found: 0 },
  }), 'insufficient_evidence');
});

test('sources_confirmed is computed from verdicts, never trusted from the model', () => {
  const report = deriveReport({
    kind: 'claim',
    documentName: null,
    claims: [claim('supported'), claim('contradicted'), claim('unverified')],
    checks: { claims_checked: 3, sources_found: 2 },
    citationsChecked: 1,
    webSearched: true,
  });
  assert.equal(report.version, 2);
  assert.equal(report.sources_confirmed, 1);
  assert.equal(report.checks.web_search, true);
  assert.equal(report.checks.claims_checked, 3);
  assert.equal(report.checks.citations_checked, 1);
  assert.equal(report.overall_status, 'human_review_required');
});

test('a verdict without an attributable URL is downgraded to unverified', () => {
  const claims = [{ text: 'Revenue grew 15%.', page: null, kind: 'statistic', evidence: [{ title: 'S', url: 'https://example.org/s' }] }];
  const verdicts = normaliseVerdicts({
    verdicts: [{ id: 1, verdict: 'supported', concern: '', evidence: ['https://invented.example/x'] }],
  }, claims);
  assert.equal(verdicts[0].verdict, 'unverified');
  assert.deepEqual(verdicts[0].evidence, []);
});

test('a verdict list that omits a claim is rejected (no silent default)', () => {
  const claims = [
    { text: 'One claim.', page: 1, evidence: [] },
    { text: 'Another claim.', page: 2, evidence: [] },
  ];
  assert.equal(normaliseVerdicts({ verdicts: [{ id: 1, verdict: 'unverified', concern: '', evidence: [] }] }, claims), null);
});

test('parseJsonLoose accepts fenced JSON and prose around an object', () => {
  assert.deepEqual(parseJsonLoose('```json\n{"a":1}\n```'), { a: 1 });
  assert.deepEqual(parseJsonLoose('Here you go: {"a":2} — done.'), { a: 2 });
  assert.equal(parseJsonLoose('not json'), null);
  assert.equal(parseJsonLoose(''), null);
});

test('legacy v1 rows keep their old shape; v2 rows are shaped from the payload', () => {
  const legacy = shapeAnalysisRow({
    id: 1, overall_status: 'appears_sound', summary: 'old', report: { overall_status: 'appears_sound' },
  });
  assert.equal(legacy.version, 1);
  assert.equal(legacy.overall_status, 'appears_sound');

  const modern = shapeAnalysisRow({
    id: 2, overall_status: 'appears_sound', summary: 'old',
    report: { version: 2, overall_status: 'human_review_required', summary: 'new', checks: {}, claims: [claim('contradicted')], sources_confirmed: 0 },
  });
  assert.equal(modern.version, 2);
  assert.equal(modern.overall_status, 'human_review_required');
  assert.equal(modern.claims.length, 1);
});
