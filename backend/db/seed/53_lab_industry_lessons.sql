-- VerifAI AI Lab — per-industry lessons (original text; adapted only from
-- CC BY / public-domain sources). Idempotent: lessons upsert by code, child
-- rows are replaced, source links upsert.

-- ---------------------------------------------------------------------------
-- FINANCE
-- ---------------------------------------------------------------------------
INSERT INTO lab_lessons (code, track_id, title, summary, estimated_minutes, level, is_original, competency, sort_order)
VALUES
  ('finance-read-the-numbers', (SELECT id FROM industry_tracks WHERE name = 'Finance'),
   'Reading AI-written financial summaries critically',
   'Treat an AI-written financial summary as a draft: trace each number to a source and a date before you rely on it.',
   8, 1, FALSE, 'Verification', 110),
  ('finance-verify-a-forecast', (SELECT id FROM industry_tracks WHERE name = 'Finance'),
   'Verifying an AI revenue forecast',
   'Audit the assumptions behind an AI revenue forecast before you act on it.',
   7, 1, FALSE, 'AI Judgement', 120)
ON CONFLICT (code) DO UPDATE SET
  track_id = EXCLUDED.track_id, title = EXCLUDED.title, summary = EXCLUDED.summary,
  estimated_minutes = EXCLUDED.estimated_minutes, level = EXCLUDED.level,
  competency = EXCLUDED.competency, sort_order = EXCLUDED.sort_order;

DELETE FROM lab_lesson_sections WHERE lesson_id IN (SELECT id FROM lab_lessons WHERE code IN ('finance-read-the-numbers', 'finance-verify-a-forecast'));
INSERT INTO lab_lesson_sections (lesson_id, heading, body, sort_order)
SELECT l.id, v.heading, v.body, v.sort_order
FROM lab_lessons l, (VALUES
  ('finance-read-the-numbers', 'What the summary leaves out',
   'An AI summary often drops the reporting period, the currency and whether a figure is audited or an estimate. Before trusting a number, find where it came from and when it applies.', 1),
  ('finance-read-the-numbers', 'A ratio needs a benchmark',
   'Liquidity, leverage and profitability ratios only mean something next to a comparison - a prior period, a peer or a target. A ratio on its own is a bare number, not a conclusion.', 2),
  ('finance-read-the-numbers', 'A rand today is not a rand next year',
   'Any figure that spans time must state its discount rate and period, or the comparison is meaningless. Value, not just count.', 3),
  ('finance-verify-a-forecast', 'The assumptions are the forecast',
   'A forecast is only as good as its inputs. List them explicitly: the growth rate, the cost base, the market size and the exact data range used.', 1),
  ('finance-verify-a-forecast', 'When the input is stale',
   'A model projecting forward from last year''s data misses structural change. Ask what has happened since the data ends - a new entrant, a rate change, a supply shock.', 2)
) AS v(code, heading, body, sort_order)
WHERE l.code = v.code;

DELETE FROM lab_questions WHERE lesson_id IN (SELECT id FROM lab_lessons WHERE code IN ('finance-read-the-numbers', 'finance-verify-a-forecast'));
INSERT INTO lab_questions (lesson_id, prompt, options, correct_index, explanation, sort_order)
SELECT l.id, v.prompt, v.options::jsonb, v.correct_index, v.explanation, v.sort_order
FROM lab_lessons l, (VALUES
  ('finance-read-the-numbers', 'An AI summary states "profit up 12%" with no period or source. What is the responsible first step?',
   '["Accept it - it is a specific number","Find the reporting period and source before relying on it","Round it to the nearest whole number"]', 1,
   'A number without a period and source cannot be verified. Locate both first.', 1),
  ('finance-read-the-numbers', 'Which comparison is safe to make without adjustment?',
   '["Cash today versus cash in three years","Two figures from the same period and currency","Last year''s rand versus this year''s with no inflation note"]', 1,
   'Figures from the same period and currency are directly comparable; the others need a time-value adjustment.', 2),
  ('finance-verify-a-forecast', 'A forecast is built on data that ends before a major new competitor entered the market. What does that most affect?',
   '["The font of the report","The validity of the growth assumption","Nothing - forecasts are always accurate"]', 1,
   'Stale inputs invalidate the growth assumption, which drives the whole forecast.', 1),
  ('finance-verify-a-forecast', 'What is the most responsible way to use an AI forecast you cannot fully audit?',
   '["Present it as a certainty","Label it provisional and state the unverified assumptions","Delete it without comment"]', 1,
   'Communicate the uncertainty and the gaps rather than implying false confidence.', 2)
) AS v(code, prompt, options, correct_index, explanation, sort_order)
WHERE l.code = v.code;

