-- VerifAI AI Lab — practice activities for the global (cross-industry) lessons.
-- 10 each, same typed recall model as 54. Original wording; concepts drawn from
-- the lesson's linked sources. Idempotent: replaces activities per lesson.

-- ---------------------------------------------------------------------------
-- ai-fundamentals
-- ---------------------------------------------------------------------------
DELETE FROM lab_activities WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'ai-fundamentals');
INSERT INTO lab_activities (lesson_id, type, prompt, payload, correct, explanation, source_id, sort_order)
SELECT l.id, v.type, v.prompt, v.payload::jsonb, v.correct::jsonb, v.explanation,
       (SELECT id FROM content_sources cs WHERE cs.title = v.source_title), v.sort_order
FROM lab_lessons l, (VALUES
  ('multiple_choice', 'What does a language model actually do when it answers a question?',
   '{"options":["Looks up facts in a verified database","Predicts the most likely next token given the text before it","Runs a live web search"]}',
   '{"answer_index":1}', 'A model predicts the next token from the preceding text; it does not look up facts or search.',
   'Dive into Deep Learning', 1),
  ('true_false', 'A language model looks up facts from a verified database before answering.',
   '{}', '{"answer":false}', 'It produces likely continuations; there is no verified fact database behind the answer.',
   'Dive into Deep Learning', 2),
  ('true_false', 'Confident, well-formatted wording is evidence that an answer is correct.',
   '{}', '{"answer":false}', 'Fluency is a property of the text, not a signal about the world.',
   'Dive into Deep Learning', 3),
  ('fill_blank', 'A language model produces the most likely next ___ given everything before it.',
   '{}', '{"accepted":["token","word"]}', 'The model predicts one token at a time from the preceding text.',
   'Dive into Deep Learning', 4),
  ('matching', 'Match each term to its meaning.',
   '{"left":["Fluency","Token","Training data","Hallucination"],"right":["the text the model learned patterns from","smooth, well-formed text","a confident but unsupported answer","a unit of text the model predicts"]}',
   '{"mapping":{"Fluency":"smooth, well-formed text","Token":"a unit of text the model predicts","Training data":"the text the model learned patterns from","Hallucination":"a confident but unsupported answer"}}',
   'Fluency describes the text; a token is the unit predicted; training data shapes the model; a hallucination is confident but unsupported.',
   'Dive into Deep Learning', 5),
  ('multiple_choice', 'Which task is the best fit for a language model?',
   '{"options":["Guaranteeing a legal citation is real","Drafting a first version of an email","Stating today''s exact exchange rate"]}',
   '{"answer_index":1}', 'Drafting plays to the model''s strength; the other two need a verifiable source.',
   'Dive into Deep Learning', 6),
  ('multiple_choice', 'Why might a model not say it is unsure?',
   '{"options":["It always knows the correct answer","It has no reliable internal signal for uncertainty","It is not allowed to say so"]}',
   '{"answer_index":1}', 'Models produce likely continuations and have no dependable uncertainty signal unless explicitly built in.',
   'Dive into Deep Learning', 7),
  ('ordering', 'Put the steps for deciding whether to trust an AI answer into the correct order.',
   '{"items":["Accept it or flag it as unverified","Decide whether the claim needs a verifiable source","Identify what the answer claims","Check the claim against a source"]}',
   '{"order":["Identify what the answer claims","Decide whether the claim needs a verifiable source","Check the claim against a source","Accept it or flag it as unverified"]}',
   'Clarify the claim, decide if it needs a source, check it, then record a verdict.',
   'Dive into Deep Learning', 8),
  ('true_false', 'Models are strong at drafting, summarising and rephrasing text.',
   '{}', '{"answer":true}', 'Those are exactly the tasks language models do well.',
   'Dive into Deep Learning', 9),
  ('fill_blank', 'Fluency is a property of the text, not a ___ about the world.',
   '{}', '{"accepted":["signal","evidence"]}', 'Confident wording tells you nothing about whether the claim is true.',
   'Dive into Deep Learning', 10)
) AS v(type, prompt, payload, correct, explanation, source_title, sort_order)
WHERE l.code = 'ai-fundamentals';

