-- 038_industry_track_presentation.sql
--
-- The industry picker used to hardcode an icon and a one-line perk per track
-- name inside the Flutter widget, so any newly added track rendered as a
-- generic placeholder. Both values now live on the row so the catalogue can
-- grow without a client release.
--
-- Idempotent. Mirrors the relevant block in db/schema.sql so a fresh database
-- built from schema.sql and an upgraded database via migrations end up equal.

ALTER TABLE industry_tracks
  ADD COLUMN IF NOT EXISTS icon_key VARCHAR(50),
  ADD COLUMN IF NOT EXISTS perk VARCHAR(120);

-- Backfill the four tracks that ship today. A track added later through the
-- admin tooling gets NULL for both and the client falls back to a neutral
-- icon and a generic perk line.
UPDATE industry_tracks SET icon_key = 'finance',    perk = 'Numerical Auditing'  WHERE name = 'Finance';
UPDATE industry_tracks SET icon_key = 'legal',      perk = 'Clause Citation'     WHERE name = 'Legal';
UPDATE industry_tracks SET icon_key = 'it',         perk = 'Code Verification'   WHERE name = 'IT / Software';
UPDATE industry_tracks SET icon_key = 'consulting', perk = 'Strategy Governance' WHERE name = 'Business Consulting';
