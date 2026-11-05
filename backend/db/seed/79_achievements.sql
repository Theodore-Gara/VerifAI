-- 79_achievements.sql — the six former roadmap items now live in the reward
-- shelf (BF-9). The roadmap itself is GET /api/roadmap (BB-10) and must never
-- read XP, streaks or achievements.
--
-- The plan named this 78_achievements.sql, but 78 is already the support tour
-- manifest; the seed filename is the only difference.
--
-- `first-task` and `streak-7` already exist, so they are updated in place to the
-- copy the roadmap used. `track-master`, `xp-250`, `xp-1000` and `level-5` are
-- new. Idempotent upsert by `code`.
--
-- Note on the count: BF-9 was written when the catalog had 5 base achievements
-- and 4 capstones (14 after the migration). The repository has since grown to
-- 14 base achievements, so this additive seed yields 22 rows. The alternative -
-- deleting the older achievements to hit the old number - would cascade-delete
-- learners' earned badges, so the catalog is kept additive.

INSERT INTO achievements (code, name, description) VALUES
  ('first-task', 'First Steps', 'Complete your first workplace readiness task.'),
  ('streak-7', 'On Fire', 'Keep a seven-day practice streak.'),
  ('track-master', 'Track Master', 'Pass every published task in your active industry track.'),
  ('xp-250', 'Committed', 'Earn at least 250 XP.'),
  ('xp-1000', 'Dedicated', 'Earn at least 1,000 XP.'),
  ('level-5', 'Seasoned', 'Reach level 5.')
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description;
