-- VerifAI rewards catalog. Costs are in reward tokens (earned from level-ups
-- and achievements), NOT XP. Idempotent upsert by `code`.

INSERT INTO rewards (code, title, subtitle, cost_tokens, image_asset, note, active, sort_order)
VALUES
  ('coffee', 'Coffee break',
   'A coffee reward concept for celebrating a learning streak.', 10,
   'reward_coffee.png', 'Illustrative reward', TRUE, 10),
  ('game-night', 'Game night',
   'A gaming reward concept inspired by cozy sandbox adventures.', 12,
   'reward_game.png', 'No game code included', TRUE, 20),
  ('paws', 'Paws for a cause',
   'A concept for supporting an animal rescue once a verified partner is available.', 15,
   'reward_paws.png', 'No donation made', TRUE, 30),
  ('community-impact', 'Community impact',
   'A future option to support a vetted organisation, subject to an approved partnership.', 18,
   'reward_impact.png', 'Partner needed', TRUE, 40),
  ('workshop-pass', 'Workshop pass',
   'A future ticket to an AI, software, career or professional-skills workshop.', 20,
   'reward_workshop.png', 'Workshop partner needed', TRUE, 50),
  ('grocery', 'Everyday essentials',
   'An illustrative grocery voucher concept for a future verified partner.', 22,
   'reward_grocery.png', 'Partner required', TRUE, 60),
  ('fuel', 'Fuel your next move',
   'A petrol voucher concept for celebrating consistent practice.', 25,
   'reward_fuel.png', 'Partner required', TRUE, 70),
  ('game-credit', 'Game store credit',
   'A digital gaming credit concept for reaching a higher milestone.', 28,
   'reward_gamecredit.png', 'No code included', TRUE, 80),
  ('m365', 'Microsoft 365 boost',
   'A productivity-software voucher or subscription concept for future learners.', 30,
   'reward_m365.png', 'Availability varies', TRUE, 90)
ON CONFLICT (code) DO UPDATE SET
  title = EXCLUDED.title,
  subtitle = EXCLUDED.subtitle,
  cost_tokens = EXCLUDED.cost_tokens,
  image_asset = EXCLUDED.image_asset,
  note = EXCLUDED.note,
  active = EXCLUDED.active,
  sort_order = EXCLUDED.sort_order;
