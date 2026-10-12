// Domain-level AI functions. Each maps a use case to a model profile and a
// system prompt, then delegates transport to services/llm/client.js.
const {
  chatWithFallback,
  streamWithFallback,
  llmError,
} = require('./llm/client');
const { resolveProfile } = require('./llm/profiles');
const {
  assistantSystem,
  generalSystem,
  coachSystem,
  analysisSystem,
} = require('./llm/prompts');

function emptyReplyError() {
  return llmError(502, 'The AI service returned an empty response.');
}

// --- Task-scoped Learning Assistant (existing behaviour) --------------------
async function getAssistantReply({ task, messages, fetchImpl }) {
  const { content } = await chatWithFallback(
    {
      ...resolveProfile('assistant'),
      messages: [{ role: 'system', content: assistantSystem(task) }, ...messages],
    },
    fetchImpl,
  );
  if (!content) throw emptyReplyError();
  return content;
}

async function* streamAssistantReply({ task, messages, fetchImpl }) {
  yield* streamWithFallback(
    {
      ...resolveProfile('assistant'),
      messages: [{ role: 'system', content: assistantSystem(task) }, ...messages],
    },
    fetchImpl,
  );
}

// --- General (task-less) assistant -------------------------------------------
async function getGeneralReply({ trackName, messages, fetchImpl }) {
  const { content } = await chatWithFallback(
    {
      ...resolveProfile('general'),
      messages: [{ role: 'system', content: generalSystem(trackName) }, ...messages],
    },
    fetchImpl,
  );
  if (!content) throw emptyReplyError();
  return content;
}

async function* streamGeneralReply({ trackName, messages, fetchImpl }) {
  yield* streamWithFallback(
    {
      ...resolveProfile('general'),
      messages: [{ role: 'system', content: generalSystem(trackName) }, ...messages],
    },
    fetchImpl,
  );
}

// --- AI Lab coach ------------------------------------------------------------
async function getCoachReply({ lesson, messages, fetchImpl }) {
  const { content } = await chatWithFallback(
    {
      ...resolveProfile('coach'),
      messages: [{ role: 'system', content: coachSystem(lesson) }, ...messages],
    },
    fetchImpl,
  );
  if (!content) throw emptyReplyError();
  return content;
}

async function* streamCoachReply({ lesson, messages, fetchImpl }) {
  yield* streamWithFallback(
    {
      ...resolveProfile('coach'),
      messages: [{ role: 'system', content: coachSystem(lesson) }, ...messages],
    },
    fetchImpl,
  );
}

// --- Verification Studio analysis -------------------------------------------
// Returns raw model text; the controller validates it into the report schema.
async function analyzeContent({ kind, content, fetchImpl }) {
  const result = await chatWithFallback(
    {
      ...resolveProfile('analysis'),
      messages: [
        { role: 'system', content: analysisSystem(kind) },
        { role: 'user', content: `Kind: ${kind}\n\nAnalyse the following and return the JSON report:\n\n${content}` },
      ],
    },
    fetchImpl,
  );
  if (!result.content) throw emptyReplyError();
  return result.content;
}

module.exports = {
  getAssistantReply,
  streamAssistantReply,
  getGeneralReply,
  streamGeneralReply,
  getCoachReply,
  streamCoachReply,
  analyzeContent,
};
