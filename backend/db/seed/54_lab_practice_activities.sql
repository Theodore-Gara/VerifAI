-- VerifAI AI Lab — practice activities (read-and-recall), 10 per lesson.
-- Original wording; concepts drawn from the lesson's sources. Answer keys and
-- grading stay server-side. Idempotent: replaces the activities per lesson.
--
-- Payload shapes (sent to the app, answer withheld):
--   multiple_choice {"options":[...]}          correct {"answer_index":n}
--   true_false      {}                          correct {"answer":true|false}
--   fill_blank      {}                          correct {"accepted":[...]}
--   matching        {"left":[...],"right":[...]} correct {"mapping":{left:right}}
--   ordering        {"items":[...]}             correct {"order":[...]}

-- ---------------------------------------------------------------------------
-- finance-read-the-numbers
-- ---------------------------------------------------------------------------
DELETE FROM lab_activities WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'finance-read-the-numbers');
INSERT INTO lab_activities (lesson_id, type, prompt, payload, correct, explanation, source_id, sort_order)
SELECT l.id, v.type, v.prompt, v.payload::jsonb, v.correct::jsonb, v.explanation,
       (SELECT id FROM content_sources cs WHERE cs.title = v.source_title), v.sort_order
FROM lab_lessons l, (VALUES
  ('multiple_choice', 'An AI summary states "profit up 12%" with no period or source. What is the responsible first step?',
   '{"options":["Accept it - it is a specific number","Find the reporting period and source before relying on it","Round it to the nearest whole number"]}',
   '{"answer_index":1}', 'A number without a period and source cannot be verified. Locate both first.',
   'Financial Management for Small Businesses', 1),
  ('true_false', 'A single ratio on its own is enough to draw a business conclusion.',
   '{}', '{"answer":false}', 'A ratio needs a benchmark - a prior period, a peer or a target - before it means anything.',
   'Introduction to Financial Analysis', 2),
  ('fill_blank', 'To compare a rand today with a rand next year, you must apply a ___ rate.',
   '{}', '{"accepted":["discount","discount rate","discounting"]}', 'Figures across time are only comparable once discounted to a common point.',
   'Introduction to Financial Analysis', 3),
  ('matching', 'Match each financial ratio to what it mainly measures.',
   '{"left":["Current ratio","Debt-to-equity ratio","Net profit margin","Inventory turnover"],"right":["Operating efficiency","Profitability","Financial leverage","Short-term liquidity"]}',
   '{"mapping":{"Current ratio":"Short-term liquidity","Debt-to-equity ratio":"Financial leverage","Net profit margin":"Profitability","Inventory turnover":"Operating efficiency"}}',
   'Current ratio compares current assets to current liabilities; debt-to-equity compares borrowed funds to owners funds; net profit margin is profit as a share of sales; inventory turnover shows how quickly stock is sold.',
   'Introduction to Financial Analysis', 4),
  ('multiple_choice', 'Which comparison is safe to make without adjustment?',
   '{"options":["Cash today versus cash in three years","Two figures from the same period and currency","Last year''s rand versus this year''s with no inflation note"]}',
   '{"answer_index":1}', 'Same period and currency are directly comparable; the others need a time-value adjustment.',
   'Introduction to Financial Analysis', 5),
  ('true_false', 'An audited figure and a rough estimate in the same summary are equally reliable.',
   '{}', '{"answer":false}', 'Audited and estimated figures carry different reliability; the summary must say which is which.',
   'Financial Management for Small Businesses', 6),
  ('fill_blank', 'Compound interest: FV = PV x (1 + r)^___ (r is the rate per period).',
   '{}', '{"accepted":["n","number of periods","the number of periods"]}', 'The exponent is the number of compounding periods. Each extra period multiplies the balance by (1 + r) again.',
   'Introduction to Financial Analysis', 7),
  ('ordering', 'Put the steps for checking a number in a summary into the correct order.',
   '{"items":["Mark it confirmed or unverified","Identify the exact claim","Find the source and its date","Check the period and currency"]}',
   '{"order":["Identify the exact claim","Find the source and its date","Check the period and currency","Mark it confirmed or unverified"]}',
   'Isolate the claim, find the source and date, check the period and currency, then record a verdict.',
   'Financial Management for Small Businesses', 8),
  ('multiple_choice', 'A summary omits the reporting period. Why does that matter most?',
   '{"options":["It changes the font of the report","Figures without a period cannot be compared or verified","It makes the number larger"]}',
   '{"answer_index":1}', 'A number with no period cannot be compared with anything else or tied to a source.',
   'Financial Management for Small Businesses', 9),
  ('true_false', 'Profit and cash are the same thing.',
   '{}', '{"answer":false}', 'A business can be profitable and still run short of cash if customers pay late or stock is bought upfront.',
   'Financial Management for Small Businesses', 10)
) AS v(type, prompt, payload, correct, explanation, source_title, sort_order)
WHERE l.code = 'finance-read-the-numbers';