-- ---------------------------------------------------------------------------
-- LEGAL
-- ---------------------------------------------------------------------------
INSERT INTO lab_lessons (code, track_id, title, summary, estimated_minutes, level, is_original, competency, sort_order)
VALUES
  ('legal-primary-sources', (SELECT id FROM industry_tracks WHERE name = 'Legal'),
   'Working from South African primary law',
   'Work from primary law - the Act, regulation or judgment itself - not from a summary of it.',
   8, 1, FALSE, 'Verification', 110),
  ('legal-ai-citation-check', (SELECT id FROM industry_tracks WHERE name = 'Legal'),
   'Checking an AI-cited authority',
   'Verify an authority an AI cites before you rely on it.',
   7, 1, FALSE, 'AI Judgement', 120)
ON CONFLICT (code) DO UPDATE SET
  track_id = EXCLUDED.track_id, title = EXCLUDED.title, summary = EXCLUDED.summary,
  estimated_minutes = EXCLUDED.estimated_minutes, level = EXCLUDED.level,
  competency = EXCLUDED.competency, sort_order = EXCLUDED.sort_order;

DELETE FROM lab_lesson_sections WHERE lesson_id IN (SELECT id FROM lab_lessons WHERE code IN ('legal-primary-sources', 'legal-ai-citation-check'));
INSERT INTO lab_lesson_sections (lesson_id, heading, body, sort_order)
SELECT l.id, v.heading, v.body, v.sort_order
FROM lab_lessons l, (VALUES
  ('legal-primary-sources', 'Primary versus secondary',
   'The Act and the judgment are the law. A summary, a commentary or a headnote is someone''s reading of it, and may be wrong or out of date.', 1),
  ('legal-primary-sources', 'Official texts carry no copyright',
   'Under section 12(8)(a) of the Copyright Act, no copyright subsists in official texts of a legislative, administrative or legal nature. You may quote the Act or a judgment; commentary and headnotes written by others are still protected.', 2),
  ('legal-primary-sources', 'Read the provision, not the paraphrase',
   'Confirm the current wording and any amendments before you rely on a paraphrase. Law changes.', 3),
  ('legal-ai-citation-check', 'A citation is a lead, not proof',
   'An AI citation is a claim. Confirm the case or Act exists, that it is in force, and that it says what the AI claims it says.', 1),
  ('legal-ai-citation-check', 'Currency and context',
   'Check that a provision has not been amended and a judgment has not been overturned or distinguished. Authority is only authority if it is current and on point.', 2)
) AS v(code, heading, body, sort_order)
WHERE l.code = v.code;

DELETE FROM lab_questions WHERE lesson_id IN (SELECT id FROM lab_lessons WHERE code IN ('legal-primary-sources', 'legal-ai-citation-check'));
INSERT INTO lab_questions (lesson_id, prompt, options, correct_index, explanation, sort_order)
SELECT l.id, v.prompt, v.options::jsonb, v.correct_index, v.explanation, v.sort_order
FROM lab_lessons l, (VALUES
  ('legal-primary-sources', 'Which of these is primary law?',
   '["A blog summary of POPIA","The text of an Act as published","A law firm''s newsletter"]', 1,
   'The published Act is the primary source; the others are secondary commentary.', 1),
  ('legal-primary-sources', 'You want to quote a judgment. Does copyright prevent it?',
   '["Yes, all judgments are copyrighted","No - official legal texts carry no copyright","Only if you quote more than 50 words"]', 1,
   'Section 12(8)(a) of the Copyright Act excludes copyright in official legal texts; commentary about them may still be protected.', 2),
  ('legal-ai-citation-check', 'An AI confidently cites a case. What should you do before relying on it?',
   '["Cite it as given - the AI sounds sure","Confirm it exists and supports the proposition","Assume it is current"]', 1,
   'Confirm existence, currency and relevance from the primary source before relying on it.', 1),
  ('legal-ai-citation-check', 'A cited provision was amended after the AI was trained. What is the risk?',
   '["None - wording does not change","The AI may state law that is no longer in force","The citation becomes public domain"]', 1,
   'AI training data ages; the provision must be checked against its current wording.', 2)
) AS v(code, prompt, options, correct_index, explanation, sort_order)
WHERE l.code = v.code;

