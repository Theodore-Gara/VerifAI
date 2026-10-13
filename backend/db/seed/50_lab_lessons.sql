-- VerifAI AI Lab — sample lessons (global: available to every industry track).
-- Idempotent: lessons upsert by `code`, and each lesson's child rows are
-- replaced on every run so edits to this file take effect on `db:seed`.

INSERT INTO lab_lessons (code, title, summary, estimated_minutes, level, sort_order)
VALUES
  ('ai-fundamentals', 'AI fundamentals',
   'How language models generate answers, and why fluency is not the same as truth.',
   8, 1, 10),
  ('fact-checking-with-ai', 'Fact-checking with AI',
   'Trace a claim back to trustworthy sources and separate evidence from assumption.',
   6, 1, 20),
  ('ai-ethics-and-bias', 'AI ethics and bias',
   'Recognise bias, privacy and fairness risks before they reach a decision.',
   7, 2, 30)
ON CONFLICT (code) DO UPDATE SET
  title = EXCLUDED.title,
  summary = EXCLUDED.summary,
  estimated_minutes = EXCLUDED.estimated_minutes,
  level = EXCLUDED.level,
  sort_order = EXCLUDED.sort_order;

-- ---------------------------------------------------------------------------
-- ai-fundamentals
-- ---------------------------------------------------------------------------
DELETE FROM lab_lesson_sections WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'ai-fundamentals');
INSERT INTO lab_lesson_sections (lesson_id, heading, body, sort_order)
SELECT l.id, v.heading, v.body, v.sort_order
FROM lab_lessons l, (VALUES
  ('What a language model actually does',
   'A language model predicts the next token given everything before it. It does not look up facts or run a calculation; it produces the most likely continuation. That is why an answer can be fluent, well-formatted and still wrong.', 1),
  ('Why confidence is not accuracy',
   'Fluency is a property of the text, not a signal about the world. A model has no built-in way to know when it is guessing, so it will rarely say "I am unsure" unless it was trained and prompted to.', 2),
  ('Where models help, and where they do not',
   'Models are strong at drafting, summarising and rephrasing. They are weak at anything needing a verifiable source or a guaranteed-correct fact. Match the tool to the job.', 3)
) AS v(heading, body, sort_order)
WHERE l.code = 'ai-fundamentals';

DELETE FROM lab_activities WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'ai-fundamentals');
INSERT INTO lab_activities (lesson_id, kind, title, instructions, sort_order)
SELECT l.id, v.kind, v.title, v.instructions, v.sort_order
FROM lab_lessons l, (VALUES
  ('reflection', 'Spot the fluent-but-wrong answer',
   'Ask an AI a question with a definite answer (e.g. a date or a statistic). Note how confidently it answers, then verify it against a primary source. Write one sentence on what surprised you.', 1),
  ('guided_practice', 'Match tasks to the tool',
   'List three tasks from your work. For each, decide whether "draft, summarise, rephrase" or "verify against a source" is the right approach, and say why.', 2)
) AS v(kind, title, instructions, sort_order)
WHERE l.code = 'ai-fundamentals';

DELETE FROM lab_questions WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'ai-fundamentals');
INSERT INTO lab_questions (lesson_id, prompt, options, correct_index, explanation, sort_order)
SELECT l.id, v.prompt, v.options::jsonb, v.correct_index, v.explanation, v.sort_order
FROM lab_lessons l, (VALUES
  ('A language model answers a factual question smoothly. What does that tell you about the answer?',
   '["That it is very likely correct","Nothing about whether it is correct","That it looked up a source"]', 1,
   'Smooth, confident wording describes the text, not the truth of the claim. It still needs checking.', 1),
  ('Which task is the best fit for a language model?',
   '["Guaranteeing a legal citation is real","Drafting a first version of an email","Stating today''s exact exchange rate"]', 1,
   'Drafting plays to the model''s strength; the other two need a verifiable source.', 2),
  ('Why might a model not say it is unsure?',
   '["It always knows the answer","It has no reliable internal signal for uncertainty","It is not allowed to"]', 1,
   'Models produce likely continuations and have no dependable uncertainty signal unless explicitly built in.', 3)
) AS v(prompt, options, correct_index, explanation, sort_order)
WHERE l.code = 'ai-fundamentals';

-- ---------------------------------------------------------------------------
-- fact-checking-with-ai
-- ---------------------------------------------------------------------------
DELETE FROM lab_lesson_sections WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'fact-checking-with-ai');
INSERT INTO lab_lesson_sections (lesson_id, heading, body, sort_order)
SELECT l.id, v.heading, v.body, v.sort_order
FROM lab_lessons l, (VALUES
  ('Isolate the exact claim',
   'Break a passage into single, checkable statements. "Revenue grew 15% in Q3" is checkable; "the outlook is strong" is not. Vague claims cannot be verified, so rewrite them until they can.', 1),
  ('Find a primary source',
   'Prefer the source that produced the fact: the filing, the study, the official record. A summary of a summary loses detail and gains errors. Check that the source is current and applies to the same context.', 2),
  ('Decide the verdict honestly',
   'Three outcomes are enough: confirmed, refuted, or unverified. "Unverified" is a valid and common result. Do not upgrade an unverified claim to true just because it sounds reasonable.', 3)
) AS v(heading, body, sort_order)
WHERE l.code = 'fact-checking-with-ai';