-- ---------------------------------------------------------------------------
-- finance-verify-a-forecast
-- ---------------------------------------------------------------------------
DELETE FROM lab_activities WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'finance-verify-a-forecast');
INSERT INTO lab_activities (lesson_id, type, prompt, payload, correct, explanation, source_id, sort_order)
SELECT l.id, v.type, v.prompt, v.payload::jsonb, v.correct::jsonb, v.explanation,
       (SELECT id FROM content_sources cs WHERE cs.title = v.source_title), v.sort_order
FROM lab_lessons l, (VALUES
  ('true_false', 'Under certainty, a project with a positive net present value (NPV) adds value to the firm and should be accepted.',
   '{}', '{"answer":true}', 'NPV discounts future cash flows at the required return and subtracts the initial cost. Positive means it earns more than required.',
   'Corporate Finance', 1),
  ('multiple_choice', 'Which formula gives the cash conversion cycle (CCC)?',
   '{"options":["Days inventory outstanding + days sales outstanding - days payables outstanding","Days inventory outstanding + days payables outstanding - days sales outstanding","Days sales outstanding + days payables outstanding - days inventory outstanding"]}',
   '{"answer_index":0}', 'CCC is how long cash is tied up: time to sell stock plus time to collect from customers, minus the time you take to pay suppliers.',
   'Corporate Finance', 2),
  ('true_false', 'A small business that reports a profit cannot run out of cash.',
   '{}', '{"answer":false}', 'Profit and cash differ. Late-paying customers, upfront stock or loan repayments can drain cash while the accounts still show a profit.',
   'Financial Management for Small Businesses', 3),
  ('multiple_choice', 'A forecast is built on data that ends before a major new competitor entered the market. What does that most affect?',
   '{"options":["The font of the report","The validity of the growth assumption","Nothing - forecasts are always accurate"]}',
   '{"answer_index":1}', 'Stale inputs invalidate the growth assumption, which drives the whole forecast.',
   'Financial Management for Small Businesses', 4),
  ('fill_blank', 'Cash conversion cycle: CCC = DIO + DSO - ___.',
   '{}', '{"accepted":["dpo","days payables outstanding"]}', 'DPO is the days you take to pay suppliers, which reduces the time cash is tied up.',
   'Corporate Finance', 5),
  ('matching', 'Match each finance term to its meaning.',
   '{"left":["NPV","CCC","DSO","DPO"],"right":["Time to collect from customers","Value added after the required return","Time to pay suppliers","How long cash is tied up"]}',
   '{"mapping":{"NPV":"Value added after the required return","CCC":"How long cash is tied up","DSO":"Time to collect from customers","DPO":"Time to pay suppliers"}}',
   'NPV measures value added; the CCC measures cash tied up through DIO, DSO and DPO.',
   'Corporate Finance', 6),
  ('ordering', 'Put the steps for auditing a forecast into the correct order.',
   '{"items":["Test each assumption","List the inputs and assumptions","Label the forecast provisional","Check the data range used"]}',
   '{"order":["List the inputs and assumptions","Check the data range used","Test each assumption","Label the forecast provisional"]}',
   'Surface the assumptions, check the data range, test each assumption, then communicate the uncertainty.',
   'Financial Management for Small Businesses', 7),
  ('multiple_choice', 'What is the most responsible way to use an AI forecast you cannot fully audit?',
   '{"options":["Present it as a certainty","Label it provisional and state the unverified assumptions","Delete it without comment"]}',
   '{"answer_index":1}', 'Communicate the uncertainty and the gaps rather than implying false confidence.',
   'Financial Management for Small Businesses', 8),
  ('true_false', 'An AI forecast should be presented as a certainty when it looks precise.',
   '{}', '{"answer":false}', 'Precision is not accuracy. State the uncertainty and the assumptions behind the numbers.',
   'Financial Management for Small Businesses', 9),
  ('fill_blank', 'A project should be accepted when its NPV is ___.',
   '{}', '{"accepted":["positive","greater than zero","above zero"]}', 'A positive NPV means the project earns more than the required return.',
   'Corporate Finance', 10)
) AS v(type, prompt, payload, correct, explanation, source_title, sort_order)
WHERE l.code = 'finance-verify-a-forecast';

