const { sendApiError: sendError } = require('../utils/apiError');
const crypto = require('crypto');
const pool = require('../db/pool');
const { sendJsonWithEtag } = require('../utils/httpCache');
const {
  loadHelp, loadFaqs, loadGuides, loadTours, loadAbout, normaliseSteps, newestVersion,
} = require('../services/supportContent');
const {
  CONTACT_CATEGORIES, CONTACT_LIMITS, EXPECTED_REPLY,
} = require('../services/supportLimits');
const { notifySupportTeam } = require('../services/supportNotify');
const { version: APP_VERSION } = require('../package.json');

const SLUG_RE = /^[a-z0-9][a-z0-9._-]{0,79}$/;


// ---------------------------------------------------------------------------
// Help articles
// ---------------------------------------------------------------------------
async function listHelp(req, res, next) {
  try {
    const { articles, version } = await loadHelp();
    const category = typeof req.query.category === 'string' ? req.query.category.trim().toLowerCase() : '';
    const filtered = category ? articles.filter((a) => a.category === category) : articles;
    const categories = [...new Set(articles.map((a) => a.category))];
    return sendJsonWithEtag(req, res, { articles: filtered, categories, version, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

async function getHelp(req, res, next) {
  try {
    const { articles, version } = await loadHelp();
    const article = articles.find((a) => a.slug === req.params.slug);
    if (!article) return sendError(req, res, 404, 'help_article_not_found', 'Help article not found.');
    const related = articles
      .filter((a) => a.category === article.category && a.slug !== article.slug)
      .map(({ slug, title, summary }) => ({ slug, title, summary }));
    return sendJsonWithEtag(req, res, { article, related, version, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// FAQs: ?topic= exact match, ?q= case-insensitive match on question and answer.
// ---------------------------------------------------------------------------
async function listFaqs(req, res, next) {
  try {
    const { faqs, version } = await loadFaqs();
    const topic = typeof req.query.topic === 'string' ? req.query.topic.trim().toLowerCase() : '';
    const q = typeof req.query.q === 'string' ? req.query.q.trim().slice(0, 100).toLowerCase() : '';

    let filtered = faqs;
    if (topic) filtered = filtered.filter((f) => f.topic === topic);
    if (q) {
      filtered = filtered.filter((f) => (
        f.question.toLowerCase().includes(q) || f.answer_md.toLowerCase().includes(q)
      ));
    }
    const topics = [...new Set(faqs.map((f) => f.topic))];
    return sendJsonWithEtag(req, res, { faqs: filtered, topics, version, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// Industry guides
// ---------------------------------------------------------------------------
function guideSummary(g) {
  return {
    slug: g.slug,
    track_id: g.track_id,
    track_name: g.track_name,
    tagline: g.tagline,
    hero_image: g.hero_image,
    updated_at: g.updated_at,
  };
}

async function listGuides(req, res, next) {
  try {
    const { guides, version } = await loadGuides();
    return sendJsonWithEtag(req, res, {
      guides: guides.map(guideSummary),
      version,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

async function getGuide(req, res, next) {
  try {
    const [{ guides, version: guidesVersion }, { faqs, version: faqsVersion }] = await Promise.all([
      loadGuides(), loadFaqs(),
    ]);
    const guide = guides.find((g) => g.slug === req.params.slug);
    if (!guide) return sendError(req, res, 404, 'industry_guide_not_found', 'Industry guide not found.');

    // The guide names its three related FAQs by slug; resolve them so the Learn
    // more screen needs one request. An unpublished FAQ is silently skipped.
    const wanted = Array.isArray(guide.how_to?.related_faqs) ? guide.how_to.related_faqs : [];
    const related_faqs = wanted
      .map((slug) => faqs.find((f) => f.slug === slug))
      .filter(Boolean)
      .map(({ slug, question, answer_md, topic }) => ({ slug, question, answer_md, topic }));

    return sendJsonWithEtag(req, res, {
      guide,
      related_faqs,
      version: newestVersion(guidesVersion, faqsVersion),
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// About: stored copy plus contact details and the app version from the
// environment. No contact address is invented: it is null until SUPPORT_EMAIL
// is set, and the app hides the line.
// ---------------------------------------------------------------------------
async function getAbout(req, res, next) {
  try {
    const { page, version } = await loadAbout();
    if (!page) return sendError(req, res, 404, 'about_not_found', 'About content is not available.');
    return sendJsonWithEtag(req, res, {
      about: {
        title: page.title,
        ...page.data,
        contact: {
          email: process.env.SUPPORT_EMAIL || null,
          form: true,
          expected_reply: EXPECTED_REPLY,
        },
        app_version: APP_VERSION,
      },
      version,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// Tour manifest. Without ?track= the global tour is returned. With ?track=
// (a guide slug such as "finance", or a track id) the response is the global
// steps followed by that industry's steps, keyed by the industry tour.
// autoplay is always false: the client decides.
// ---------------------------------------------------------------------------
async function getTour(req, res, next) {
  try {
    const [{ tours, version: toursVersion }, { guides }] = await Promise.all([loadTours(), loadGuides()]);
    const globalTour = tours.find((t) => t.track_id === null);
    if (!globalTour) return sendError(req, res, 404, 'tour_not_found', 'Tour not available.');

    const raw = typeof req.query.track === 'string' ? req.query.track.trim().toLowerCase() : '';
    let industryTour = null;
    if (raw) {
      const guide = guides.find((g) => g.slug === raw || String(g.track_id) === raw);
      if (!guide) return sendError(req, res, 404, 'track_not_found', 'Unknown industry.');
      industryTour = tours.find((t) => t.track_id === guide.track_id) || null;
    }

    const steps = [
      ...normaliseSteps(globalTour.steps, 'global'),
      ...(industryTour ? normaliseSteps(industryTour.steps, 'industry') : []),
    ];
    const used = industryTour ? [globalTour, industryTour] : [globalTour];

    return sendJsonWithEtag(req, res, {
      tour_key: industryTour ? industryTour.tour_key : globalTour.tour_key,
      global_tour_key: globalTour.tour_key,
      version: newestVersion(...used.map((t) => t.updated_at.replace(/\.\d{3}Z$/, 'Z'))) || toursVersion,
      autoplay: false,
      steps,
      request_id: req.requestId,
    });
  } catch (err) {
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// Contact intake
// ---------------------------------------------------------------------------
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const APP_VERSION_RE = /^[A-Za-z0-9._+ -]{1,40}$/;
// eslint-disable-next-line no-control-regex
const CONTROL_RE = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g;

function clean(value) {
  // NUL bytes make PostgreSQL reject the whole insert, so they are removed with
  // the other control characters (newlines and tabs are kept for the message).
  return String(value).replace(CONTROL_RE, '').trim();
}

class ContactError extends Error {
  constructor(code, message) {
    super(message);
    this.status = 400;
    this.code = code;
  }
}

function textField(value, field, min, max) {
  if (typeof value !== 'string') throw new ContactError(`invalid_${field}`, `${field} is required.`);
  const text = clean(value);
  if (text.length < min || text.length > max) {
    throw new ContactError(`invalid_${field}`, `${field} must be between ${min} and ${max} characters.`);
  }
  return text;
}

function validateContact(body) {
  const L = CONTACT_LIMITS;
  const name = textField(body.name, 'name', L.nameMin, L.nameMax);
  const email = textField(body.email, 'email', 3, L.emailMax).toLowerCase();
  if (!EMAIL_RE.test(email)) throw new ContactError('invalid_email', 'email is not a valid address.');
  const subject = textField(body.subject, 'subject', L.subjectMin, L.subjectMax);
  const message = textField(body.message, 'message', L.messageMin, L.messageMax);
  const category = typeof body.category === 'string' ? body.category.trim().toLowerCase() : '';
  if (!CONTACT_CATEGORIES.includes(category)) {
    throw new ContactError('invalid_category', `category must be one of: ${CONTACT_CATEGORIES.join(', ')}.`);
  }
  let appVersion = null;
  if (body.app_version !== undefined && body.app_version !== null && body.app_version !== '') {
    if (typeof body.app_version !== 'string' || !APP_VERSION_RE.test(body.app_version.trim())) {
      throw new ContactError('invalid_app_version', 'app_version is not valid.');
    }
    appVersion = body.app_version.trim();
  }
  return { name, email, subject, message, category, appVersion };
}

// Public reference: non-sequential, unambiguous characters, and the same shape
// whether the message was stored or discarded by the honeypot.
const REF_ALPHABET = 'ABCDEFGHJKMNPQRSTVWXYZ23456789';
function newPublicRef() {
  let out = 'VF-';
  for (let i = 0; i < 8; i += 1) out += REF_ALPHABET[crypto.randomInt(REF_ALPHABET.length)];
  return out;
}

// A hidden field real users never see or fill. Bots that fill every input get a
// normal-looking success and nothing is stored.
function isHoneypotHit(body) {
  return typeof body.website === 'string' && body.website.trim() !== '';
}

async function postContact(req, res, next) {
  try {
    const body = req.body && typeof req.body === 'object' ? req.body : {};

    if (isHoneypotHit(body)) {
      return res.status(201).json({
        ticket_id: newPublicRef(),
        expected_reply: EXPECTED_REPLY,
        request_id: req.requestId,
      });
    }

    const input = validateContact(body);

    let stored = null;
    for (let attempt = 0; attempt < 3 && !stored; attempt += 1) {
      const ref = newPublicRef();
      const result = await pool.query(
        `INSERT INTO support_messages
           (public_ref, user_id, name, email, subject, message, category, app_version, request_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         ON CONFLICT (public_ref) DO NOTHING
         RETURNING public_ref`,
        [ref, req.user ? req.user.id : null, input.name, input.email, input.subject,
          input.message, input.category, input.appVersion, req.requestId],
      );
      stored = result.rows[0] || null;
    }
    if (!stored) throw new Error('Could not allocate a ticket reference.');

    // Not awaited: the sender is never made to wait for, or told about, the
    // notification provider.
    notifySupportTeam({ ref: stored.public_ref, category: input.category }).catch(() => {});

    // The message is never echoed back and never logged.
    return res.status(201).json({
      ticket_id: stored.public_ref,
      expected_reply: EXPECTED_REPLY,
      request_id: req.requestId,
    });
  } catch (err) {
    if (err instanceof ContactError) return sendError(req, res, 400, err.code, err.message);
    return next(err);
  }
}

// ---------------------------------------------------------------------------
// Analytics events: one at a time, allowlisted, slugs/ids/counts only.
// ---------------------------------------------------------------------------
const SOURCES = ['drawer', 'dashboard', 'verification_error', 'login', 'onboarding', 'profile', 'help_home', 'other'];

const asEnum = (allowed) => (v) => (typeof v === 'string' && allowed.includes(v) ? v : undefined);
const asSlug = (v) => (typeof v === 'string' && SLUG_RE.test(v) ? v : undefined);
const asCount = (v) => (Number.isInteger(v) && v >= 0 && v <= 1000 ? v : undefined);

// target: 'slug' (required, validated) | 'none' (ignored and stored as null).
// meta: the only keys that may be stored, each with a validator that returns
// the cleaned value or undefined to drop it. Free text can never pass a slug,
// enum or small-integer check, so it cannot be stored.
const EVENT_SPECS = {
  help_open: { target: 'none', meta: { source: asEnum(SOURCES) } },
  article_view: { target: 'slug', meta: { source: asEnum(SOURCES) } },
  faq_expand: { target: 'slug', meta: { topic: asSlug } },
  // The search text is deliberately NOT stored; only whether it found anything.
  faq_search: { target: 'none', meta: { result_count: asCount } },
  tour_start: { target: 'slug', meta: { track: asSlug } },
  tour_complete: { target: 'slug', meta: { track: asSlug, steps_viewed: asCount } },
  tour_skip: { target: 'slug', meta: { track: asSlug, step_index: asCount } },
  contact_open: { target: 'none', meta: { source: asEnum(SOURCES) } },
  contact_submit: { target: 'none', meta: { category: asEnum(CONTACT_CATEGORIES) } },
};

function sanitiseMetadata(spec, raw) {
  const out = {};
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return out;
  for (const [key, validate] of Object.entries(spec.meta)) {
    const value = validate(raw[key]);
    if (value !== undefined) out[key] = value;
  }
  return out;
}

async function postEvent(req, res, next) {
  try {
    const body = req.body && typeof req.body === 'object' ? req.body : {};
    const spec = typeof body.event === 'string' && Object.hasOwn(EVENT_SPECS, body.event)
      ? EVENT_SPECS[body.event]
      : null;
    if (!spec) return sendError(req, res, 400, 'invalid_event', 'Unknown event.');

    let target = null;
    if (spec.target === 'slug') {
      target = asSlug(typeof body.target === 'string' ? body.target.trim().toLowerCase() : body.target);
      if (!target) return sendError(req, res, 400, 'invalid_target', 'target must be a slug.');
    }

    const metadata = sanitiseMetadata(spec, body.metadata);

    let recorded = true;
    try {
      await pool.query(
        `INSERT INTO support_events (user_id, event, target, metadata)
         VALUES ($1, $2, $3, $4::jsonb)`,
        [req.user ? req.user.id : null, body.event, target, JSON.stringify(metadata)],
      );
    } catch (err) {
      // Analytics must never affect the UI.
      recorded = false;
      console.error(`[${req.requestId}] support event not recorded: ${err.message}`);
    }
    return res.status(202).json({ recorded, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listHelp, getHelp, listFaqs, listGuides, getGuide, getAbout, getTour, postContact, postEvent,
  // Exported for tests and for the admin console.
  validateContact, sanitiseMetadata, EVENT_SPECS, isHoneypotHit, newPublicRef, sendError,
};