DELETE FROM lab_activities WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'fact-checking-with-ai');
INSERT INTO lab_activities (lesson_id, kind, title, instructions, sort_order)
SELECT l.id, v.kind, v.title, v.instructions, v.sort_order
FROM lab_lessons l, (VALUES
  ('guided_practice', 'Break a claim into parts',
   'Take a short AI-written paragraph. Split it into individual checkable claims and label each confirmed, refuted or unverified. Bring one to the Workshop to discuss.', 1),
  ('artifact', 'Source log',
   'For one claim, record the exact source you checked, its date, and whether it supports the claim in the same context.', 2)
) AS v(kind, title, instructions, sort_order)
WHERE l.code = 'fact-checking-with-ai';

DELETE FROM lab_questions WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'fact-checking-with-ai');
INSERT INTO lab_questions (lesson_id, prompt, options, correct_index, explanation, sort_order)
SELECT l.id, v.prompt, v.options::jsonb, v.correct_index, v.explanation, v.sort_order
FROM lab_lessons l, (VALUES
  ('You cannot find any source for a confident claim. What is the honest verdict?',
   '["True","False","Unverified"]', 2,
   'Not finding evidence is not the same as disproving it. "Unverified" is the correct, honest label.', 1),
  ('Which is the strongest source to check a financial figure against?',
   '["A social media summary","The company''s audited filing","An AI''s own restatement"]', 1,
   'A primary record such as an audited filing is closest to the fact and loses the least detail.', 2)
) AS v(prompt, options, correct_index, explanation, sort_order)
WHERE l.code = 'fact-checking-with-ai';

-- ---------------------------------------------------------------------------
-- ai-ethics-and-bias
-- ---------------------------------------------------------------------------
DELETE FROM lab_lesson_sections WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'ai-ethics-and-bias');
INSERT INTO lab_lesson_sections (lesson_id, heading, body, sort_order)
SELECT l.id, v.heading, v.body, v.sort_order
FROM lab_lessons l, (VALUES
  ('Bias comes from data and design',
   'Models learn patterns from historical data. If that data under-represents a group, the model reproduces and can amplify the gap. Bias is a property of the system, not a bug you fix once.', 1),
  ('Privacy and confidentiality',
   'Before pasting anything into a tool, ask: is this personal, confidential or regulated? Check the tool''s data-handling terms and your organisation''s approved-tool policy. Unapproved tools should never see sensitive data.', 2),
  ('Fairness needs a human decision',
   'A model can score, rank and suggest, but the decision to act on it belongs to an accountable person. Document who decides, on what evidence, and how you would detect harm.', 3)
) AS v(heading, body, sort_order)
WHERE l.code = 'ai-ethics-and-bias';

DELETE FROM lab_activities WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'ai-ethics-and-bias');
INSERT INTO lab_activities (lesson_id, kind, title, instructions, sort_order)
SELECT l.id, v.kind, v.title, v.instructions, v.sort_order
FROM lab_lessons l, (VALUES
  ('reflection', 'Affected-people map',
   'For an AI use case in your field, list who could be affected and how. Identify one group who might be disadvantaged and one check that would catch it.', 1),
  ('guided_practice', 'Data-handling decision',
   'Given a document, decide whether it is safe to send to (a) an approved tool, (b) an unapproved free tool. Justify with the confidentiality and privacy rules you might be bound by.', 2)
) AS v(kind, title, instructions, sort_order)
WHERE l.code = 'ai-ethics-and-bias';

DELETE FROM lab_questions WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'ai-ethics-and-bias');
INSERT INTO lab_questions (lesson_id, prompt, options, correct_index, explanation, sort_order)
SELECT l.id, v.prompt, v.options::jsonb, v.correct_index, v.explanation, v.sort_order
FROM lab_lessons l, (VALUES
  ('A hiring model rejects more applicants from one group. What is the most responsible first step?',
   '["Assume the model is neutral","Measure outcomes across groups and involve a human reviewer","Ignore it if accuracy is high"]', 1,
   'Fairness is measured by outcomes across groups, and a human must own the decision and any harm.', 1),
  ('You want to summarise a client contract with AI. What must you check first?',
   '["Whether the tool is fast","Whether the tool is approved and how it handles confidential data","Nothing, summaries are always safe"]', 1,
   'Confidentiality rules and data-handling terms decide whether a tool may see the document at all.', 2)
) AS v(prompt, options, correct_index, explanation, sort_order)
WHERE l.code = 'ai-ethics-and-bias';