-- ---------------------------------------------------------------------------
-- legal-primary-sources
-- ---------------------------------------------------------------------------
DELETE FROM lab_activities WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'legal-primary-sources');
INSERT INTO lab_activities (lesson_id, type, prompt, payload, correct, explanation, source_id, sort_order)
SELECT l.id, v.type, v.prompt, v.payload::jsonb, v.correct::jsonb, v.explanation,
       (SELECT id FROM content_sources cs WHERE cs.title = v.source_title), v.sort_order
FROM lab_lessons l, (VALUES
  ('matching', 'Match each POPIA term to its meaning.',
   '{"left":["Responsible party","Operator","Data subject","Information Regulator"],"right":["Independent body that monitors and enforces POPIA","Decides why and how personal information is processed","The person the information relates to","Processes information on behalf of another"]}',
   '{"mapping":{"Responsible party":"Decides why and how personal information is processed","Operator":"Processes information on behalf of another","Data subject":"The person the information relates to","Information Regulator":"Independent body that monitors and enforces POPIA"}}',
   'These are the key roles in the Protection of Personal Information Act 4 of 2013. An app that decides why it collects data is usually the responsible party.',
   'South African legislation and court judgments', 1),
  ('multiple_choice', 'Which of these is primary law?',
   '{"options":["A blog summary of POPIA","The text of an Act as published","A law firm newsletter"]}',
   '{"answer_index":1}', 'The published Act is the primary source; the others are secondary commentary.',
   'South African legislation and court judgments', 2),
  ('true_false', 'Court judgments are copyrighted and cannot be quoted.',
   '{}', '{"answer":false}', 'Under s.12(8)(a) of the Copyright Act, no copyright subsists in official legal texts, including judgments.',
   'South African legislation and court judgments', 3),
  ('multiple_choice', 'Which of these is NOT one of the conditions for lawful processing under POPIA?',
   '{"options":["Accountability","Purpose specification","Profit maximisation","Security safeguards"]}',
   '{"answer_index":2}', 'POPIA lists eight conditions; profit maximisation is not one of them.',
   'South African legislation and court judgments', 4),
  ('true_false', 'Commentary and headnotes written by others about a judgment carry no copyright.',
   '{}', '{"answer":false}', 'The exemption covers the official text only. Commentary, summaries and headnotes are still protected.',
   'South African legislation and court judgments', 5),
  ('fill_blank', 'Under section ___ of the Copyright Act, no copyright subsists in official legal texts.',
   '{}', '{"accepted":["12(8)(a)","12","12(8)"]}', 'Section 12(8)(a) excludes copyright in official texts of a legislative, administrative or legal nature.',
   'South African legislation and court judgments', 6),
  ('ordering', 'Put the steps for relying on a provision into the correct order.',
   '{"items":["Quote the exact current wording","Find the primary text","Confirm it applies to the facts","Check for amendments"]}',
   '{"order":["Find the primary text","Check for amendments","Confirm it applies to the facts","Quote the exact current wording"]}',
   'Start from the primary text, confirm it is current, check it applies, then quote it exactly.',
   'South African legislation and court judgments', 7),
  ('multiple_choice', 'An AI paraphrases a statute. What must you confirm before relying on it?',
   '{"options":["The current wording of the provision","That the AI is expensive","The length of the paragraph"]}',
   '{"answer_index":0}', 'A paraphrase may differ from the wording; confirm the provision as it currently reads.',
   'South African legislation and court judgments', 8),
  ('matching', 'Match each item to whether it is primary or secondary legal material.',
   '{"left":["An Act as published","A court judgment","A headnote","A blog summary of a case"],"right":["Secondary","Primary","Primary","Secondary"]}',
   '{"mapping":{"An Act as published":"Primary","A court judgment":"Primary","A headnote":"Secondary","A blog summary of a case":"Secondary"}}',
   'Acts and judgments are primary; headnotes and summaries are secondary and may be wrong or out of date.',
   'South African legislation and court judgments', 9),
  ('true_false', 'A paraphrase of a section is authoritative even if it differs from the wording.',
   '{}', '{"answer":false}', 'Only the wording of the provision is authoritative; a paraphrase that differs is unreliable.',
   'South African legislation and court judgments', 10)
) AS v(type, prompt, payload, correct, explanation, source_title, sort_order)
WHERE l.code = 'legal-primary-sources';

