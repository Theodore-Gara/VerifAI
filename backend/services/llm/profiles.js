// Per-use-case model routing. Locked from the live model evaluation
// (see the eval findings): the strong reasoning model serves both analysis and
// the conversational surfaces, having matched the smaller model on latency while
// clearly winning on quality. Every choice is env-overridable and falls back to
// a proven model on failure.
const MODELS = {
  analysis: process.env.NVIDIA_MODEL_ANALYSIS || 'nvidia/nemotron-3-super-120b-a12b',
  chat: process.env.NVIDIA_MODEL_CHAT || 'nvidia/nemotron-3-super-120b-a12b',
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
    temperature: 0.6,
    topP: 1,
    maxTokens: 1200,
    thinking: false,
    timeoutMs: 30000,
  },
  general: {
    model: MODELS.chat,
    temperature: 0.6,
    topP: 1,
    maxTokens: 1400,
    thinking: false,
    timeoutMs: 30000,
  },
  assistant: {
    model: MODELS.chat,
    temperature: 0.7,
    topP: 1,
    maxTokens: 1200,
    thinking: false,
    timeoutMs: 30000,
  },
  // Vera: the app-wide assistant. Slightly warmer and roomier for coaching.
  vera: {
    model: MODELS.chat,
    temperature: 0.65,
    topP: 1,
    maxTokens: 1600,
    thinking: false,
    timeoutMs: 40000,
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
    model: MODELS.chat,
    temperature: 0.2,
    topP: 1,
    maxTokens: 800,
    thinking: false,
    timeoutMs: 30000,
  },
};

function resolveProfile(name) {
  const profile = PROFILES[name];
  if (!profile) {
    const error = new Error(`Unknown AI profile: ${name}`);
    error.status = 500;
    throw error;
  }
  return { ...profile, fallbackModel: MODELS.fallback };
}

module.exports = { MODELS, PROFILES, resolveProfile };
