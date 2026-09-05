-- VerifAI Seed Data

-- Seed users (prototype). Passwords live in Firebase Auth in production;
-- the mock mobile app accepts the default prototype password: password123
INSERT INTO users (firebase_uid, email, display_name) VALUES
  ('theo@verif.com', 'theo@verif.com', 'Theodore Nangara'),
  ('vusani@verif.com', 'vusani@verif.com', 'Vusani Earl Mulaudzi'),
  ('naledi@verif.com', 'naledi@verif.com', 'Lwandle Naledi Chloe Mvelase'),
  ('mpho@verif.com', 'mpho@verif.com', 'Mpho Mokoena'),
  ('meshaque@verif.com', 'meshaque@verif.com', 'Meshaque Kalonji');

INSERT INTO industry_tracks (name, description) VALUES
  ('Finance', 'Financial services and banking scenarios'),
  ('Legal', 'Legal research and compliance scenarios'),
  ('IT / Software', 'Software development and IT operations scenarios'),
  ('Business Consulting', 'Management consulting and strategy scenarios');

-- Sample tasks will be added as employer-sourced scenarios are developed