-- ---------------------------------------------------------------------------
-- legal-ai-citation-check
-- ---------------------------------------------------------------------------
DELETE FROM lab_activities WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'legal-ai-citation-check');
INSERT INTO lab_activities (lesson_id, type, prompt, payload, correct, explanation, source_id, sort_order)
SELECT l.id, v.type, v.prompt, v.payload::jsonb, v.correct::jsonb, v.explanation,
       (SELECT id FROM content_sources cs WHERE cs.title = v.source_title), v.sort_order
FROM lab_lessons l, (VALUES
  ('multiple_choice', 'A company believes an unauthorised person accessed personal information it holds. Who must it notify under POPIA section 22?',
   '{"options":["Nobody unless a court orders it","Only the Information Regulator","The Information Regulator and the affected data subjects","Only the police"]}',
   '{"answer_index":2}', 'The responsible party must notify the Regulator and the affected data subjects as soon as reasonably possible.',
   'South African legislation and court judgments', 1),
  ('multiple_choice', 'Under the Consumer Protection Act 68 of 2008, within what period can a consumer return goods that fail the implied warranty of quality?',
   '{"options":["5 business days","30 days","6 months","12 months"]}',
   '{"answer_index":2}', 'Section 56 gives six months from delivery, and the consumer chooses repair, replacement or refund.',
   'South African legislation and court judgments', 2),
  ('multiple_choice', 'Under the Companies Act 71 of 2008, what is the legal status of a company?',
   '{"options":["A juristic person with its own legal existence","An extension of its directors","A partnership between shareholders","A legal entity only until its first annual return"]}',
   '{"answer_index":0}', 'A company is a juristic person: it can own property and be sued in its own name, separate from its shareholders and directors.',
   'South African legislation and court judgments', 3),
  ('true_false', 'An AI citation is proof of the law unless it looks wrong.',
   '{}', '{"answer":false}', 'A citation is a claim, not proof. Confirm the authority exists, is current, and supports the proposition.',
   'South African legislation and court judgments', 4),
  ('fill_blank', 'POPIA requires notification of a security compromise to the Information ___.',
   '{}', '{"accepted":["regulator","information regulator"]}', 'The responsible party notifies the Information Regulator (and affected data subjects where their identity can be established).',
   'South African legislation and court judgments', 5),
  ('matching', 'Match each AI claim to the check it needs.',
   '{"left":["Case X bans Y","Section 56 gives six months","A company is a juristic person"],"right":["Confirm Companies Act s.19","Confirm the case exists and says so","Confirm the current wording of s.56"]}',
   '{"mapping":{"Case X bans Y":"Confirm the case exists and says so","Section 56 gives six months":"Confirm the current wording of s.56","A company is a juristic person":"Confirm Companies Act s.19"}}',
   'Each claim must be checked against the primary authority that supports it.',
   'South African legislation and court judgments', 6),
  ('ordering', 'Put the steps for verifying an AI citation into the correct order.',
   '{"items":["Confirm it supports the proposition","Locate the authority on SAFLII","Confirm it is current","Confirm it exists"]}',
   '{"order":["Locate the authority on SAFLII","Confirm it exists","Confirm it is current","Confirm it supports the proposition"]}',
   'Locate, confirm existence, confirm currency, then confirm it supports the claim.',
   'South African legislation and court judgments', 7),
  ('true_false', 'A provision that was amended after the AI was trained may be stated incorrectly.',
   '{}', '{"answer":true}', 'AI training data ages; the provision must be checked against its current wording.',
   'South African legislation and court judgments', 8),
  ('multiple_choice', 'A judgment an AI cites was overturned. What should you do?',
   '{"options":["Cite it anyway","Use the current authority instead","Assume it still applies"]}',
   '{"answer_index":1}', 'Authority is only authority if it is current; rely on the position after the appeal.',
   'South African legislation and court judgments', 9),
  ('fill_blank', 'A company is a ___ person with its own legal existence.',
   '{}', '{"accepted":["juristic"]}', 'Companies Act s.19 makes a company a juristic person, separate from its shareholders and directors.',
   'South African legislation and court judgments', 10)
) AS v(type, prompt, payload, correct, explanation, source_title, sort_order)
WHERE l.code = 'legal-ai-citation-check';

