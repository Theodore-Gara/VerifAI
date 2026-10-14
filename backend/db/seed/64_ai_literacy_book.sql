-- VerifAI AI Lab — AI literacy textbook (cross-industry, available to every track).
-- The three former AI lessons are folded into a single "AI literacy" chapter;
-- AI governance keeps its own chapter. Idempotent.

INSERT INTO lab_lessons (code, track_id, title, summary, estimated_minutes, level, is_original, competency, sort_order)
VALUES
  ('ai-literacy-book', NULL,
   'Working with AI: a short textbook',
   'How language models generate answers, how to fact-check them, the ethics of using them, and how to govern AI by risk.',
   40, 1, FALSE, 'Risk & Governance', 200)
ON CONFLICT (code) DO UPDATE SET
  title = EXCLUDED.title, summary = EXCLUDED.summary,
  estimated_minutes = EXCLUDED.estimated_minutes, level = EXCLUDED.level,
  competency = EXCLUDED.competency, sort_order = EXCLUDED.sort_order;

DELETE FROM lab_lessons WHERE code IN ('ai-fundamentals', 'fact-checking-with-ai', 'ai-ethics-and-bias', 'risk-ai-governance-nist');

DELETE FROM lab_lesson_sections WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'ai-literacy-book');

-- Chapters ------------------------------------------------------------------
INSERT INTO lab_lesson_sections (lesson_id, heading, body, parent_id, sort_order)
SELECT l.id, v.heading, v.body, NULL, v.sort_order
FROM lab_lessons l, (VALUES
  ('AI literacy', 'How models work, how to check them, and the ethics of using them.', 1),
  ('AI governance', 'Governing AI by risk: map, measure, manage and document.', 2)
) AS v(heading, body, sort_order)
WHERE l.code = 'ai-literacy-book';

-- Topics --------------------------------------------------------------------
INSERT INTO lab_lesson_sections (lesson_id, heading, body, parent_id, sort_order)
SELECT l.id, v.heading, v.body, ch.id, v.tsort
FROM lab_lessons l,
(VALUES
  ('AI literacy', 'How a language model works', 'Predicting text, and why fluency is not truth.', 1),
  ('AI literacy', 'Fact-checking with AI', 'Tracing a claim back to a trustworthy source.', 2),
  ('AI literacy', 'Ethics and bias', 'Recognising bias, privacy and fairness risks.', 3),
  ('AI governance', 'A risk-based approach', 'Map, measure, manage and document.', 1)
) AS v(chapter, heading, body, tsort),
lab_lesson_sections ch
WHERE l.code = 'ai-literacy-book'
  AND ch.lesson_id = l.id AND ch.parent_id IS NULL AND ch.heading = v.chapter;

