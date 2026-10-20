// Per-use-case model routing. The main model serves every generative surface
// (chat, coach, learning assistant, analysis/verification, marking reports); the
// smaller 3 super model handles background utility work and is the fallback.
// Every choice is env-overridable.
const MODELS = {
  // Main model: the fast 3.5 super VL model, for analysis AND conversational use.
  analysis: process.env.NVIDIA_MODEL_ANALYSIS || 'nvidia/nemotron-3.5-super-vl-120b-a12b',
  chat: process.env.NVIDIA_MODEL_CHAT || 'nvidia/nemotron-3.5-super-vl-120b-a12b',
  // Background/utility work (session compaction, memory extraction).
  light: process.env.NVIDIA_MODEL_LIGHT || 'nvidia/nemotron-3-super-120b-a12b',
  // Everything falls back to the reliable 3 super model.
  fallback: process.env.NVIDIA_MODEL_FALLBACK || process.env.NVIDIA_MODEL || 'nvidia/nemotron-3-super-120b-a12b',
};

// NOTE: reasoning models spend `max_tokens` on their trace before emitting any
// content, so thinking profiles MUST carry a large max_tokens (and reasoning
// budget) or the reply comes back empty.
const PROFILES = {
  analysis: {
    model: MODELS.analysis,
    temperature: 0.2,
    topP: 1,
    maxTokens: 4000,
    thinking: true,
    reasoningBudget: 2000,
    timeoutMs: 60000,
  },
  coach: {
    model: MODELS.chat,
    fallbackModel: MODELS.light,
    temperature: 0.6,
    topP: 1,
    maxTokens: 1200,
    thinking: false,
    timeoutMs: 90000,
    firstTokenTimeoutMs: 15000,
  },
  general: {
    model: MODELS.chat,
    fallbackModel: MODELS.light,
    temperature: 0.6,
    topP: 1,
    maxTokens: 1400,
    thinking: false,
    timeoutMs: 90000,
    firstTokenTimeoutMs: 15000,
  },
  assistant: {
    model: MODELS.chat,
    fallbackModel: MODELS.light,
    temperature: 0.7,
    topP: 1,
    maxTokens: 1200,
    thinking: false,
    timeoutMs: 90000,
    firstTokenTimeoutMs: 15000,
  },
  // Vera: the app-wide assistant. Slightly warmer and roomier for coaching. If
  // the big model is slow to start (queued/overloaded) it falls back to the
  // faster super model so the learner is not left waiting.
  vera: {
    model: MODELS.chat,
    fallbackModel: MODELS.light,
    temperature: 0.65,
    topP: 1,
    maxTokens: 1600,
    thinking: false,
    timeoutMs: 90000,
    firstTokenTimeoutMs: 15000,
  },
  // Marker/extractor: reasoning model for rubric marking and memory extraction
  // (strict JSON, low temperature).
  marker: {
    model: MODELS.analysis,
    temperature: 0.2,
    topP: 1,
    maxTokens: 3000,
    thinking: true,
    reasoningBudget: 1500,
    timeoutMs: 60000,
  },
  extractor: {
    model: MODELS.light,
    temperature: 0.2,
    topP: 1,
    maxTokens: 800,
    thinking: false,
    timeoutMs: 30000,
  },
  // Decides whether Vera should search the web before replying (cheap, fast).
  planner: {
    model: MODELS.light,
    temperature: 0,
    topP: 1,
    maxTokens: 200,
    thinking: false,
    timeoutMs: 20000,
  },
  // Folds an ageing conversation into a running summary (background, cheap).
  compactor: {
    model: MODELS.light,
    temperature: 0.3,
    topP: 1,
    maxTokens: 900,
    thinking: false,
    timeoutMs: 45000,
  },
};

function resolveProfile(name) {
  const profile = PROFILES[name];
  if (!profile) {
    const error = new Error(`Unknown AI profile: ${name}`);
    error.status = 500;
    throw error;
  }
  return { ...profile, fallbackModel: profile.fallbackModel || MODELS.fallback };
}

module.exports = { MODELS, PROFILES, resolveProfile };
