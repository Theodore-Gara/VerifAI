// Read side of the content-driven support surface: published help articles,
// FAQs, industry guides, tour manifests and the About page.
//
// Each collection is cached as a whole (they are small) under its own key in the
// shared contentCache, then filtered in memory per request. An admin edit calls
// invalidateSupportCache(), so a change shows on the next request without a
// deploy. With more than one API instance the other instances catch up when
// their entry expires (CONTENT_CACHE_MS, default 60s).
const pool = require('../db/pool');
const { contentCache } = require('../utils/ttlCache');

const KEYS = {
  help: 'support:help',
  faqs: 'support:faqs',
  guides: 'support:guides',
  tours: 'support:tours',
  about: 'support:about',
};

function invalidateSupportCache() {
  for (const key of Object.values(KEYS)) contentCache.delete(key);
}

// The newest updated_at in a collection, as an ISO-8601 string without
// milliseconds. It changes whenever any row in the collection is created or
// edited, so the app can compare it to detect updates. (Date-only would miss a
// second edit on the same day.)
function versionOf(rows) {
  let max = 0;
  for (const row of rows) {
    const t = new Date(row.updated_at).getTime();
    if (Number.isFinite(t) && t > max) max = t;
  }
  return new Date(max).toISOString().replace(/\.\d{3}Z$/, 'Z');
}

function newestVersion(...versions) {
  return versions.filter(Boolean).sort().pop() || versionOf([]);
}

function iso(value) {
  return new Date(value).toISOString();
}

async function loadHelp() {
  return contentCache.wrap(KEYS.help, async () => {
    const result = await pool.query(
      `SELECT id, slug, title, summary, body_md, category, audience, sort_order, updated_at
         FROM help_articles
        WHERE published = TRUE
        ORDER BY sort_order, id`,
    );
    const articles = result.rows.map((r) => ({ ...r, updated_at: iso(r.updated_at) }));
    return { articles, version: versionOf(articles) };
  });
}

async function loadFaqs() {
  return contentCache.wrap(KEYS.faqs, async () => {
    const result = await pool.query(
      `SELECT id, slug, question, answer_md, topic, sort_order, updated_at
         FROM faqs
        WHERE published = TRUE
        ORDER BY sort_order, id`,
    );
    const faqs = result.rows.map((r) => ({ ...r, updated_at: iso(r.updated_at) }));
    return { faqs, version: versionOf(faqs) };
  });
}

async function loadGuides() {
  return contentCache.wrap(KEYS.guides, async () => {
    const result = await pool.query(
      `SELECT g.id, g.track_id, t.name AS track_name, g.slug, g.tagline, g.overview_md,
              g.outcomes, g.feature_tour, g.how_to, g.hero_image, g.body_image, g.updated_at
         FROM industry_guides g
         JOIN industry_tracks t ON t.id = g.track_id
        ORDER BY g.track_id`,
    );
    const guides = result.rows.map((r) => ({ ...r, updated_at: iso(r.updated_at) }));
    return { guides, version: versionOf(guides) };
  });
}

async function loadTours() {
  return contentCache.wrap(KEYS.tours, async () => {
    const result = await pool.query(
      `SELECT tour_key, track_id, title, steps, updated_at
         FROM support_tours
        ORDER BY track_id NULLS FIRST, tour_key`,
    );
    const tours = result.rows.map((r) => ({ ...r, updated_at: iso(r.updated_at) }));
    return { tours, version: versionOf(tours) };
  });
}

async function loadAbout() {
  return contentCache.wrap(KEYS.about, async () => {
    const result = await pool.query(
      `SELECT slug, title, data, updated_at FROM support_pages WHERE slug = 'about'`,
    );
    const row = result.rows[0] || null;
    return row ? { page: { ...row, updated_at: iso(row.updated_at) }, version: versionOf([row]) } : { page: null, version: versionOf([]) };
  });
}

// Steps always carry a `media` key (null when no recording is hosted) so the
// client never has to distinguish "missing" from "not yet recorded", and a
// `scope` so it can show global and industry steps under separate headings.
function normaliseSteps(steps, scope) {
  return (Array.isArray(steps) ? steps : []).map((step) => ({
    id: step.id,
    title: step.title,
    body_md: step.body_md,
    media: step.media && step.media.url ? step.media : null,
    scope,
  }));
}

module.exports = {
  KEYS,
  invalidateSupportCache,
  versionOf,
  newestVersion,
  loadHelp,
  loadFaqs,
  loadGuides,
  loadTours,
  loadAbout,
  normaliseSteps,
};