-- ---------------------------------------------------------------------------
-- fact-checking-with-ai
-- ---------------------------------------------------------------------------
DELETE FROM lab_activities WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'fact-checking-with-ai');
INSERT INTO lab_activities (lesson_id, type, prompt, payload, correct, explanation, source_id, sort_order)
SELECT l.id, v.type, v.prompt, v.payload::jsonb, v.correct::jsonb, v.explanation,
       (SELECT id FROM content_sources cs WHERE cs.title = v.source_title), v.sort_order
FROM lab_lessons l, (VALUES
  ('multiple_choice', 'Which of these is a checkable claim?',
   '{"options":["Revenue grew 15% in Q3","The outlook is strong","The company is well run"]}',
   '{"answer_index":0}', 'A specific figure with a period is checkable; the others are vague opinions.',
   'NIST AI Risk Management Framework', 1),
  ('fill_blank', 'The three honest verdicts are confirmed, refuted and ___.',
   '{}', '{"accepted":["unverified"]}', 'Not finding evidence is not the same as disproving it; unverified is a valid verdict.',
   'NIST AI Risk Management Framework', 2),
  ('multiple_choice', 'Which is the strongest source to check a financial figure against?',
   '{"options":["A social media summary","The company''s audited filing","An AI''s own restatement"]}',
   '{"answer_index":1}', 'A primary record such as an audited filing is closest to the fact and loses the least detail.',
   'NIST AI Risk Management Framework', 3),
  ('true_false', 'If you cannot find a source for a confident claim, the claim is false.',
   '{}', '{"answer":false}', 'Absence of evidence is not disproof. Label it unverified, not false.',
   'NIST AI Risk Management Framework', 4),
  ('matching', 'Match each source to its strength.',
   '{"left":["Audited filing","Social media summary","Official record","A summary of a summary"],"right":["loses detail and gains errors","primary source","weak secondary source","primary source"]}',
   '{"mapping":{"Audited filing":"primary source","Social media summary":"weak secondary source","Official record":"primary source","A summary of a summary":"loses detail and gains errors"}}',
   'Primary records are strongest; summaries lose detail; social media is a weak secondary source.',
   'NIST AI Risk Management Framework', 5),
  ('ordering', 'Put the steps for verifying a claim into the correct order.',
   '{"items":["Check the source is current and applies","Record confirmed, refuted or unverified","Isolate the exact claim","Find a primary source"]}',
   '{"order":["Isolate the exact claim","Find a primary source","Check the source is current and applies","Record confirmed, refuted or unverified"]}',
   'Break out the claim, find the primary source, check currency and context, then record a verdict.',
   'NIST AI Risk Management Framework', 6),
  ('multiple_choice', 'A confident claim that you cannot confirm should be labelled?',
   '{"options":["True","False","Unverified"]}', '{"answer_index":2}',
   'Unverified is the honest label when you have no supporting evidence.',
   'NIST AI Risk Management Framework', 7),
  ('true_false', 'A summary of a summary is as reliable as the original source.',
   '{}', '{"answer":false}', 'Each layer adds error and drops detail; go back to the original where you can.',
   'NIST AI Risk Management Framework', 8),
  ('fill_blank', 'Prefer the source that produced the fact - the ___ source.',
   '{}', '{"accepted":["primary"]}', 'The primary source is closest to the fact and the least distorted.',
   'NIST AI Risk Management Framework', 9),
  ('multiple_choice', 'The only source you find applies to a different context. What is the correct verdict?',
   '{"options":["Still true everywhere","Unverified for this context","Automatically false"]}',
   '{"answer_index":1}', 'A source that does not match the context cannot confirm the claim; mark it unverified.',
   'NIST AI Risk Management Framework', 10)
) AS v(type, prompt, payload, correct, explanation, source_title, sort_order)
WHERE l.code = 'fact-checking-with-ai';

