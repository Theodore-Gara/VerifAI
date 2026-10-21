-- The reward catalogue moved from illustrated PNGs to photographic JPEGs, and
-- the client resolves `image_asset` straight to a bundled file. Any database
-- seeded before the switch still holds the old names, which would render the
-- gift-glyph fallback, so rewrite the extension in place.
UPDATE rewards
SET image_asset = regexp_replace(image_asset, '\.png$', '.jpg')
WHERE image_asset ~ '^reward_[a-z0-9-]+\.png$';