-- ---------------------------------------------------------------------------
-- IT / SOFTWARE
-- ---------------------------------------------------------------------------
INSERT INTO lab_lessons (code, track_id, title, summary, estimated_minutes, level, is_original, competency, sort_order)
VALUES
  ('it-verify-generated-code', (SELECT id FROM industry_tracks WHERE name = 'IT / Software'),
   'Verifying AI-generated code for security flaws',
   'Treat generated code as a proposal and check the security-sensitive paths before merging.',
   10, 1, TRUE, 'Verification', 110),
  ('it-model-limits', (SELECT id FROM industry_tracks WHERE name = 'IT / Software'),
   'Understanding model limits',
   'Know what a model does and does not guarantee before you depend on it.',
   8, 1, TRUE, 'Risk & Governance', 120)
ON CONFLICT (code) DO UPDATE SET
  track_id = EXCLUDED.track_id, title = EXCLUDED.title, summary = EXCLUDED.summary,
  estimated_minutes = EXCLUDED.estimated_minutes, level = EXCLUDED.level,
  competency = EXCLUDED.competency, sort_order = EXCLUDED.sort_order;

DELETE FROM lab_lesson_sections WHERE lesson_id IN (SELECT id FROM lab_lessons WHERE code IN ('it-verify-generated-code', 'it-model-limits'));
INSERT INTO lab_lesson_sections (lesson_id, heading, body, sort_order)
SELECT l.id, v.heading, v.body, v.sort_order
FROM lab_lessons l, (VALUES
  ('it-verify-generated-code', 'Read for security, not style',
   'Generated code is usually plausible. The failures that matter cluster in input validation, authentication, authorisation and secrets handling.', 1),
  ('it-verify-generated-code', 'Test the edges',
   'Run tests for empty, oversized and hostile inputs before merging. AI-written code rarely anticipates the adversarial case.', 2),
  ('it-model-limits', 'Predicting text, not truth',
   'A model produces likely continuations, not verified facts. Fluency is not a correctness signal.', 1),
  ('it-model-limits', 'Distribution shift',
   'Performance degrades when live data differs from training data. Monitor for drift and re-evaluate when the world changes.', 2)
) AS v(code, heading, body, sort_order)
WHERE l.code = v.code;

DELETE FROM lab_questions WHERE lesson_id IN (SELECT id FROM lab_lessons WHERE code IN ('it-verify-generated-code', 'it-model-limits'));
INSERT INTO lab_questions (lesson_id, prompt, options, correct_index, explanation, sort_order)
SELECT l.id, v.prompt, v.options::jsonb, v.correct_index, v.explanation, v.sort_order
FROM lab_lessons l, (VALUES
  ('it-verify-generated-code', 'Where is AI-generated code most likely to hide a security flaw?',
   '["In its comments","In input validation and auth paths","In its formatting"]', 1,
   'Validation, authentication and authorisation are the highest-risk paths in generated code.', 1),
  ('it-verify-generated-code', 'What is the responsible step before merging generated code that touches authentication?',
   '["Merge because it compiles","Review the security-sensitive paths and run edge-case tests","Remove the tests to ship faster"]', 1,
   'Read the security paths and test the edges before it reaches users.', 2),
  ('it-model-limits', 'A model answers fluently and confidently. What does that tell you?',
   '["It is correct","Nothing about correctness","It verified its own answer"]', 1,
   'Fluency describes the text, not the truth of the claim.', 1),
  ('it-model-limits', 'What happens when live data drifts from the training data?',
   '["Nothing","Model performance can silently degrade","The model retrains itself"]', 1,
   'Distribution shift degrades performance; it must be monitored and re-evaluated.', 2)
) AS v(code, prompt, options, correct_index, explanation, sort_order)
WHERE l.code = v.code;

-- ---------------------------------------------------------------------------
-- BUSINESS CONSULTING (original - OpenStax dropped)
-- ---------------------------------------------------------------------------
INSERT INTO lab_lessons (code, track_id, title, summary, estimated_minutes, level, is_original, competency, sort_order)
VALUES
  ('business-ai-in-decisions', (SELECT id FROM industry_tracks WHERE name = 'Business Consulting'),
   'AI-assisted decisions and accountability',
   'Keep a human accountable for any decision an AI assists.',
   8, 1, TRUE, 'AI Judgement', 110),
  ('business-stakeholder-risk', (SELECT id FROM industry_tracks WHERE name = 'Business Consulting'),
   'Stakeholder and risk mapping for AI use',
   'Map who is affected and how before deploying an AI tool.',
   7, 1, TRUE, 'Risk & Governance', 120)
