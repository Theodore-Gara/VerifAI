-- VerifAI — shared seed data
-- Tracks, prototype users and achievements. Task content lives in db/seed/*.sql
-- and is applied after this file by scripts/db-setup.js.

INSERT INTO industry_tracks (name, description) VALUES
  ('Finance', 'Financial services and banking scenarios'),
  ('Legal', 'Legal research and compliance scenarios'),
  ('IT / Software', 'Software development and IT operations scenarios'),
  ('Business Consulting', 'Management consulting and strategy scenarios')
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description;

-- Prototype users from the original team seed. In production, Firebase Auth owns credentials.
INSERT INTO users (firebase_uid, email, display_name)
VALUES
  ('theo@verif.com', 'theo@verif.com', 'Theodore Nangara'),
  ('vusani@verif.com', 'vusani@verif.com', 'Vusani Earl Mulaudzi'),
  ('naledi@verif.com', 'naledi@verif.com', 'Lwandle Naledi Chloe Mvelase'),
  ('mpho@verif.com', 'mpho@verif.com', 'Mpho Mokoena'),
  ('meshaque@verif.com', 'meshaque@verif.com', 'Meshaque Kalonji')
ON CONFLICT (firebase_uid) DO UPDATE
SET email = EXCLUDED.email,
    display_name = EXCLUDED.display_name;

INSERT INTO achievements (code, name, description) VALUES
  ('first-task', 'First Assessment', 'Complete your first workplace readiness task.'),
  ('five-tasks', 'Five in the Bag', 'Complete five workplace readiness tasks.'),
  ('ten-tasks', 'Consistent Practitioner', 'Complete ten workplace readiness tasks.'),
  ('xp-500', '500 XP', 'Earn at least 500 XP.'),
  ('dimension-80', 'Strong Skill', 'Reach a score of at least 80 in one readiness skill.')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;
