-- VerifAI AI Lab — capstone assessments (module-level, scenario-based).
--
-- AUTHORING FORMAT (one assessment per industry module; track_id NULL = cross-
-- industry). For each question use one of the practice-activity types:
--   multiple_choice  payload {"options":[...]}        correct {"answer_index":n}
--   true_false       payload {}                       correct {"answer":true|false}
--   fill_blank       payload {}                       correct {"accepted":[...]}
--   matching         payload {"left":[...],"right":[...]} correct {"mapping":{left:right}}
--   ordering         payload {"items":[...]}          correct {"order":[...]}
-- Add a `scenario` stem for the application/real-world feel, and `points` to
-- weight harder questions. The example below is a placeholder to replace.

INSERT INTO achievements (code, name, description)
VALUES ('capstone-responsible-ai', 'Responsible AI Capstone',
        'Passed the cross-industry Responsible AI capstone assessment.')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

INSERT INTO lab_capstone_assessments
  (code, track_id, title, summary, time_limit_seconds, pass_score, max_attempts,
   xp_reward, token_reward, achievement_code, sort_order)
VALUES
  ('responsible-ai-capstone', NULL,
   'Responsible AI at work — capstone',
   'A scenario-based assessment covering verification, AI judgement and risk across the whole module.',
   900, 60, 3, 100, 5, 'capstone-responsible-ai', 100)
ON CONFLICT (code) DO UPDATE SET
  title = EXCLUDED.title,
  summary = EXCLUDED.summary,
  time_limit_seconds = EXCLUDED.time_limit_seconds,
  pass_score = EXCLUDED.pass_score,
  max_attempts = EXCLUDED.max_attempts,
  xp_reward = EXCLUDED.xp_reward,
  token_reward = EXCLUDED.token_reward,
  achievement_code = EXCLUDED.achievement_code,
  sort_order = EXCLUDED.sort_order;

DELETE FROM lab_capstone_questions
WHERE assessment_id = (SELECT id FROM lab_capstone_assessments WHERE code = 'responsible-ai-capstone');
INSERT INTO lab_capstone_questions (assessment_id, type, scenario, prompt, payload, correct, explanation, points, sort_order)
SELECT c.id, v.type, v.scenario, v.prompt, v.payload::jsonb, v.correct::jsonb, v.explanation, v.points, v.sort_order
FROM lab_capstone_assessments c, (VALUES
  ('multiple_choice',
   'Your team wants to paste a client contract into a free online chatbot to summarise it before a deadline.',
   'What is the most responsible first step?',
   '{"options":["Paste it in - summaries are low risk","Check the confidentiality obligations and whether the tool is approved","Ask the chatbot to keep the data private"]}',
   '{"answer_index":1}', 'Confidentiality rules and the tool''s data-handling terms decide whether it may see the document at all.', 1, 1),
  ('multiple_choice',
   'An AI dashboard recommends rejecting a loan applicant and flags the case as high confidence.',
   'Who is accountable for the final decision?',
   '{"options":["The AI vendor","The human decision-maker who acts on the recommendation","No one, because a model decided"]}',
   '{"answer_index":1}', 'A model can recommend; an accountable person decides and records why.', 1, 2),
  ('true_false',
   'A model performed well in testing but its accuracy dropped as the market changed over the following year.',
   'This is an example of distribution shift.',
   '{}', '{"answer":true}', 'Live data drifting from the training data degrades performance silently until someone measures it.', 1, 3),
  ('fill_blank',
   'An AI summary states a figure with no reporting period and no source.',
   'What verdict should you record if you cannot confirm it?',
   '{}', '{"accepted":["unverified"]}', 'Not finding evidence is not the same as disproving it; "unverified" is the honest label.', 2, 4)
) AS v(type, scenario, prompt, payload, correct, explanation, points, sort_order)
WHERE c.code = 'responsible-ai-capstone';
