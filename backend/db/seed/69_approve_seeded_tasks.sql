-- 69_approve_seeded_tasks.sql — curated seed content counts as approved.
--
-- tasks.approval defaults to 'pending' so admin-imported tasks always get a
-- moderator sign-off, but the content in db/seed/*.sql is curated in-repo and
-- is published straight away (schema default published = TRUE). On the hosted
-- database the equivalent step is migration 023, which approves every task
-- that was already live; a fresh build baselines that migration without
-- running it, so the seed pipeline needs its own approval pass. The demo
-- activity seed (70_demo_activity.sql) also filters on approval = 'approved'
-- when generating attempts, so without this step a fresh database ends up
-- with zero demo attempts and an Approvals queue full of noise.
--
-- Runs after every content seed and before 70_demo_activity.sql. The three
-- unpublished demo drafts inserted by 70 stay 'pending' (they are not
-- published, so this UPDATE does not touch them).

UPDATE tasks
SET approval = 'approved', approved_by = 'seed', approved_at = CURRENT_TIMESTAMP
WHERE published AND approval = 'pending';
