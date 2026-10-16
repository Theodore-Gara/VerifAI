// Per-use-case model routing. Conversational surfaces run on the larger frontier
// model; analysis/marking and background utility work run on the smaller model.
// Every choice is env-overridable and falls back to a proven model on failure.
const MODELS = {
  analysis: process.env.NVIDIA_MODEL_ANALYSIS || 'nvidia/nemotron-3-super-120b-a12b',
  // Conversational surfaces (Vera, the Learning Assistant and the coach) use the
  // larger frontier model; it is slower per token but tighter and higher quality.
  chat: process.env.NVIDIA_MODEL_CHAT || 'nvidia/nemotron-3-ultra-550b-a55b',
  // Background/utility work (memory extraction, session compaction) stays on the
  // cheaper, faster model.
  light: process.env.NVIDIA_MODEL_LIGHT || 'nvidia/nemotron-3-super-120b-a12b',
  fallback: process.env.NVIDIA_MODEL_FALLBACK || process.env.NVIDIA_MODEL || 'openai/gpt-oss-20b',
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
