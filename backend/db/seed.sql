-- VerifAI — shared seed data
-- Tracks and achievements. Task content lives in db/seed/*.sql and is applied
-- after this file by scripts/db-setup.js.

INSERT INTO industry_tracks (name, description) VALUES
  ('Finance', 'Financial services and banking scenarios'),
  ('Legal', 'Legal research and compliance scenarios'),
  ('IT / Software', 'Software development and IT operations scenarios'),
  ('Business Consulting', 'Management consulting and strategy scenarios')
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description;

INSERT INTO achievements (code, name, description) VALUES
  ('first-task', 'First Assessment', 'Complete your first workplace readiness task.'),
  ('five-tasks', 'Five in the Bag', 'Complete five workplace readiness tasks.'),
  ('ten-tasks', 'Consistent Practitioner', 'Complete ten workplace readiness tasks.'),
  ('xp-500', '500 XP', 'Earn at least 500 XP.'),
  ('dimension-80', 'Strong Skill', 'Reach a score of at least 80 in one readiness skill.')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;
