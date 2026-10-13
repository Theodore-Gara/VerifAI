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
  veraSystem,
  markerSystem,
  extractorSystem,
  MEMORY_KINDS,
} = require('./llm/prompts');

function emptyReplyError() {
  return llmError(502, 'The AI service returned an empty response.');
}

// Pulls a JSON object out of model text, tolerating stray fences or prose.
function parseJsonObject(text) {
  let value = String(text || '').trim();
  const fence = value.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fence) value = fence[1].trim();
  const start = value.indexOf('{');
  const end = value.lastIndexOf('}');
  if (start >= 0 && end > start) value = value.slice(start, end + 1);
  try {
    const parsed = JSON.parse(value);
    return parsed && typeof parsed === 'object' ? parsed : null;
  } catch {
    return null;
  }
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
// `webResults` (from Tavily) are supplied to the model as live evidence.
async function analyzeContent({ kind, content, webResults, fetchImpl }) {
  const evidence = webResults && webResults.length
    ? `\n\nLive web search results (use as evidence, cite by title):\n${webResults
        .map((r, i) => `${i + 1}. ${r.title} — ${r.url}\n   ${r.content}`)
        .join('\n')}`
    : '\n\nNo live web results were available; assess from the material alone.';
  const result = await chatWithFallback(
    {
      ...resolveProfile('analysis'),
      messages: [
        { role: 'system', content: analysisSystem(kind) },
        { role: 'user', content: `Kind: ${kind}\n\nAnalyse the following and return the JSON report:\n\n${content}${evidence}` },
      ],
    },
    fetchImpl,
  );
  if (!result.content) throw emptyReplyError();
  return result.content;
}

// --- Vera: personalised assistant with memory --------------------------------
async function getVeraReply({ userName, contextText, memories, contextName, appKnowledge, attemptAnswers, webResults, messages, fetchImpl }) {
  const { content } = await chatWithFallback(
    {
      ...resolveProfile('vera'),
      messages: [
        { role: 'system', content: veraSystem({ userName, contextText, memories, contextName, appKnowledge, attemptAnswers, webResults }) },
        ...messages,
      ],
    },
    fetchImpl,
  );
  if (!content) throw emptyReplyError();
  return content;
}

async function* streamVeraReply({ userName, contextText, memories, contextName, appKnowledge, attemptAnswers, webResults, messages, fetchImpl }) {
  yield* streamWithFallback(
    {
      ...resolveProfile('vera'),
      messages: [
        { role: 'system', content: veraSystem({ userName, contextText, memories, contextName, appKnowledge, attemptAnswers, webResults }) },
        ...messages,
      ],
    },
    fetchImpl,
  );
}

// Extracts durable memories from one exchange. Best-effort: any failure yields
// an empty list so chat is never blocked by extraction.
async function extractMemories({ userName, contextText, userMessage, assistantReply, fetchImpl }) {
  try {
    const { content } = await chatWithFallback(
      {
        ...resolveProfile('extractor'),
        messages: [
          { role: 'system', content: extractorSystem() },
          {
            role: 'user',
            content: `Learner: ${userName || 'Unknown'}\n\nProfile:\n${contextText || '(none)'}\n\nExchange:\nLearner: ${userMessage}\nVera: ${assistantReply}`,
          },
        ],
      },
      fetchImpl,
    );
    const parsed = parseJsonObject(content);
    if (!parsed || !Array.isArray(parsed.memories)) return [];
    return parsed.memories
      .filter((m) => m && MEMORY_KINDS.includes(m.kind) && typeof m.content === 'string' && m.content.trim())
      .map((m) => ({ kind: m.kind, content: m.content.trim().slice(0, 300) }))
      .slice(0, 3);
  } catch {
    return [];
  }
}

// --- AI rubric marking -------------------------------------------------------
async function markRubric({ question, response, fetchImpl }) {
  const { content } = await chatWithFallback(
    {
      ...resolveProfile('marker'),
      messages: [
        { role: 'system', content: markerSystem() },
        {
          role: 'user',
          content: [
            `Question: ${question.prompt}`,
            `Total marks: ${question.marks}`,
            `Rubric (JSON): ${JSON.stringify(question.rubric || [])}`,
            `Model answer: ${question.model_answer || '(none provided)'}`,
            'Candidate response:',
            String(response == null ? '' : response),
          ].join('\n'),
        },
      ],
    },
    fetchImpl,
  );
  const parsed = parseJsonObject(content);
  if (!parsed || !Array.isArray(parsed.criteria)) {
    throw llmError(502, 'The AI marker returned an unreadable response.');
  }
  return parsed;
}

module.exports = {
  getAssistantReply,
  streamAssistantReply,
  getGeneralReply,
  streamGeneralReply,
  getCoachReply,
  streamCoachReply,
  analyzeContent,
  getVeraReply,
  streamVeraReply,
  extractMemories,
  markRubric,
};