ON CONFLICT (code) DO UPDATE SET
  track_id = EXCLUDED.track_id, title = EXCLUDED.title, summary = EXCLUDED.summary,
  estimated_minutes = EXCLUDED.estimated_minutes, level = EXCLUDED.level,
  competency = EXCLUDED.competency, sort_order = EXCLUDED.sort_order;

DELETE FROM lab_lesson_sections WHERE lesson_id IN (SELECT id FROM lab_lessons WHERE code IN ('business-ai-in-decisions', 'business-stakeholder-risk'));
INSERT INTO lab_lesson_sections (lesson_id, heading, body, sort_order)
SELECT l.id, v.heading, v.body, v.sort_order
FROM lab_lessons l, (VALUES
  ('business-ai-in-decisions', 'Who decides',
   'A model can recommend; an accountable person decides and records why. If no one owns the outcome, the decision is ungoverned.', 1),
  ('business-ai-in-decisions', 'Evidence and reversibility',
   'Prefer decisions you can reverse, and record the evidence used. An irreversible decision made on an unaudited model output is a governance failure.', 2),
  ('business-stakeholder-risk', 'Map the affected',
   'Before deploying, list who is affected and how, including people who never interact with the tool directly.', 1),
  ('business-stakeholder-risk', 'Watch for disparate impact',
   'Check outcomes across groups. A model can reproduce and amplify an existing gap in the data.', 2)
) AS v(code, heading, body, sort_order)
WHERE l.code = v.code;

DELETE FROM lab_questions WHERE lesson_id IN (SELECT id FROM lab_lessons WHERE code IN ('business-ai-in-decisions', 'business-stakeholder-risk'));
INSERT INTO lab_questions (lesson_id, prompt, options, correct_index, explanation, sort_order)
SELECT l.id, v.prompt, v.options::jsonb, v.correct_index, v.explanation, v.sort_order
FROM lab_lessons l, (VALUES
  ('business-ai-in-decisions', 'An AI recommends a hiring decision. Who is accountable for the outcome?',
   '["The model vendor","The accountable person who decides to act","No one"]', 1,
   'A human owns the decision; the model only advises.', 1),
  ('business-ai-in-decisions', 'Which decision is riskier to make on an unaudited model output?',
   '["A reversible one you can review later","An irreversible one with no documented evidence","One reviewed by a person"]', 1,
   'Irreversible decisions with no evidence leave no way to catch or correct harm.', 2),
  ('business-stakeholder-risk', 'Who should be in a stakeholder map?',
   '["Only direct users of the tool","Everyone affected, including indirect groups","Only the project sponsor"]', 1,
   'Indirectly affected people often carry the risk and must be considered.', 1),
  ('business-stakeholder-risk', 'What is the best first check for unfair outcomes?',
   '["Assume the model is neutral","Measure outcomes across relevant groups","Raise the model temperature"]', 1,
   'Fairness is measured by outcomes across groups, not assumed.', 2)
) AS v(code, prompt, options, correct_index, explanation, sort_order)
WHERE l.code = v.code;

-- ---------------------------------------------------------------------------
-- CROSS-INDUSTRY (NIST AI RMF, public domain - adapted)
-- ---------------------------------------------------------------------------
INSERT INTO lab_lessons (code, track_id, title, summary, estimated_minutes, level, is_original, competency, sort_order)
VALUES
  ('risk-ai-governance-nist', NULL,
   'A risk-based approach to AI governance',
   'Govern AI by risk: map the context, measure the risks, manage them, and document the result.',
   10, 2, FALSE, 'Risk & Governance', 200)
ON CONFLICT (code) DO UPDATE SET
  title = EXCLUDED.title, summary = EXCLUDED.summary,
  estimated_minutes = EXCLUDED.estimated_minutes, level = EXCLUDED.level,
  competency = EXCLUDED.competency, sort_order = EXCLUDED.sort_order;

DELETE FROM lab_lesson_sections WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'risk-ai-governance-nist');
INSERT INTO lab_lesson_sections (lesson_id, heading, body, sort_order)
SELECT l.id, v.heading, v.body, v.sort_order
FROM lab_lessons l, (VALUES
  ('Govern by risk, not by tool', 'Start from the use case and its potential harms, not from the AI tool. The same model can be low-risk in one context and high-risk in another.', 1),
  ('Map, measure, manage', 'Identify the context and risks, assess how serious they are, then assign controls and named owners.', 2),
  ('Document and review', 'Keep a record of the assessment and review it as the system, the data or the world changes.', 3)
) AS v(heading, body, sort_order)
WHERE l.code = 'risk-ai-governance-nist';

