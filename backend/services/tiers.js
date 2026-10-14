// Learner tiers are derived from the 0-100 readiness score: higher readiness
// means a higher tier. There is no separate volume counter, so moving to a new
// tier (or back down after a weak run) follows the readiness score directly.
const TIERS = [
  { name: 'Novice', min: 0 },
  { name: 'Developing', min: 50 },
  { name: 'Proficient', min: 70 },
  { name: 'Advanced', min: 85 },
];

function clampScore(score) {
  const n = Number(score);
  if (!Number.isFinite(n)) return 0;
  return Math.max(0, Math.min(100, n));
}

// Highest tier whose minimum the score has reached.
function tierForScore(score) {
  const value = clampScore(score);
  let name = TIERS[0].name;
  for (const tier of TIERS) {
    if (value >= tier.min) name = tier.name;
  }
  return name;
}

// The next tier up, or null at the top.
function nextTier(tierName) {
  const index = TIERS.findIndex((t) => t.name === tierName);
  if (index < 0 || index >= TIERS.length - 1) return null;
  return TIERS[index + 1];
}

module.exports = { TIERS, tierForScore, nextTier };
