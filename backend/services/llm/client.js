// Low-level NVIDIA-hosted chat transport. Knows nothing about prompts or use
// cases: callers pass a resolved profile (see profiles.js) and messages.
//
// Key behaviours discovered while evaluating the models:
//  - `enable_thinking:true` makes a reasoning model spend the token budget on
//    its trace first, so it must be paired with a generous `max_tokens` (and a
//    `reasoning_budget` where supported) or `content` comes back empty.
//  - Only some models accept `reasoning_budget`; profiles below only set it for
//    the analysis model.
//  - Upstream can be slow or flaky, so callers get a fallback model.
const CHAT_URL =
  process.env.NVIDIA_BASE_URL || 'https://integrate.api.nvidia.com/v1/chat/completions';

const RETRYABLE_STATUS = new Set([429, 500, 502, 503, 504]);

function llmError(status, message) {
  const error = new Error(message);
  error.status = status;
  return error;
}

function requireApiKey() {
  const key = process.env.NVIDIA_API_KEY;
  if (!key) throw llmError(503, 'AI service is not configured.');
  return key;
}

function buildBody({ model, messages, temperature, topP, maxTokens, thinking, reasoningBudget, stream }) {
  const body = {
    model,
    messages,
    temperature,
    top_p: topP,
    max_tokens: maxTokens,
    stream: !!stream,
  };
  if (thinking !== undefined) body.chat_template_kwargs = { enable_thinking: !!thinking };
  if (thinking && reasoningBudget) body.reasoning_budget = reasoningBudget;
  return body;
}

function mapTransportError(cause) {
  if (cause && (cause.name === 'TimeoutError' || cause.name === 'AbortError')) {
    return llmError(504, 'The AI service timed out or is unavailable.');
  }
  return llmError(502, 'The AI service is temporarily unavailable.');
}

function mapHttpError(status) {
  return llmError(status === 429 ? 503 : 502, 'The AI service is temporarily unavailable.');
}

// Single buffered completion. Returns { content, reasoning, usage, finish }.
async function chatCompletion(params, fetchImpl = fetch) {
  const key = requireApiKey();
  let response;
  try {
    response = await fetchImpl(CHAT_URL, {
      method: 'POST',
      headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(buildBody({ ...params, stream: false })),
      signal: AbortSignal.timeout(params.timeoutMs || 30000),
    });
  } catch (cause) {
    throw mapTransportError(cause);
  }
  if (!response.ok) throw mapHttpError(response.status);

  const result = await response.json();
  if (result && result.error) {
    const code = Number(result.error.code) || 503;
    throw llmError(RETRYABLE_STATUS.has(code) ? code : 502, result.error.message || 'The AI service returned an error.');
  }
  const message = result.choices?.[0]?.message || {};
  return {
    content: typeof message.content === 'string' ? message.content.trim() : '',
    reasoning: typeof message.reasoning_content === 'string' ? message.reasoning_content : '',
    usage: result.usage || {},
    finish: result.choices?.[0]?.finish_reason,
  };
}

// Buffered completion with a single retry on the fallback model if the primary
// fails for a retryable reason. Throws the original error if no fallback helps.
async function chatWithFallback(params, fetchImpl = fetch) {
  const { fallbackModel, ...primary } = params;
  try {
    return await chatCompletion(primary, fetchImpl);
  } catch (error) {
    if (!fallbackModel || fallbackModel === primary.model || !RETRYABLE_STATUS.has(error.status)) {
      throw error;
    }
    return chatCompletion({ ...primary, model: fallbackModel }, fetchImpl);
  }
}