DELETE FROM lab_questions WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'risk-ai-governance-nist');
INSERT INTO lab_questions (lesson_id, prompt, options, correct_index, explanation, sort_order)
SELECT l.id, v.prompt, v.options::jsonb, v.correct_index, v.explanation, v.sort_order
FROM lab_lessons l, (VALUES
  ('A risk-based approach starts from which question?',
   '["Which model is most advanced?","What is the use case and who could be harmed?","How fast can we ship?"]', 1,
   'Risk is a property of the use case and its context, not the model alone.', 1),
  ('After identifying and assessing risks, what comes next?',
   '["Ignore them","Assign controls and named owners, then document","Increase the temperature"]', 1,
   'Managing risk means controls, ownership and a written record that is reviewed over time.', 2)
) AS v(prompt, options, correct_index, explanation, sort_order)
WHERE l.code = 'risk-ai-governance-nist';

-- ---------------------------------------------------------------------------
-- Source links (lesson_sources)
-- ---------------------------------------------------------------------------
-- Finance: adapted from CC BY sources.
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'adapted', 'Condensed to a short workplace lesson and added a South African rand example.'
FROM lab_lessons l, content_sources cs
WHERE l.code = 'finance-read-the-numbers' AND cs.title = 'Financial Management for Small Businesses'
ON CONFLICT DO NOTHING;
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'adapted', 'Simplified the ratio and time-value explanations for a short lesson.'
FROM lab_lessons l, content_sources cs
WHERE l.code = 'finance-read-the-numbers' AND cs.title = 'Introduction to Financial Analysis'
ON CONFLICT DO NOTHING;
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'adapted', 'Adapted the forecasting assumptions guidance into a verification activity.'
FROM lab_lessons l, content_sources cs
WHERE l.code = 'finance-verify-a-forecast' AND cs.title = 'Financial Management for Small Businesses'
ON CONFLICT DO NOTHING;

-- Legal: adapted from public-domain official texts.
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'adapted', 'Wrote original scenarios around the primary sources; quoted only official text.'
FROM lab_lessons l, content_sources cs
WHERE l.code = 'legal-primary-sources' AND cs.title = 'South African legislation and court judgments'
ON CONFLICT DO NOTHING;
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'adapted', 'Wrote original scenarios around the primary sources; quoted only official text.'
FROM lab_lessons l, content_sources cs
WHERE l.code = 'legal-ai-citation-check' AND cs.title = 'South African legislation and court judgments'
ON CONFLICT DO NOTHING;

-- IT: link/inspire only (BY-SA sources must not contaminate original lesson text).
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'linked', NULL
FROM lab_lessons l, content_sources cs
WHERE l.code = 'it-verify-generated-code' AND cs.title = 'OWASP Cheat Sheet Series'
ON CONFLICT DO NOTHING;
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'inspired_by', NULL
FROM lab_lessons l, content_sources cs
WHERE l.code = 'it-verify-generated-code' AND cs.title = 'Dive into Deep Learning'
ON CONFLICT DO NOTHING;
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'inspired_by', NULL
FROM lab_lessons l, content_sources cs
WHERE l.code = 'it-model-limits' AND cs.title = 'Dive into Deep Learning'
ON CONFLICT DO NOTHING;

-- Cross-industry: adapted from NIST AI RMF (public domain).
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'adapted', 'Summarised the map-measure-manage functions into a short lesson.'
FROM lab_lessons l, content_sources cs
WHERE l.code = 'risk-ai-governance-nist' AND cs.title = 'NIST AI Risk Management Framework'
ON CONFLICT DO NOTHING;

-- Existing global lessons: link/inspire (BY-SA) and adapt (public domain).
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'inspired_by', NULL
FROM lab_lessons l, content_sources cs
WHERE l.code = 'ai-fundamentals' AND cs.title = 'Dive into Deep Learning'
ON CONFLICT DO NOTHING;
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'inspired_by', NULL
FROM lab_lessons l, content_sources cs
WHERE l.code = 'fact-checking-with-ai' AND cs.title = 'NIST AI Risk Management Framework'
ON CONFLICT DO NOTHING;
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'adapted', 'Added South African examples and condensed the guidance.'
FROM lab_lessons l, content_sources cs
WHERE l.code = 'ai-ethics-and-bias' AND cs.title = 'NIST AI Risk Management Framework'
ON CONFLICT DO NOTHING;