-- ---------------------------------------------------------------------------
-- it-verify-generated-code
-- ---------------------------------------------------------------------------
DELETE FROM lab_activities WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'it-verify-generated-code');
INSERT INTO lab_activities (lesson_id, type, prompt, payload, correct, explanation, source_id, sort_order)
SELECT l.id, v.type, v.prompt, v.payload::jsonb, v.correct::jsonb, v.explanation,
       (SELECT id FROM content_sources cs WHERE cs.title = v.source_title), v.sort_order
FROM lab_lessons l, (VALUES
  ('multiple_choice', 'What is the primary defence against SQL injection?',
   '{"options":["Parameterised queries (prepared statements)","Hiding database error messages only","Using a longer database password","Serving the app over HTTPS"]}',
   '{"answer_index":0}', 'Parameterised queries keep user input as data, so it can never be run as SQL.',
   'OWASP Cheat Sheet Series', 1),
  ('multiple_choice', 'How should an app store user passwords?',
   '{"options":["Encrypted with the key in the source code","Hashed with a fast unsalted algorithm such as MD5","Hashed with a salted, slow algorithm such as Argon2id or bcrypt","In plain text in a protected database"]}',
   '{"answer_index":2}', 'Slow, salted hashes make stolen password databases expensive to crack; plain text and reversible encryption expose every password.',
   'OWASP Cheat Sheet Series', 2),
  ('true_false', 'Validating user input in the mobile app alone is enough to keep the backend safe.',
   '{}', '{"answer":false}', 'Attackers can call the API directly and skip the app, so the server must validate every input itself.',
   'OWASP Cheat Sheet Series', 3),
  ('multiple_choice', 'A model scores very high on its training data but poorly on new data. What is this called?',
   '{"options":["Overfitting","Underfitting","Regularisation","Normalisation"]}',
   '{"answer_index":0}', 'An overfit model has memorised the training data, including noise, instead of learning patterns that generalise.',
   'Dive into Deep Learning', 4),
  ('multiple_choice', 'Which dataset should be used only once, at the very end, to estimate final performance on unseen data?',
   '{"options":["Training set","Validation set","Test set","Any of the above"]}',
   '{"answer_index":2}', 'The validation set is for tuning. If you tune on the test set, its score is no longer an honest estimate.',
   'Dive into Deep Learning', 5),
  ('matching', 'Match each risk to the control that addresses it.',
   '{"left":["SQL injection","Weak password storage","Client-only validation","Secrets in source code"],"right":["Store secrets in a secret manager","Parameterised queries","Salted slow password hashing","Validate on the server"]}',
   '{"mapping":{"SQL injection":"Parameterised queries","Weak password storage":"Salted slow password hashing","Client-only validation":"Validate on the server","Secrets in source code":"Store secrets in a secret manager"}}',
   'Each control targets a specific weakness in generated code.',
   'OWASP Cheat Sheet Series', 6),
  ('fill_blank', 'Password hashes should be slow and ___.',
   '{}', '{"accepted":["salted","salted with a unique salt"]}', 'A unique salt per password defeats precomputed rainbow-table attacks.',
   'OWASP Cheat Sheet Series', 7),
  ('ordering', 'Put the steps for reviewing generated code into the correct order.',
   '{"items":["Run edge-case tests","Read the code","Merge","Focus on auth and validation paths"]}',
   '{"order":["Read the code","Focus on auth and validation paths","Run edge-case tests","Merge"]}',
   'Read it, focus on the risky paths, test the edges, then merge.',
   'OWASP Cheat Sheet Series', 8),
  ('true_false', 'AI-written code usually anticipates adversarial inputs.',
   '{}', '{"answer":false}', 'Generated code rarely anticipates hostile inputs; test the empty, oversized and malicious cases yourself.',
   'OWASP Cheat Sheet Series', 9),
  ('true_false', 'A model that memorises training noise instead of general patterns is overfitting.',
   '{}', '{"answer":true}', 'Overfitting means it fails to generalise to unseen data.',
   'Dive into Deep Learning', 10)
) AS v(type, prompt, payload, correct, explanation, source_title, sort_order)
WHERE l.code = 'it-verify-generated-code';

-- ---------------------------------------------------------------------------
-- it-model-limits
-- ---------------------------------------------------------------------------
DELETE FROM lab_activities WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'it-model-limits');
INSERT INTO lab_activities (lesson_id, type, prompt, payload, correct, explanation, source_id, sort_order)
SELECT l.id, v.type, v.prompt, v.payload::jsonb, v.correct::jsonb, v.explanation,
       (SELECT id FROM content_sources cs WHERE cs.title = v.source_title), v.sort_order
