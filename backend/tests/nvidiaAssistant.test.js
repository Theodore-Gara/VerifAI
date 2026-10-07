const assert = require('node:assert/strict');
const { test } = require('node:test');
const { getAssistantReply } = require('../services/nvidiaAssistant');

test('NVIDIA assistant sends bounded, task-scoped chat and returns its reply', async () => {
  const previousKey = process.env.NVIDIA_API_KEY;
  process.env.NVIDIA_API_KEY = 'test-key';
  let request;

  try {
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
        request = { url, options, body: JSON.parse(options.body) };
        return {
          ok: true,
          json: async () => ({ choices: [{ message: { content: 'Check what changed in the market.' } }] }),
        };
      },
    });

    assert.equal(reply, 'Check what changed in the market.');
    assert.equal(request.url, 'https://integrate.api.nvidia.com/v1/chat/completions');
    assert.equal(request.options.headers.Authorization, 'Bearer test-key');
    assert.equal(request.body.model, 'nvidia/nemotron-3.5-lightning-30b-a3b');
    assert.equal(request.body.max_tokens, 800);
    assert.equal(request.body.chat_template_kwargs.enable_thinking, false);
    assert.match(request.body.messages[0].content, /Do not reveal the expected answer/);
    assert.doesNotMatch(request.body.messages[0].content, /must not be included/);
  } finally {
    if (previousKey === undefined) delete process.env.NVIDIA_API_KEY;
    else process.env.NVIDIA_API_KEY = previousKey;
  }
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
    if (previousKey !== undefined) process.env.NVIDIA_API_KEY = previousKey;
  }
});