-- Subtopics -----------------------------------------------------------------
INSERT INTO lab_lesson_sections (lesson_id, heading, body, parent_id, sort_order)
SELECT l.id, v.heading, v.body, tp.id, v.ssort
FROM lab_lessons l,
(VALUES
  ('AI literacy', 'How a language model works', 'What a language model actually does',
   'A language model predicts the next token given everything before it. It does not look up facts or run a calculation; it produces the most likely continuation. That is why an answer can be fluent, well-formatted and still wrong.', 1),
  ('AI literacy', 'How a language model works', 'Why confidence is not accuracy',
   'Fluency is a property of the text, not a signal about the world. A model has no built-in way to know when it is guessing, so it will rarely say "I am unsure" unless it was trained and prompted to.', 2),
  ('AI literacy', 'How a language model works', 'Where models help, and where they do not',
   'Models are strong at drafting, summarising and rephrasing. They are weak at anything needing a verifiable source or a guaranteed-correct fact. Match the tool to the job.', 3),
  ('AI literacy', 'Fact-checking with AI', 'Isolate the exact claim',
   'Break a passage into single, checkable statements. "Revenue grew 15% in Q3" is checkable; "the outlook is strong" is not. Vague claims cannot be verified, so rewrite them until they can.', 1),
  ('AI literacy', 'Fact-checking with AI', 'Find a primary source',
   'Prefer the source that produced the fact: the filing, the study, the official record. A summary of a summary loses detail and gains errors. Check that the source is current and applies to the same context.', 2),
  ('AI literacy', 'Fact-checking with AI', 'Decide the verdict honestly',
   'Three outcomes are enough: confirmed, refuted, or unverified. "Unverified" is a valid and common result. Do not upgrade an unverified claim to true just because it sounds reasonable.', 3),
  ('AI literacy', 'Ethics and bias', 'Bias comes from data and design',
   'Models learn patterns from historical data. If that data under-represents a group, the model reproduces and can amplify the gap. Bias is a property of the system, not a bug you fix once.', 1),
  ('AI literacy', 'Ethics and bias', 'Privacy and confidentiality',
   'Before pasting anything into a tool, ask: is this personal, confidential or regulated? Check the tool''s data-handling terms and your organisation''s approved-tool policy. Unapproved tools should never see sensitive data.', 2),
  ('AI literacy', 'Ethics and bias', 'Fairness needs a human decision',
   'A model can score, rank and suggest, but the decision to act on it belongs to an accountable person. Document who decides, on what evidence, and how you would detect harm.', 3),
  ('AI governance', 'A risk-based approach', 'Govern by risk, not by tool',
   'Start from the use case and its potential harms, not from the AI tool. The same model can be low-risk in one context and high-risk in another.', 1),
  ('AI governance', 'A risk-based approach', 'Map, measure, manage',
   'Identify the context and risks, assess how serious they are, then assign controls and named owners.', 2),
  ('AI governance', 'A risk-based approach', 'Document and review',
   'Keep a record of the assessment and review it as the system, the data or the world changes.', 3)
) AS v(chapter, topic, heading, body, ssort),
lab_lesson_sections ch,
lab_lesson_sections tp
WHERE l.code = 'ai-literacy-book'
  AND ch.lesson_id = l.id AND ch.parent_id IS NULL AND ch.heading = v.chapter
  AND tp.lesson_id = l.id AND tp.parent_id = ch.id AND tp.heading = v.topic;

-- End-of-book questions -----------------------------------------------------
DELETE FROM lab_questions WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'ai-literacy-book');
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
   'Models produce likely continuations and have no dependable uncertainty signal unless explicitly built in.', 3),
  ('You cannot find any source for a confident claim. What is the honest verdict?',
   '["True","False","Unverified"]', 2,
   'Not finding evidence is not the same as disproving it. "Unverified" is the correct, honest label.', 4),
  ('Which is the strongest source to check a financial figure against?',
   '["A social media summary","The company''s audited filing","An AI''s own restatement"]', 1,
   'A primary record such as an audited filing is closest to the fact and loses the least detail.', 5),
  ('A hiring model rejects more applicants from one group. What is the most responsible first step?',
   '["Assume the model is neutral","Measure outcomes across groups and involve a human reviewer","Ignore it if accuracy is high"]', 1,
   'Fairness is measured by outcomes across groups, and a human must own the decision and any harm.', 6),
  ('You want to summarise a client contract with AI. What must you check first?',
   '["Whether the tool is fast","Whether the tool is approved and how it handles confidential data","Nothing, summaries are always safe"]', 1,
   'Confidentiality rules and data-handling terms decide whether a tool may see the document at all.', 7),
  ('A risk-based approach starts from which question?',
   '["Which model is most advanced?","What is the use case and who could be harmed?","How fast can we ship?"]', 1,
   'Risk is a property of the use case and its context, not the model alone.', 8),
  ('After identifying and assessing risks, what comes next?',
   '["Ignore them","Assign controls and named owners, then document","Increase the temperature"]', 1,
   'Managing risk means controls, ownership and a written record that is reviewed over time.', 9)
) AS v(prompt, options, correct_index, explanation, sort_order)
WHERE l.code = 'ai-literacy-book';

-- Source links --------------------------------------------------------------
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'inspired_by', NULL
FROM lab_lessons l, content_sources cs
WHERE l.code = 'ai-literacy-book' AND cs.title = 'Dive into Deep Learning'
ON CONFLICT DO NOTHING;
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'adapted', 'Added South African examples and condensed the guidance into original prose.'
FROM lab_lessons l, content_sources cs
WHERE l.code = 'ai-literacy-book' AND cs.title = 'NIST AI Risk Management Framework'
ON CONFLICT DO NOTHING;
