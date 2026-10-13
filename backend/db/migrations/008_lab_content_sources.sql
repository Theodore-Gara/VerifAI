-- VerifAI AI Lab — content source + licence tracking
--
-- Records where AI Lab material comes from and under what licence, so the app
-- can (a) show a "where our material comes from" library and (b) render an
-- attribution/credit line on lesson content. Lessons remain in lab_lessons;
-- this links them to sources.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$ BEGIN
  CREATE TYPE license_code AS ENUM ('CC0', 'PUBLIC_DOMAIN', 'CC_BY_4', 'CC_BY_SA_4');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE industry_code AS ENUM ('FINANCE', 'LEGAL', 'IT_SOFTWARE', 'BUSINESS_CONSULTING', 'CROSS_INDUSTRY');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- One row per upstream work (book, cheat sheet, statute, standard, ...).
CREATE TABLE IF NOT EXISTS content_sources (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title         TEXT          NOT NULL,
  author        TEXT          NOT NULL,
  publisher     TEXT,
  edition       TEXT,
  source_url    TEXT          NOT NULL,
  license       license_code  NOT NULL,
  license_url   TEXT          NOT NULL,
  industry      industry_code NOT NULL,
  checked_on    DATE          NOT NULL DEFAULT CURRENT_DATE,
  notes         TEXT
);

-- A source title identifies one work; makes db:seed re-runs idempotent.
CREATE UNIQUE INDEX IF NOT EXISTS idx_content_sources_title ON content_sources(title);

-- Extra licence/origin fields on the existing lab lesson table.
ALTER TABLE lab_lessons ADD COLUMN IF NOT EXISTS is_original BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE lab_lessons ADD COLUMN IF NOT EXISTS reviewed_by TEXT;
ALTER TABLE lab_lessons ADD COLUMN IF NOT EXISTS competency VARCHAR(40);

-- Recency of the last time a learner opened a lesson. Drives content rotation:
-- a seen lesson is never locked away, it is simply rotated behind unseen ones.
ALTER TABLE lab_lesson_progress ADD COLUMN IF NOT EXISTS last_viewed_at TIMESTAMPTZ;

-- A lesson can draw on several sources.
CREATE TABLE IF NOT EXISTS lesson_sources (
  lesson_id     INTEGER NOT NULL REFERENCES lab_lessons(id)      ON DELETE CASCADE,
  source_id     UUID    NOT NULL REFERENCES content_sources(id)  ON DELETE RESTRICT,
  use_type      TEXT    NOT NULL CHECK (use_type IN ('linked', 'inspired_by', 'adapted', 'copied')),
  changes_made  TEXT,
  PRIMARY KEY (lesson_id, source_id)
);

CREATE INDEX IF NOT EXISTS idx_content_sources_industry ON content_sources(industry, title);
CREATE INDEX IF NOT EXISTS idx_lesson_sources_source ON lesson_sources(source_id);
CREATE INDEX IF NOT EXISTS idx_lab_lesson_progress_viewed ON lab_lesson_progress(user_id, last_viewed_at);

-- Flags lessons that adapt/copy a BY-SA source: their text must be released
-- under CC BY-SA too.
CREATE OR REPLACE VIEW lessons_needing_share_alike AS
SELECT DISTINCT l.id, l.title
FROM lab_lessons l
JOIN lesson_sources ls ON ls.lesson_id = l.id
JOIN content_sources cs ON cs.id = ls.source_id
WHERE cs.license = 'CC_BY_SA_4'
  AND ls.use_type IN ('adapted', 'copied');

-- Ready-made credit line per lesson, for display in the app.
CREATE OR REPLACE VIEW lesson_attributions AS
SELECT
    ls.lesson_id,
    format(
        '"%s"%s by %s, %s%s',
        cs.title,
        COALESCE(' (' || cs.edition || ')', ''),
        cs.author,
        CASE cs.license
            WHEN 'CC_BY_4'       THEN 'licensed under CC BY 4.0'
            WHEN 'CC_BY_SA_4'    THEN 'licensed under CC BY-SA 4.0'
            WHEN 'CC0'           THEN 'dedicated to the public domain (CC0)'
            WHEN 'PUBLIC_DOMAIN' THEN 'public domain'
        END,
        CASE WHEN ls.use_type IN ('adapted', 'copied') AND ls.changes_made IS NOT NULL
             THEN '. Changes: ' || ls.changes_made ELSE '' END
    ) AS credit_line,
    cs.source_url,
    cs.license_url,
    cs.title,
    cs.license,
    ls.use_type
FROM lesson_sources ls
JOIN content_sources cs ON cs.id = ls.source_id;
