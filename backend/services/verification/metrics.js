// Verification failure counters. The next QA round needs to distinguish a
// transport failure from an unreadable model reply from a no-evidence result;
// the counters are exposed for logs/tests without exporting document content.
const counters = {
  transport: 0,
  parsing: 0,
  evidence: 0,
  no_claims: 0,
};

function recordFailure(stage) {
  if (Object.prototype.hasOwnProperty.call(counters, stage)) counters[stage] += 1;
}

function snapshot() {
  return { ...counters };
}

function resetMetrics() {
  for (const key of Object.keys(counters)) counters[key] = 0;
}

module.exports = { recordFailure, snapshot, resetMetrics };