FROM lab_lessons l, (VALUES
  ('true_false', 'A fluent, confident model answer is evidence that it is correct.',
   '{}', '{"answer":false}', 'Fluency describes the text, not the truth of the claim.',
   'Dive into Deep Learning', 1),
  ('multiple_choice', 'Live data drifts away from the data a model was trained on. What is the effect?',
   '{"options":["Nothing changes","Model performance can silently degrade","The model retrains itself"]}',
   '{"answer_index":1}', 'Distribution shift degrades performance, usually without any error being raised.',
   'Dive into Deep Learning', 2),
  ('fill_blank', 'When live data differs from training data, this is called distribution ___.',
   '{}', '{"accepted":["shift"]}', 'Distribution shift is a common cause of silent model degradation.',
   'Dive into Deep Learning', 3),
  ('matching', 'Match each term to its meaning.',
   '{"left":["Overfitting","Validation set","Test set","Distribution shift"],"right":["Live data differs from training data","Final honest performance estimate","Memorising training noise","Tuning and model selection"]}',
   '{"mapping":{"Overfitting":"Memorising training noise","Validation set":"Tuning and model selection","Test set":"Final honest performance estimate","Distribution shift":"Live data differs from training data"}}',
   'Keeping the three data splits distinct preserves honest evaluation.',
   'Dive into Deep Learning', 4),
  ('multiple_choice', 'Which data split is used for tuning and model selection?',
   '{"options":["Training set","Validation set","Test set","None"]}',
   '{"answer_index":1}', 'The validation set is for tuning; the test set is reserved for the final estimate.',
   'Dive into Deep Learning', 5),
  ('true_false', 'A deployed model retrains itself automatically when the world changes.',
   '{}', '{"answer":false}', 'Models do not retrain themselves; someone must monitor for drift and re-evaluate.',
   'Dive into Deep Learning', 6),
  ('ordering', 'Put the model evaluation steps in the correct order.',
   '{"items":["Report on the test set","Split the data","Tune on the validation set","Train on the training set"]}',
   '{"order":["Split the data","Train on the training set","Tune on the validation set","Report on the test set"]}',
   'Split first, train, tune on validation, then report once on the test set.',
   'Dive into Deep Learning', 7),
  ('multiple_choice', 'Why is overfitting a problem in practice?',
   '{"options":["It slows the model down","It fails to generalise to unseen data","It uses too much memory"]}',
   '{"answer_index":1}', 'An overfit model looks great on training data but performs poorly on new data.',
   'Dive into Deep Learning', 8),
  ('fill_blank', 'Tuning on the test set makes its score no longer an ___ estimate.',
   '{}', '{"accepted":["honest","unbiased","independent"]}', 'Once the test set informs tuning, it can no longer give an independent estimate.',
   'Dive into Deep Learning', 9),
  ('true_false', 'Fluency is a property of the text, not a correctness signal.',
   '{}', '{"answer":true}', 'Models produce likely continuations; confident wording is not evidence of truth.',
   'Dive into Deep Learning', 10)
) AS v(type, prompt, payload, correct, explanation, source_title, sort_order)
WHERE l.code = 'it-model-limits';

-- ---------------------------------------------------------------------------
-- business-ai-in-decisions (original)
-- ---------------------------------------------------------------------------
DELETE FROM lab_activities WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'business-ai-in-decisions');
INSERT INTO lab_activities (lesson_id, type, prompt, payload, correct, explanation, source_id, sort_order)
SELECT l.id, v.type, v.prompt, v.payload::jsonb, v.correct::jsonb, v.explanation,
       (SELECT id FROM content_sources cs WHERE cs.title = v.source_title), v.sort_order
