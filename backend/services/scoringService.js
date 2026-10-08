const STOP_WORDS = new Set([
  'a','an','and','are','as','at','be','by','for','from','has','have','if','in','into','is','it','its','of','on','or','that','the','their','then','this','to','use','using','with','you','your','should','must','can','could','would','will','when','while','than','also','not','but','before','after','only','ensure','check','answer','explain','explanation'
]);

function normalize(text) {
  return String(text || '')
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, ' ')
    .replace(/-/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function tokenize(text) {
  return normalize(text).split(' ').filter(Boolean);
}

function extractKeywords(correctAnswer) {
  const raw = String(correctAnswer || '');
  const explicit = raw.match(/keywords?\s*:\s*(.+)$/i);
  const source = normalize(explicit ? explicit[1] : raw);

  const words = source
    .split(/\s+/)
    .map((word) => word.trim())
    .filter((word) => word.length >= 3 && !STOP_WORDS.has(word));

  return [...new Set(words)];
}

function phrasePresent(answerTokens, phrase) {
  const phraseTokens = tokenize(phrase);
  if (!phraseTokens.length) return false;
  if (phraseTokens.length === 1) return answerTokens.includes(phraseTokens[0]);

  for (let i = 0; i <= answerTokens.length - phraseTokens.length; i += 1) {
    if (phraseTokens.every((token, index) => answerTokens[i + index] === token)) return true;
  }
  return false;
}

// Free-text fallback (Verification scenarios with `keywords` instead of options).
function scoreAnswer(userAnswer, correctAnswer) {
  const normalizedAnswer = normalize(userAnswer);
  const keywords = extractKeywords(correctAnswer);

  if (!normalizedAnswer) {
    return { score: 0, matchedKeywords: [], missedKeywords: keywords, matchRatio: 0, passed: false };
  }

  if (!keywords.length) {
    const exact = normalizedAnswer === normalize(correctAnswer);
    return { score: exact ? 100 : 0, matchedKeywords: [], missedKeywords: [], matchRatio: exact ? 1 : 0, passed: exact };
  }

  const answerTokens = tokenize(normalizedAnswer);
  const matchedKeywords = keywords.filter((keyword) => phrasePresent(answerTokens, keyword));
  const matchRatio = matchedKeywords.length / keywords.length;
  const score = Math.round(matchRatio * 100);

  return {
    score,
    matchedKeywords,
    missedKeywords: keywords.filter((keyword) => !matchedKeywords.includes(keyword)),
    matchRatio,
    passed: score >= 60,
  };
}

// Controlled-choice scoring: sum the selected options' weights (0-100).
// Verification is all-or-nothing (one option scores 100); AI Judgement and
// Risk & Governance split the total across a decision and a reason.
function scoreOptions(optionScores) {
  const total = (optionScores || []).reduce((sum, value) => sum + (Number(value) || 0), 0);
  return Math.max(0, Math.min(100, Math.round(total)));
}

// XP is proportional to the score, so a wrong answer (score 0) earns nothing.
// Difficulty scales the ceiling; partial credit flows through automatically.
const DIFFICULTY_MAX_XP = { easy: 50, medium: 70, hard: 100 };

function calculateXp(score, difficulty = 'medium') {
  const bounded = Math.max(0, Math.min(100, Number(score) || 0));
  if (bounded <= 0) return 0;
  const maxXp = DIFFICULTY_MAX_XP[difficulty] ?? DIFFICULTY_MAX_XP.medium;
  return Math.max(0, Math.min(100, Math.round((bounded / 100) * maxXp)));
}

// Cumulative XP required to *reach* a level. Each level costs +60 more XP than
// the last: L1->L2 250, L2->L3 310, L3->L4 370, ... (250, 560, 930, 1360, ...).
function xpForLevel(level) {
  const k = Math.max(0, Math.floor(Number(level) || 1) - 1);
  return 250 * k + 30 * k * (k - 1);
}

function calculateLevel(xp) {
  const total = Math.max(0, Number(xp) || 0);
  let level = 1;
  while (total >= xpForLevel(level + 1)) level += 1;
  return level;
}

// ---------------------------------------------------------------------------
// Verification 'line_text' scoring
// ---------------------------------------------------------------------------
// Find the flaw: 30 (exact line set). Fix: 40, Reason: 30 (proportional to the
// criteria matched). A criterion is a group of '|'-separated variants; it matches
// if any variant appears in the answer (exact token, phrase, or prefix/stem, or a
// compact alphanumeric substring for numbers like "1,860" -> "1860").

const FLAW_POINTS = 30;
const FIX_POINTS = 40;
const REASON_POINTS = 30;

function compact(text) {
  return String(text || '').toLowerCase().replace(/[^a-z0-9]/g, '');
}

function variantPresent(answerTokens, answerCompact, variant) {
  const vt = tokenize(variant);
  if (!vt.length) return false;
  if (vt.length > 1 && phrasePresent(answerTokens, variant)) return true;
  if (vt.length === 1) {
    const word = vt[0];
    if (answerTokens.some((t) => t === word || (word.length >= 4 && t.startsWith(word)))) return true;
  }
  const cv = compact(variant);
  return cv.length >= 2 && answerCompact.includes(cv);
}

function criterionMatches(answerTokens, answerCompact, criterion) {
  const variants = String(criterion).split('|').map((v) => v.trim()).filter(Boolean);
  return variants.some((v) => variantPresent(answerTokens, answerCompact, v));
}

function scoreCriteria(userText, criteria, points) {
  const list = (criteria || []).filter(Boolean);
  if (!list.length) return { score: 0, matched: 0, total: 0 };
  const answerTokens = tokenize(userText);
  const answerCompact = compact(userText);
  const matched = list.filter((c) => criterionMatches(answerTokens, answerCompact, c)).length;
  return { score: Math.round((points * matched) / list.length), matched, total: list.length };
}

function scoreFlawLines(selected, flawed) {
  const a = [...new Set((selected || []).map(Number))].sort((x, y) => x - y);
  const b = [...new Set((flawed || []).map(Number))].sort((x, y) => x - y);
  const equal = a.length === b.length && b.length > 0 && a.every((v, i) => v === b[i]);
  return equal ? FLAW_POINTS : 0;
}

module.exports = {
  normalize,
  tokenize,
  extractKeywords,
  scoreAnswer,
  scoreOptions,
  scoreCriteria,
  scoreFlawLines,
  FLAW_POINTS,
  FIX_POINTS,
  REASON_POINTS,
  calculateXp,
  xpForLevel,
  calculateLevel,
};
