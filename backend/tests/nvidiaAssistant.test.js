const assert = require('node:assert/strict');
const { test } = require('node:test');

// Lock routing to the documented defaults regardless of the developer's shell.
delete process.env.NVIDIA_MODEL;
delete process.env.NVIDIA_MODEL_ANALYSIS;
delete process.env.NVIDIA_MODEL_CHAT;
delete process.env.NVIDIA_MODEL_FALLBACK;

const {
  getAssistantReply,
  analyzeContent,
} = require('../services/nvidiaAssistant');

test('task assistant routes to the chat model with the task guardrail', async () => {
  process.env.NVIDIA_API_KEY = 'test-key';
  let request;

  const reply = await getAssistantReply({
    task: {
      trackName: 'Finance',
      feature: 'verification',
      title: 'Review a forecast',
      scenario: 'The forecast ignores a new competitor.',
      expectedAnswer: 'must not be included',
    },
    messages: [{ role: 'user', content: 'Can you give me a hint?' }],
    fetchImpl: async (url, options) => {
      request = { url, body: JSON.parse(options.body) };
      return { ok: true, json: async () => ({ choices: [{ message: { content: 'Check what changed in the market.' } }] }) };
    },
  });

  assert.equal(reply, 'Check what changed in the market.');
  assert.equal(request.url, 'https://integrate.api.nvidia.com/v1/chat/completions');
  assert.equal(request.body.model, 'nvidia/nemotron-3-super-120b-a12b');
  assert.equal(request.body.max_tokens, 1200);
  assert.equal(request.body.chat_template_kwargs.enable_thinking, false);
  assert.match(request.body.messages[0].content, /Do not reveal the expected answer/);
  assert.doesNotMatch(request.body.messages[0].content, /must not be included/);
});

test('analysis routes to the reasoning model with thinking enabled', async () => {
  process.env.NVIDIA_API_KEY = 'test-key';
  let request;

  await analyzeContent({
    kind: 'document',
    content: 'A claim with no citation.',
    fetchImpl: async (url, options) => {
      request = { body: JSON.parse(options.body) };
      return { ok: true, json: async () => ({ choices: [{ message: { content: '{"ok":true}' } }] }) };
    },
  });

  assert.equal(request.body.model, 'nvidia/nemotron-3-super-120b-a12b');
  assert.equal(request.body.chat_template_kwargs.enable_thinking, true);
  assert.equal(request.body.reasoning_budget, 2000);
  assert.ok(request.body.max_tokens >= 2000);
});

test('a retryable upstream failure falls back to the proven model', async () => {
  process.env.NVIDIA_API_KEY = 'test-key';
  const models = [];

  const reply = await getAssistantReply({
    task: { trackName: 'Finance', feature: 'verification', title: 'T', scenario: 'S' },
    messages: [{ role: 'user', content: 'hint?' }],
    fetchImpl: async (url, options) => {
      const body = JSON.parse(options.body);
      models.push(body.model);
      if (body.model === 'nvidia/nemotron-3-super-120b-a12b') {
        return { ok: false, status: 500, text: async () => 'boom' };
      }
      return { ok: true, json: async () => ({ choices: [{ message: { content: 'Fallback reply.' } }] }) };
    },
  });

  assert.equal(reply, 'Fallback reply.');
  assert.deepEqual(models, ['nvidia/nemotron-3-super-120b-a12b', 'openai/gpt-oss-20b']);
});

test('NVIDIA assistant rejects use without a server API key', async () => {
  const previousKey = process.env.NVIDIA_API_KEY;
  delete process.env.NVIDIA_API_KEY;
  try {
    await assert.rejects(
      getAssistantReply({ task: {}, messages: [] }),
      (error) => error.status === 503,
    );
  } finally {
    if (previousKey === undefined) delete process.env.NVIDIA_API_KEY;
    else process.env.NVIDIA_API_KEY = previousKey;
  }
});