FROM lab_lessons l, (VALUES
  ('multiple_choice', 'An AI recommends a hiring decision. Who is accountable for the outcome?',
   '{"options":["The model vendor","The accountable person who decides to act","No one, because a model decided"]}',
   '{"answer_index":1}', 'A human owns the decision; the model only advises.',
   NULL, 1),
  ('true_false', 'A model can be the accountable owner of a business decision.',
   '{}', '{"answer":false}', 'Accountability rests with a person, not a tool.',
   NULL, 2),
  ('ordering', 'Put the steps for governing an AI-assisted decision into the correct order.',
   '{"items":["Record the evidence used","Define the decision","Decide and review","Identify the accountable person"]}',
   '{"order":["Define the decision","Identify the accountable person","Record the evidence used","Decide and review"]}',
   'Define the decision, name the owner, record the evidence, then decide and review.',
   NULL, 3),
  ('matching', 'Match each term to its meaning.',
   '{"left":["Accountable owner","Reversible decision","Evidence","Ungoverned decision"],"right":["Basis for the decision","No one accountable","Decides and records why","Can be reviewed and corrected"]}',
   '{"mapping":{"Accountable owner":"Decides and records why","Reversible decision":"Can be reviewed and corrected","Evidence":"Basis for the decision","Ungoverned decision":"No one accountable"}}',
   'Governance needs a named owner and a record; reversible decisions are safer.',
   NULL, 4),
  ('multiple_choice', 'Which decision is riskier to make on an unaudited model output?',
   '{"options":["A reversible one you can review later","An irreversible one with no documented evidence","One reviewed by a person"]}',
   '{"answer_index":1}', 'Irreversible decisions with no evidence leave no way to catch or correct harm.',
   NULL, 5),
  ('fill_blank', 'A model can recommend, but an accountable ___ decides.',
   '{}', '{"accepted":["person","human"]}', 'Accountability sits with a person, not the model.',
   NULL, 6),
  ('true_false', 'Recording why a decision was made is optional.',
   '{}', '{"answer":false}', 'Without a record there is no basis to review or defend the decision.',
   NULL, 7),
  ('multiple_choice', 'What makes a decision ungoverned?',
   '{"options":["It used an AI tool","It has no accountable owner","It was made quickly"]}',
   '{"answer_index":1}', 'If no one owns the outcome, the decision is ungoverned.',
   NULL, 8),
  ('true_false', 'Preferring reversible decisions reduces risk.',
   '{}', '{"answer":true}', 'A reversible decision can be reviewed and corrected if the model turned out to be wrong.',
   NULL, 9),
  ('fill_blank', 'Document the ___ used to make an AI-assisted decision.',
   '{}', '{"accepted":["evidence","rationale","reasoning"]}', 'The record should show what evidence supported the decision.',
   NULL, 10)
) AS v(type, prompt, payload, correct, explanation, source_title, sort_order)
WHERE l.code = 'business-ai-in-decisions';

-- ---------------------------------------------------------------------------
-- business-stakeholder-risk (original)
-- ---------------------------------------------------------------------------
DELETE FROM lab_activities WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'business-stakeholder-risk');
INSERT INTO lab_activities (lesson_id, type, prompt, payload, correct, explanation, source_id, sort_order)
SELECT l.id, v.type, v.prompt, v.payload::jsonb, v.correct::jsonb, v.explanation,
       (SELECT id FROM content_sources cs WHERE cs.title = v.source_title), v.sort_order
FROM lab_lessons l, (VALUES
  ('multiple_choice', 'Who should be included in a stakeholder map for an AI tool?',
   '{"options":["Only the direct users of the tool","Everyone affected, including indirect groups","Only the project sponsor"]}',
   '{"answer_index":1}', 'Indirectly affected people often carry the risk and must be considered.',
   NULL, 1),
  ('true_false', 'Only the direct users of a tool are stakeholders.',
   '{}', '{"answer":false}', 'People who never touch the tool can still be affected by its outcomes.',
   NULL, 2),
  ('multiple_choice', 'What is the best first check for unfair outcomes?',
   '{"options":["Assume the model is neutral","Measure outcomes across relevant groups","Increase the model temperature"]}',
   '{"answer_index":1}', 'Fairness is measured by outcomes across groups, not assumed.',
   NULL, 3),
  ('matching', 'Match each group to what to consider.',
   '{"left":["Direct users","Indirectly affected people","Model vendor","Regulator"],"right":["Compliance requirements","Usability and direct harm","Data handling terms","Often carry the risk"]}',
   '{"mapping":{"Direct users":"Usability and direct harm","Indirectly affected people":"Often carry the risk","Model vendor":"Data handling terms","Regulator":"Compliance requirements"}}',
   'A complete map covers users, the indirectly affected, the vendor and the regulator.',
   NULL, 4),
  ('ordering', 'Put the risk-mapping steps in the correct order.',
   '{"items":["Assign an owner","List affected groups","Choose a check for each risk","Assess how each group is affected"]}',
   '{"order":["List affected groups","Assess how each group is affected","Choose a check for each risk","Assign an owner"]}',
   'List, assess, choose checks, then assign ownership.',
   NULL, 5),
  ('fill_blank', 'Fairness is measured by outcomes across ___.',
   '{}', '{"accepted":["groups","relevant groups"]}', 'Compare outcomes between groups to detect unfairness.',
   NULL, 6),
  ('true_false', 'A model can reproduce and amplify an existing gap in the data.',
   '{}', '{"answer":true}', 'If data under-represents a group, the model reproduces and can amplify the gap.',
   NULL, 7),
  ('multiple_choice', 'Why include indirectly affected people in the map?',
   '{"options":["They pay for the tool","They often carry the risk","They wrote the data"]}',
   '{"answer_index":1}', 'Indirectly affected people can bear the harm even though they never use the tool.',
   NULL, 8),
  ('true_false', 'High model accuracy means the model is fair.',
   '{}', '{"answer":false}', 'A model can be accurate overall yet unfair to a specific group.',
   NULL, 9),
  ('fill_blank', 'A ___ impact check compares outcomes across groups.',
   '{}', '{"accepted":["disparate","disparate impact"]}', 'Disparate-impact checks surface unfairness that overall accuracy hides.',
   NULL, 10)
) AS v(type, prompt, payload, correct, explanation, source_title, sort_order)
WHERE l.code = 'business-stakeholder-risk';