// Streams server-sent chunks. Yields { delta } for each content token and a
// final { usage } when the provider reports it. Unlike the buffered call this
// must NOT cap the whole response - a reply can stream for over a minute. The
// timeout applies to the initial response only; after that a per-chunk idle
// timeout catches a genuinely stalled stream. `firstTokenTimeoutMs` aborts a
// model that is slow to START (queued/overloaded) so the caller can fall back.
async function* streamChatCompletion(params, fetchImpl = fetch) {
  const key = requireApiKey();
  const controller = new AbortController();
  const headerTimeoutMs = params.timeoutMs || 30000;
  const idleTimeoutMs = params.idleTimeoutMs || 60000;
  const firstTokenMs = Number(params.firstTokenTimeoutMs) || 0;
  // When a first-token budget is set it also caps the wait for the response
  // headers, so a model that is slow to START is abandoned quickly.
  const headerTimer = setTimeout(
    () => controller.abort(),
    firstTokenMs > 0 ? firstTokenMs : headerTimeoutMs,
  );
  let response;
  try {
    response = await fetchImpl(CHAT_URL, {
      method: 'POST',
      headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(buildBody({ ...params, stream: true })),
      signal: controller.signal,
    });
  } catch (cause) {
    throw mapTransportError(cause);
  } finally {
    clearTimeout(headerTimer);
  }
  if (!response.ok) throw mapHttpError(response.status);

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';
  let firstTokenTimer = null;
  let firstTokenExpired = false;
  const clearFirstTokenTimer = () => {
    if (firstTokenTimer) { clearTimeout(firstTokenTimer); firstTokenTimer = null; }
  };
  if (firstTokenMs > 0) {
    firstTokenTimer = setTimeout(() => {
      firstTokenExpired = true;
      controller.abort();
    }, firstTokenMs);
  }
  try {
    for (;;) {
      let result;
      let idleTimer;
      try {
        result = await Promise.race([
          reader.read(),
          new Promise((_, reject) => {
            idleTimer = setTimeout(() => {
              controller.abort();
              reject(llmError(504, 'The AI service stalled.'));
            }, idleTimeoutMs);
          }),
        ]);
      } finally {
        clearTimeout(idleTimer);
      }
      const { done, value } = result;
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop();
      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        const data = trimmed.slice(5).trim();
        if (data === '[DONE]') continue;
        let parsed;
        try {
          parsed = JSON.parse(data);
        } catch {
          continue;
        }
        // The upstream can return HTTP 200 and put a failure in the stream body
        // (e.g. {"error":{"message":"Service temporarily overloaded","code":503}}).
        if (parsed.error) {
          const code = Number(parsed.error.code) || 503;
          throw llmError(RETRYABLE_STATUS.has(code) ? code : 502, parsed.error.message || 'The AI service returned an error.');
        }
        const delta = parsed.choices?.[0]?.delta?.content;
        if (delta) {
          clearFirstTokenTimer();
          yield { delta };
        }
        if (parsed.usage) yield { usage: parsed.usage };
      }
    }
  } catch (err) {
    if (firstTokenExpired) throw llmError(504, 'The AI service was too slow to start.');
    throw err;
  } finally {
    clearFirstTokenTimer();
  }
}

// Streaming fallback. A mid-stream failure after content cannot be restarted
// (it would duplicate tokens), so it is surfaced. But if the primary produced
// NO content - a stalled or overloaded upstream that returned an error frame or
// an empty stream - we retry once on the fallback model instead of leaving the
// caller with a silent empty reply.
async function* streamWithFallback(params, fetchImpl = fetch) {
  const { fallbackModel, ...primary } = params;
  const canFallback = fallbackModel && fallbackModel !== primary.model;

  let yielded = false;
  let error = null;
  try {
    for await (const chunk of streamChatCompletion(primary, fetchImpl)) {
      if (chunk.delta) yielded = true;
      yield chunk;
    }
  } catch (err) {
    error = err;
  }

  if (yielded) {
    if (error) throw error; // partial content already sent; surface the failure
    return;
  }

  // Nothing was streamed. Retry on the fallback when the failure is retryable.
  if (!canFallback) {
    if (error) throw error;
    throw llmError(502, 'The AI service returned an empty response.');
  }
  if (error && !RETRYABLE_STATUS.has(error.status)) throw error;

  yield* streamChatCompletion({ ...primary, model: fallbackModel }, fetchImpl);
}

module.exports = {
  CHAT_URL,
  chatCompletion,
  chatWithFallback,
  streamChatCompletion,
  streamWithFallback,
  llmError,
};
