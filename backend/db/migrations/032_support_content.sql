-- 032 — Support content: help articles, FAQs, industry guides, tour manifests
-- and static pages (About).
--
-- The support surface is content-driven: wording lives in the database so a fix
-- ships without an app build. Every table keeps `updated_at`, which the read
-- API turns into a `version` string so the app can detect changes.
--
-- Seeds (70-72, 78) upsert on the stable key (slug / tour_key) and only
-- overwrite a row whose updated_at is not newer than the seed's own content
-- date, so an admin edit is never silently reverted by a re-seed.

CREATE TABLE IF NOT EXISTS help_articles (
  id SERIAL PRIMARY KEY,
  slug VARCHAR(120) NOT NULL UNIQUE,
  title VARCHAR(200) NOT NULL,
  summary TEXT NOT NULL,
  body_md TEXT NOT NULL,
  category VARCHAR(40) NOT NULL,
  audience VARCHAR(20) NOT NULL DEFAULT 'all',
  sort_order INTEGER NOT NULL DEFAULT 0,
  published BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_help_articles_listing
  ON help_articles (category, sort_order, id) WHERE published;

CREATE TABLE IF NOT EXISTS faqs (
  id SERIAL PRIMARY KEY,
  slug VARCHAR(120) NOT NULL UNIQUE,
  question TEXT NOT NULL,
  answer_md TEXT NOT NULL,
  topic VARCHAR(40) NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  published BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_faqs_listing
  ON faqs (topic, sort_order, id) WHERE published;

CREATE TABLE IF NOT EXISTS industry_guides (
  id SERIAL PRIMARY KEY,
  track_id INTEGER NOT NULL UNIQUE REFERENCES industry_tracks(id) ON DELETE CASCADE,
  slug VARCHAR(80) NOT NULL UNIQUE,
  tagline TEXT NOT NULL,
  overview_md TEXT NOT NULL,
  -- { "who_for": "<md>", "by_the_end": ["...", ...] }
  outcomes JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- Ordered sections: [{ "key", "title", "body_md" | "items": [...] }]
  feature_tour JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- { "first_session": [...], "common_mistakes": [...], "related_faqs": [slug, ...] }
  how_to JSONB NOT NULL DEFAULT '{}'::jsonb,
  hero_image VARCHAR(120),
  body_image VARCHAR(120),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One manifest per industry plus one global manifest (track_id NULL).
CREATE TABLE IF NOT EXISTS support_tours (
  tour_key VARCHAR(60) PRIMARY KEY,
  track_id INTEGER UNIQUE REFERENCES industry_tracks(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  -- [{ "id", "title", "body_md", "media": null | { kind, url, captions_url, poster, duration_seconds } }]
  steps JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- At most one global tour.
CREATE UNIQUE INDEX IF NOT EXISTS uq_support_tours_global
  ON support_tours ((track_id IS NULL)) WHERE track_id IS NULL;

CREATE TABLE IF NOT EXISTS support_pages (
  slug VARCHAR(80) PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
