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
  ('dimension-80', 'Strong Skill', 'Reach a score of at least 80 in one readiness skill.'),
  ('xp-2000', '2000 XP', 'Earn at least 2,000 XP.'),
  ('streak-7', 'Week Streak', 'Keep a seven-day practice streak.'),
  ('streak-30', 'Month Streak', 'Keep a thirty-day practice streak.'),
  ('all-features', 'Triple Threat', 'Pass at least one task in each feature: verification, AI judgement and risk & governance.'),
  ('verification-10', 'Verification Specialist', 'Pass ten verification tasks.'),
  ('judgement-10', 'Sound Judgement', 'Pass ten AI judgement tasks.'),
  ('risk-10', 'Guardian', 'Pass ten risk & governance tasks.'),
  ('capstone-1', 'Capstone Earner', 'Pass a capstone assessment.'),
  ('interview-5', 'Interview Ready', 'Practise five interview questions.')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;
