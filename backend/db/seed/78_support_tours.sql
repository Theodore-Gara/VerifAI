-- 78_support_tours.sql — tour manifests: one global tour and one per industry.
--
-- media is null until recordings are hosted; every step's body_md is the
-- transcript, so a tour is complete as text and the app's missing-player
-- handling is exercised from day one. To attach a recording, set
-- media = {"kind":"video","url":...,"captions_url":...,"poster":...,
-- "duration_seconds":...} through a content update; no app build is needed.
-- Idempotent: upserts on tour_key; newer admin edits are preserved.

INSERT INTO support_tours (tour_key, track_id, title, steps, updated_at)
VALUES ('global-v1', NULL, 'VerifAI in 60 seconds',
$j$[{"id":"dashboard","title":"Your home screen","body_md":"Home shows your next recommended task, your readiness score, your XP and your streak. Tap the info button on any card to see what it measures.","media":null},{"id":"start-a-task","title":"Starting a task","body_md":"Tap your next task or open Practice. Read the scenario, make your choice or find the flawed line, explain your reasoning, and submit. You will get feedback straight away.","media":null},{"id":"vera","title":"Meet Vera","body_md":"Vera is your AI coach. Ask her to explain a concept or talk through a scenario. She helps you think; she will not hand you the answer.","media":null},{"id":"menu","title":"The menu","body_md":"The menu button opens a full list of the app, including Help, About, Contact and Log out. The bottom bar always has Home, Learn, Practice, Progress and Profile.","media":null},{"id":"progress","title":"Progress","body_md":"Progress shows your readiness, your skill scores and your readiness path, a five-stage journey that always shows your next step.","media":null}]$j$::jsonb,
'2026-10-22T00:00:00Z')
ON CONFLICT (tour_key) DO UPDATE SET
  title = EXCLUDED.title, steps = EXCLUDED.steps, updated_at = EXCLUDED.updated_at
WHERE support_tours.updated_at <= EXCLUDED.updated_at;

INSERT INTO support_tours (tour_key, track_id, title, steps, updated_at)
SELECT 'finance-v1', it.id, 'Finance: your pathway',
$j$[{"id":"skills","title":"The four skills in Finance","body_md":"Verification: check AI-generated figures against their source and period. AI Judgement: decide when a forecast can use AI and when a person must own it. Risk & Governance: spot privacy and compliance risk in a finance workflow. Prompt Design: ask for what you need clearly; its tasks are still being added.","media":null},{"id":"start-here","title":"Where to start","body_md":"Start with a Verification task, then read the Finance textbook in Learn. Try Judgement once you have passed a few Verification tasks.","media":null},{"id":"path","title":"Your readiness path","body_md":"Your path has five stages: Orientation, Verify, Judge and govern, Apply, and Prove readiness. Each step is based on real work you have done, and the screen always shows the next one.","media":null}]$j$::jsonb,
'2026-10-22T00:00:00Z'
FROM industry_tracks it WHERE it.name = 'Finance'
ON CONFLICT (tour_key) DO UPDATE SET
  track_id = EXCLUDED.track_id, title = EXCLUDED.title, steps = EXCLUDED.steps,
  updated_at = EXCLUDED.updated_at
WHERE support_tours.updated_at <= EXCLUDED.updated_at;

INSERT INTO support_tours (tour_key, track_id, title, steps, updated_at)
SELECT 'legal-v1', it.id, 'Legal: your pathway',
$j$[{"id":"skills","title":"The four skills in Legal","body_md":"Verification: check that a summary cites what it claims to. AI Judgement: decide when a draft can be AI-assisted and when it needs a lawyer. Risk & Governance: spot confidentiality, privilege and POPIA risk. Prompt Design: ask for what you need clearly; its tasks are still being added.","media":null},{"id":"start-here","title":"Where to start","body_md":"Start with a Verification task, then read the Legal textbook in Learn. Interview practice is also available on the Legal pathway.","media":null},{"id":"path","title":"Your readiness path","body_md":"Your path has five stages: Orientation, Verify, Judge and govern, Apply, and Prove readiness. Each step is based on real work you have done, and the screen always shows the next one.","media":null}]$j$::jsonb,
'2026-10-22T00:00:00Z'
FROM industry_tracks it WHERE it.name = 'Legal'
ON CONFLICT (tour_key) DO UPDATE SET
  track_id = EXCLUDED.track_id, title = EXCLUDED.title, steps = EXCLUDED.steps,
  updated_at = EXCLUDED.updated_at
WHERE support_tours.updated_at <= EXCLUDED.updated_at;

INSERT INTO support_tours (tour_key, track_id, title, steps, updated_at)
SELECT 'it-software-v1', it.id, 'IT / Software: your pathway',
$j$[{"id":"skills","title":"The four skills in IT / Software","body_md":"Verification: review generated code for bugs the model is confident about. AI Judgement: decide when AI-written code can ship. Risk & Governance: spot security, licensing and data risk in engineering work. Prompt Design: ask for what you need clearly; its tasks are still being added.","media":null},{"id":"start-here","title":"Where to start","body_md":"Start with a Verification task, then read the IT textbook in Learn. Try Judgement once you have passed a few Verification tasks.","media":null},{"id":"path","title":"Your readiness path","body_md":"Your path has five stages: Orientation, Verify, Judge and govern, Apply, and Prove readiness. Each step is based on real work you have done, and the screen always shows the next one.","media":null}]$j$::jsonb,
'2026-10-22T00:00:00Z'
FROM industry_tracks it WHERE it.name = 'IT / Software'
ON CONFLICT (tour_key) DO UPDATE SET
  track_id = EXCLUDED.track_id, title = EXCLUDED.title, steps = EXCLUDED.steps,
  updated_at = EXCLUDED.updated_at
WHERE support_tours.updated_at <= EXCLUDED.updated_at;

INSERT INTO support_tours (tour_key, track_id, title, steps, updated_at)
SELECT 'business-consulting-v1', it.id, 'Business Consulting: your pathway',
$j$[{"id":"skills","title":"The four skills in Business Consulting","body_md":"Verification: check a recommendation against its evidence. AI Judgement: decide when a strategy or client answer can be AI-assisted. Risk & Governance: spot bias, privacy and compliance risk in an engagement. Prompt Design: ask for what you need clearly; its tasks are still being added.","media":null},{"id":"start-here","title":"Where to start","body_md":"Start with a Verification task, then read the Business Consulting textbook in Learn. Try Judgement once you have passed a few Verification tasks.","media":null},{"id":"path","title":"Your readiness path","body_md":"Your path has five stages: Orientation, Verify, Judge and govern, Apply, and Prove readiness. Each step is based on real work you have done, and the screen always shows the next one.","media":null}]$j$::jsonb,
'2026-10-22T00:00:00Z'
FROM industry_tracks it WHERE it.name = 'Business Consulting'
ON CONFLICT (tour_key) DO UPDATE SET
  track_id = EXCLUDED.track_id, title = EXCLUDED.title, steps = EXCLUDED.steps,
  updated_at = EXCLUDED.updated_at
WHERE support_tours.updated_at <= EXCLUDED.updated_at;