-- ---------------------------------------------------------------------------
-- risk-ai-governance-nist
-- ---------------------------------------------------------------------------
DELETE FROM lab_activities WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'risk-ai-governance-nist');
INSERT INTO lab_activities (lesson_id, type, prompt, payload, correct, explanation, source_id, sort_order)
SELECT l.id, v.type, v.prompt, v.payload::jsonb, v.correct::jsonb, v.explanation,
       (SELECT id FROM content_sources cs WHERE cs.title = v.source_title), v.sort_order
FROM lab_lessons l, (VALUES
  ('multiple_choice', 'A risk-based approach to AI starts from which question?',
   '{"options":["Which model is most advanced?","What is the use case and who could be harmed?","How fast can we ship?"]}',
   '{"answer_index":1}', 'Risk is a property of the use case and its context, not the model alone.',
   'NIST AI Risk Management Framework', 1),
  ('true_false', 'The same model always carries the same risk regardless of context.',
   '{}', '{"answer":false}', 'The same model can be low-risk in one context and high-risk in another.',
   'NIST AI Risk Management Framework', 2),
  ('ordering', 'Put the risk-management flow in the correct order.',
   '{"items":["Manage: assign controls and owners","Map: identify context and risks","Document and review","Measure: assess severity"]}',
   '{"order":["Map: identify context and risks","Measure: assess severity","Manage: assign controls and owners","Document and review"]}',
   'Map the context, measure the risks, manage with controls, then document and review.',
   'NIST AI Risk Management Framework', 3),
  ('matching', 'Match each function to what it means.',
   '{"left":["Map","Measure","Manage","Document"],"right":["Assign controls and owners","Identify context and risks","Record and review","Assess severity"]}',
   '{"mapping":{"Map":"Identify context and risks","Measure":"Assess severity","Manage":"Assign controls and owners","Document":"Record and review"}}',
   'The map-measure-manage functions, with documentation throughout.',
   'NIST AI Risk Management Framework', 4),
  ('fill_blank', 'Risk is a property of the use case and its ___.',
   '{}', '{"accepted":["context"]}', 'The context determines how serious a risk is.',
   'NIST AI Risk Management Framework', 5),
  ('multiple_choice', 'After identifying and assessing risks, what comes next?',
   '{"options":["Ignore them","Assign controls and named owners and document","Increase the temperature"]}',
   '{"answer_index":1}', 'Managing risk means controls, ownership and a written record that is reviewed over time.',
   'NIST AI Risk Management Framework', 6),
  ('true_false', 'A governance record should be reviewed as the system changes.',
   '{}', '{"answer":true}', 'The assessment is kept current as the system, data or world changes.',
   'NIST AI Risk Management Framework', 7),
  ('multiple_choice', 'What should drive how an AI system is governed?',
   '{"options":["The marketing plan","The use case and its potential harms","The model size"]}',
   '{"answer_index":1}', 'Governance follows the use case and its risks, not the tool or its size.',
   'NIST AI Risk Management Framework', 8),
  ('fill_blank', 'Managing risk means controls, ownership and a written ___.',
   '{}', '{"accepted":["record","register"]}', 'A written record makes governance reviewable.',
   'NIST AI Risk Management Framework', 9),
  ('true_false', 'Risk management is a one-time task.',
   '{}', '{"answer":false}', 'Risk management is continuous: document, monitor and review as things change.',
   'NIST AI Risk Management Framework', 10)
) AS v(type, prompt, payload, correct, explanation, source_title, sort_order)
WHERE l.code = 'risk-ai-governance-nist';
