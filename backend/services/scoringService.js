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

function calculateXp(score) {
  const bounded = Math.max(0, Math.min(100, Number(score) || 0));
  return Math.max(10, Math.min(70, 20 + Math.round(bounded * 0.5)));
}

function calculateLevel(xp) {
  return Math.max(1, Math.floor(Math.max(0, Number(xp) || 0) / 250) + 1);
}

module.exports = {
  normalize,
  tokenize,
  extractKeywords,
  scoreAnswer,
  calculateXp,
  calculateLevel,
};
