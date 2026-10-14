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
  markerSystem,
  extractorSystem,
  capstoneReportSystem,
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
// The caller assembles the full message list (system prompt + running summary +
// recent turns); these just run it through the Vera profile.
async function getVeraReply({ messages, fetchImpl }) {
  const { content } = await chatWithFallback(
    { ...resolveProfile('vera'), messages },
    fetchImpl,
  );
  if (!content) throw emptyReplyError();
  return content;
}

async function* streamVeraReply({ messages, fetchImpl }) {
  yield* streamWithFallback({ ...resolveProfile('vera'), messages }, fetchImpl);
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

// --- Post-capstone performance report ---------------------------------------
async function generateCapstoneReport({ assessment, summary, fetchImpl }) {
  const { content } = await chatWithFallback(
    {
      ...resolveProfile('marker'),
      messages: [
        { role: 'system', content: capstoneReportSystem() },
        { role: 'user', content: `Assessment: ${assessment.title}\nPass mark: ${assessment.pass_score}\nLearner result:\n${summary}` },
      ],
    },
    fetchImpl,
  );
  const parsed = parseJsonObject(content);
  if (!parsed) throw llmError(502, 'The coach returned an unreadable report.');
  return {
    headline: typeof parsed.headline === 'string' ? parsed.headline.slice(0, 200) : '',
    strengths: Array.isArray(parsed.strengths) ? parsed.strengths.filter((s) => typeof s === 'string').slice(0, 4) : [],
    focus: Array.isArray(parsed.focus) ? parsed.focus.filter((s) => typeof s === 'string').slice(0, 4) : [],
    report: typeof parsed.report === 'string' ? parsed.report.slice(0, 2000) : '',
  };
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
  generateCapstoneReport,
};