-- ---------------------------------------------------------------------------
-- ai-ethics-and-bias
-- ---------------------------------------------------------------------------
DELETE FROM lab_activities WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'ai-ethics-and-bias');
INSERT INTO lab_activities (lesson_id, type, prompt, payload, correct, explanation, source_id, sort_order)
SELECT l.id, v.type, v.prompt, v.payload::jsonb, v.correct::jsonb, v.explanation,
       (SELECT id FROM content_sources cs WHERE cs.title = v.source_title), v.sort_order
FROM lab_lessons l, (VALUES
  ('multiple_choice', 'A hiring model rejects more applicants from one group. What is the most responsible first step?',
   '{"options":["Assume the model is neutral","Measure outcomes across groups and involve a human reviewer","Ignore it if overall accuracy is high"]}',
   '{"answer_index":1}', 'Fairness is measured by outcomes across groups, and a human must own the decision and any harm.',
   'NIST AI Risk Management Framework', 1),
  ('true_false', 'Bias is a bug you fix once and then move on.',
   '{}', '{"answer":false}', 'Bias is a property of the data and design; it needs monitoring, not a one-off fix.',
   'NIST AI Risk Management Framework', 2),
  ('multiple_choice', 'Before pasting a client contract into an AI tool, what must you check?',
   '{"options":["Whether the tool is fast","Whether the tool is approved and how it handles confidential data","Nothing, summaries are always safe"]}',
   '{"answer_index":1}', 'Confidentiality rules and the tool''s data-handling terms decide whether it may see the document at all.',
   'NIST AI Risk Management Framework', 3),
  ('true_false', 'A model can reproduce and amplify an existing gap in the data.',
   '{}', '{"answer":true}', 'If data under-represents a group, the model reproduces and can amplify the gap.',
   'NIST AI Risk Management Framework', 4),
  ('matching', 'Match each term to its meaning.',
   '{"left":["Bias","Confidential data","Disparate impact","Human accountability"],"right":["a person owns the decision","unfair outcomes across groups","a systematic gap learned from data","information you must not expose"]}',
   '{"mapping":{"Bias":"a systematic gap learned from data","Confidential data":"information you must not expose","Disparate impact":"unfair outcomes across groups","Human accountability":"a person owns the decision"}}',
   'Bias comes from data; confidential data must be protected; disparate impact is uneven outcomes; a person stays accountable.',
   'NIST AI Risk Management Framework', 5),
  ('ordering', 'Put the fairness workflow into the correct order.',
   '{"items":["Assign an accountable reviewer","Map who could be affected","Act on any unfairness","Measure outcomes across groups"]}',
   '{"order":["Map who could be affected","Measure outcomes across groups","Assign an accountable reviewer","Act on any unfairness"]}',
   'Map affected people, measure outcomes, assign a reviewer, then act on what you find.',
   'NIST AI Risk Management Framework', 6),
  ('fill_blank', 'Fairness is measured by ___ across groups.',
   '{}', '{"accepted":["outcomes"]}', 'Compare outcomes between groups to detect unfairness.',
   'NIST AI Risk Management Framework', 7),
  ('true_false', 'High overall accuracy means a model is fair.',
   '{}', '{"answer":false}', 'A model can be accurate overall yet unfair to a specific group.',
   'NIST AI Risk Management Framework', 8),
  ('multiple_choice', 'Who decides to act on an AI recommendation?',
   '{"options":["The model itself","An accountable person","No one"]}',
   '{"answer_index":1}', 'A model can recommend; an accountable person decides and records why.',
   'NIST AI Risk Management Framework', 9),
  ('fill_blank', 'Before using an AI tool with sensitive data, check its data-handling ___.',
   '{}', '{"accepted":["terms","policy","terms and conditions"]}', 'The tool''s data-handling terms and your policy decide whether it may process the data.',
   'NIST AI Risk Management Framework', 10)
) AS v(type, prompt, payload, correct, explanation, source_title, sort_order)
WHERE l.code = 'ai-ethics-and-bias';
