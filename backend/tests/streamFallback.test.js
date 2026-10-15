const assert = require('node:assert/strict');
const { test } = require('node:test');

process.env.NVIDIA_API_KEY = 'test-key';
const { streamWithFallback } = require('../services/llm/client');

// A fetch-like response whose body is the given SSE lines.
function sseResponse(lines) {
  const encoder = new TextEncoder();
  const body = new ReadableStream({
    start(controller) {
      for (const line of lines) controller.enqueue(encoder.encode(line));
      controller.close();
    },
  });
  return { ok: true, status: 200, body };
}

const GOOD_LINES = [
  'data: {"choices":[{"delta":{"content":"Hello"}}]}\n\n',
  'data: {"choices":[{"delta":{"content":" world"}}]}\n\n',
  'data: [DONE]\n\n',
];
// A fresh response per call (a ReadableStream can only be consumed once).
const good = () => sseResponse(GOOD_LINES);

async function collect(stream) {
  let out = '';
  for await (const chunk of stream) {
    if (chunk.delta) out += chunk.delta;
  }
  return out;
}

// fetchImpl is the client's second argument, not part of the request params.
function requestParams() {
  return {
    model: 'primary',
    fallbackModel: 'fallback',
    timeoutMs: 5000,
    idleTimeoutMs: 5000,
    messages: [{ role: 'user', content: 'hi' }],
  };
}

test('streams content from the primary model', async () => {
  const models = [];
  const text = await collect(
    streamWithFallback(requestParams(), async (url, options) => {
      models.push(JSON.parse(options.body).model);
      return good();
    }),
  );
  assert.equal(text, 'Hello world');
  assert.deepEqual(models, ['primary']);
});

test('an SSE error frame with no content retries on the fallback model', async () => {
  const models = [];
  const text = await collect(
    streamWithFallback(requestParams(), async (url, options) => {
      const model = JSON.parse(options.body).model;
      models.push(model);
      return model === 'primary'
        ? sseResponse(['data: {"error":{"message":"Service temporarily overloaded","code":503}}\n\n', 'data: [DONE]\n\n'])
        : good();
    }),
  );
  assert.equal(text, 'Hello world');
  assert.deepEqual(models, ['primary', 'fallback']);
});

test('an empty primary stream retries on the fallback model', async () => {
  const models = [];
  const text = await collect(
    streamWithFallback(requestParams(), async (url, options) => {
      const model = JSON.parse(options.body).model;
      models.push(model);
      return model === 'primary' ? sseResponse(['data: [DONE]\n\n']) : good();
    }),
  );
  assert.equal(text, 'Hello world');
  assert.deepEqual(models, ['primary', 'fallback']);
});

test('a mid-stream failure after content is surfaced, not restarted', async () => {
  let calls = 0;
  await assert.rejects(
    collect(
      streamWithFallback(requestParams(), async () => {
        calls += 1;
        return sseResponse([
          'data: {"choices":[{"delta":{"content":"Hel"}}]}\n\n',
          'data: {"error":{"message":"boom","code":500}}\n\n',
        ]);
      }),
    ),
    /boom/,
  );
  assert.equal(calls, 1, 'does not retry after content was streamed');
});
