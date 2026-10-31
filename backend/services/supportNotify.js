// Optional "new support message" email to the team. Entirely best effort: the
// ticket is already stored when this runs, so a missing provider, a network
// error or a provider outage must never change the response to the sender.
//
// The email carries the ticket reference and category only, never the sender's
// name, address, subject or message. Staff open the admin console for those, so
// the message body never leaves our database for a third-party mail provider.
//
// Provider: Resend's HTTP API (no extra dependency). Everything provider
// specific is in this file, so swapping it is a one-file change.
//   SUPPORT_NOTIFY_EMAIL  recipient (feature is off when unset)
//   RESEND_API_KEY        provider key (feature is off when unset)
//   SUPPORT_NOTIFY_FROM   sender address, e.g. "VerifAI <support@your-domain>"
function isConfigured(env = process.env) {
  return Boolean(env.SUPPORT_NOTIFY_EMAIL && env.RESEND_API_KEY && env.SUPPORT_NOTIFY_FROM);
}

async function notifySupportTeam({ ref, category }, { env = process.env, fetchImpl = fetch } = {}) {
  if (!isConfigured(env)) return { sent: false, reason: 'not_configured' };
  try {
    const response = await fetchImpl('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: env.SUPPORT_NOTIFY_FROM,
        to: [env.SUPPORT_NOTIFY_EMAIL],
        subject: `New VerifAI support message ${ref} (${category})`,
        text: `A new support message was received.\n\nReference: ${ref}\nCategory: ${category}\n\nOpen the admin dashboard to read and reply.`,
      }),
      signal: AbortSignal.timeout(5000),
    });
    if (!response.ok) return { sent: false, reason: `provider_${response.status}` };
    return { sent: true };
  } catch (err) {
    // Log the failure kind only; never the message.
    console.error(`Support notification failed: ${err.name}`);
    return { sent: false, reason: 'error' };
  }
}

module.exports = { notifySupportTeam, isConfigured };
