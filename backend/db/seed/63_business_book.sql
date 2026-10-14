-- VerifAI AI Lab — Business Consulting textbook.
-- Structure: book > chapter > topic > subtopic. Original text, adapted from
-- Project Management (CC BY 4.0). Idempotent.

INSERT INTO lab_lessons (code, track_id, title, summary, estimated_minutes, level, is_original, competency, sort_order)
VALUES
  ('business-book', (SELECT id FROM industry_tracks WHERE name = 'Business Consulting'),
   'Business consulting: a working textbook',
   'Managing and organising work, strategy, projects, customers, people, and keeping a human accountable for AI-assisted decisions.',
   60, 1, FALSE, 'AI Judgement', 110)
ON CONFLICT (code) DO UPDATE SET
  track_id = EXCLUDED.track_id, title = EXCLUDED.title, summary = EXCLUDED.summary,
  estimated_minutes = EXCLUDED.estimated_minutes, level = EXCLUDED.level,
  competency = EXCLUDED.competency, sort_order = EXCLUDED.sort_order;

DELETE FROM lab_lessons WHERE code IN ('business-ai-in-decisions', 'business-stakeholder-risk');

DELETE FROM lab_lesson_sections WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'business-book');

-- Chapters ------------------------------------------------------------------
INSERT INTO lab_lesson_sections (lesson_id, heading, body, parent_id, sort_order)
SELECT l.id, v.heading, v.body, NULL, v.sort_order
FROM lab_lessons l, (VALUES
  ('The management functions', 'Planning, organising, leading and controlling.', 1),
  ('Strategy and analysis', 'Choosing where to compete and how to win.', 2),
  ('Projects and change', 'Delivering a defined change on time and on budget.', 3),
  ('Marketing and customers', 'Understanding and serving a market.', 4),
  ('Organisations and people', 'Structure, teams and how work gets done.', 5),
  ('AI in business', 'Accountable AI-assisted decisions and stakeholder risk.', 6)
) AS v(heading, body, sort_order)
WHERE l.code = 'business-book';

-- Topics --------------------------------------------------------------------
INSERT INTO lab_lesson_sections (lesson_id, heading, body, parent_id, sort_order)
SELECT l.id, v.heading, v.body, ch.id, v.tsort
FROM lab_lessons l,
(VALUES
  ('The management functions', 'Planning and goals', 'Setting direction before action.', 1),
  ('The management functions', 'Organising resources', 'Who does what, with what authority.', 2),
  ('The management functions', 'Controlling performance', 'Measuring and correcting against the plan.', 3),

  ('Strategy and analysis', 'Mission and objectives', 'Why the organisation exists and what it is trying to do.', 1),
  ('Strategy and analysis', 'Analysis tools', 'SWOT and the competitive environment.', 2),
  ('Strategy and analysis', 'Choosing a position', 'Deciding where to play and how to win.', 3),

  ('Projects and change', 'The project life cycle', 'Initiation, planning, execution and closure.', 1),
  ('Projects and change', 'Scope, time and cost', 'The constraints that define a project.', 2),
  ('Projects and change', 'Stakeholders and risk', 'Who is affected, and what could go wrong.', 3),

  ('Marketing and customers', 'The market and the segment', 'Dividing a market to serve it well.', 1),
  ('Marketing and customers', 'The value proposition', 'What the customer gets and why it matters.', 2),
  ('Marketing and customers', 'Customers and retention', 'Winning a customer is only half the job.', 3),

  ('Organisations and people', 'Structure and culture', 'How authority and values shape behaviour.', 1),
  ('Organisations and people', 'Teams and motivation', 'What makes a group effective.', 2),
  ('Organisations and people', 'Change management', 'Helping people through a transition.', 3),

  ('AI in business', 'AI-assisted decisions and accountability', 'Keep a human accountable for any decision an AI assists.', 1),
  ('AI in business', 'Stakeholder and risk mapping', 'Map who is affected and how before deploying AI.', 2)
) AS v(chapter, heading, body, tsort),
lab_lesson_sections ch
WHERE l.code = 'business-book'
  AND ch.lesson_id = l.id AND ch.parent_id IS NULL AND ch.heading = v.chapter;

-- Subtopics -----------------------------------------------------------------
INSERT INTO lab_lesson_sections (lesson_id, heading, body, parent_id, sort_order)
SELECT l.id, v.heading, v.body, tp.id, v.ssort
FROM lab_lessons l,
(VALUES
  ('The management functions', 'Planning and goals', 'Decide the direction',
   'Planning sets the objectives and the path to reach them. A plan states what success looks like, so later decisions can be judged against it.', 1),
  ('The management functions', 'Planning and goals', 'Plans are not forecasts',
   'A plan is a commitment, not a prediction. When conditions change, the plan is revised deliberately rather than abandoned quietly.', 2),
  ('The management functions', 'Organising resources', 'Structure follows work',
   'Organising assigns tasks, authority and resources so the work can actually be done. The structure should serve the work, not the other way round.', 1),
  ('The management functions', 'Organising resources', 'Clear responsibility',
   'Every important outcome needs one accountable owner. Shared responsibility with no owner is how tasks are quietly dropped.', 2),
  ('The management functions', 'Controlling performance', 'Measure against the plan',
   'Controlling compares actual results with the plan and corrects the gap. Measures should be few, relevant and hard to game.', 1),
  ('The management functions', 'Controlling performance', 'Feed it back',
   'Control only works when the information reaches someone who can act on it. Feedback that arrives too late cannot change anything.', 2),

  ('Strategy and analysis', 'Mission and objectives', 'Purpose and direction',
   'The mission states why the organisation exists; objectives turn that into measurable goals. Together they give strategy something to aim at.', 1),
  ('Strategy and analysis', 'Mission and objectives', 'Align the parts',
   'Every function should support the objectives. A goal no one''s daily work advances will not be met.', 2),
  ('Strategy and analysis', 'Analysis tools', 'SWOT honestly',
   'SWOT lists internal strengths and weaknesses and external opportunities and threats. Its value depends on honesty about weaknesses, not on a tidy grid.', 1),
  ('Strategy and analysis', 'Analysis tools', 'The competitive environment',
   'External analysis looks at customers, competitors, suppliers and regulation. These forces change, so the analysis must be refreshed, not filed away.', 2),
  ('Strategy and analysis', 'Choosing a position', 'Trade-offs are the strategy',
   'A strategy that promises everything to everyone is not a strategy. Choosing where to compete means choosing what not to do.', 1),
  ('Strategy and analysis', 'Choosing a position', 'Fit and consistency',
   'The chosen activities must reinforce one another. A single inconsistent activity can undo the advantage the rest create.', 2),

  ('Projects and change', 'The project life cycle', 'From initiation to closure',
   'A project moves through initiation, planning, execution and closure. Each phase produces a decision, not just a document.', 1),
  ('Projects and change', 'The project life cycle', 'A project is temporary',
   'A project has a defined start and end and produces a specific result. Ongoing operations are a different kind of work with different management.', 2),
  ('Projects and change', 'Scope, time and cost', 'The triple constraint',
   'Scope, time and cost are linked: change one and the others move. Pretending all three are fixed is how projects fail.', 1),
  ('Projects and change', 'Scope, time and cost', 'Manage scope change',
   'Requests to add scope are normal; accepting them without adjusting time or cost is not. Record and approve changes deliberately.', 2),
  ('Projects and change', 'Stakeholders and risk', 'Identify who matters',
   'Stakeholders are anyone affected by or able to affect the project. Knowing their interests early prevents late surprises.', 1),
  ('Projects and change', 'Stakeholders and risk', 'Manage risk actively',
   'Identify what could go wrong, judge its likelihood and impact, and assign an owner and a response. Risk left unowned becomes a crisis.', 2),

  ('Marketing and customers', 'The market and the segment', 'Divide to serve',
   'A market is rarely one group. Segmenting lets you serve a group''s needs well instead of serving everyone poorly.', 1),
  ('Marketing and customers', 'The market and the segment', 'Target deliberately',
   'Choose the segments worth serving and why. Trying to reach everyone dilutes the message and the budget.', 2),
  ('Marketing and customers', 'The value proposition', 'The customer''s reason to buy',
   'A value proposition states the benefit the customer gets and why it beats the alternative. If it could describe a competitor too, it is not specific enough.', 1),
  ('Marketing and customers', 'The value proposition', 'Deliver what is promised',
   'The promise must match what the organisation can actually deliver. Marketing a gap between promise and reality destroys trust.', 2),
  ('Marketing and customers', 'Customers and retention', 'Keeping a customer costs less',
   'Retaining an existing customer usually costs less than winning a new one. Poor service quietly erodes the customer base.', 1),
  ('Marketing and customers', 'Customers and retention', 'Measure satisfaction honestly',
   'Track how customers actually behave, not only what they say. Action on feedback is what turns satisfaction into loyalty.', 2),

  ('Organisations and people', 'Structure and culture', 'Structure defines authority',
   'Structure determines who reports to whom and who decides. A structure that hides the decision-maker slows everything down.', 1),
  ('Organisations and people', 'Structure and culture', 'Culture sets the behaviour',
   'Culture is how people behave when no one is watching. Values that are not practised are just words on a wall.', 2),
  ('Organisations and people', 'Teams and motivation', 'Purpose and clarity',
   'A team works best with a clear purpose, defined roles and the authority to act. Ambiguity drains motivation faster than hard work does.', 1),
  ('Organisations and people', 'Teams and motivation', 'Feedback and recognition',
   'People need timely feedback and fair recognition. Silence is read as indifference, whether or not that is intended.', 2),
  ('Organisations and people', 'Change management', 'Expect resistance',
   'Change threatens habits and status, so resistance is normal. Engaging people early reduces it; ignoring it hardens it.', 1),
  ('Organisations and people', 'Change management', 'Communicate and support',
   'People adopt change when they understand why and are supported through it. A single announcement is not a change programme.', 2),

  ('AI in business', 'AI-assisted decisions and accountability', 'Who decides',
   'A model can recommend; an accountable person decides and records why. If no one owns the outcome, the decision is ungoverned.', 1),
  ('AI in business', 'AI-assisted decisions and accountability', 'Evidence and reversibility',
   'Prefer decisions you can reverse, and record the evidence used. An irreversible decision made on an unaudited model output is a governance failure.', 2),
  ('AI in business', 'Stakeholder and risk mapping', 'Map the affected',
   'Before deploying, list who is affected and how, including people who never interact with the tool directly.', 1),
  ('AI in business', 'Stakeholder and risk mapping', 'Watch for disparate impact',
   'Check outcomes across groups. A model can reproduce and amplify an existing gap in the data.', 2)
) AS v(chapter, topic, heading, body, ssort),
lab_lesson_sections ch,
lab_lesson_sections tp
WHERE l.code = 'business-book'
  AND ch.lesson_id = l.id AND ch.parent_id IS NULL AND ch.heading = v.chapter
  AND tp.lesson_id = l.id AND tp.parent_id = ch.id AND tp.heading = v.topic;

-- End-of-book questions -----------------------------------------------------
DELETE FROM lab_questions WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'business-book');
INSERT INTO lab_questions (lesson_id, prompt, options, correct_index, explanation, sort_order)
SELECT l.id, v.prompt, v.options::jsonb, v.correct_index, v.explanation, v.sort_order
FROM lab_lessons l, (VALUES
  ('An AI recommends a hiring decision. Who is accountable for the outcome?',
   '["The model vendor","The accountable person who decides to act","No one"]', 1,
   'A human owns the decision; the model only advises.', 1),
  ('Which decision is riskier to make on an unaudited model output?',
   '["A reversible one you can review later","An irreversible one with no documented evidence","One reviewed by a person"]', 1,
   'Irreversible decisions with no evidence leave no way to catch or correct harm.', 2),
  ('Who should be in a stakeholder map?',
   '["Only direct users of the tool","Everyone affected, including indirect groups","Only the project sponsor"]', 1,
   'Indirectly affected people often carry the risk and must be considered.', 3),
  ('What is the best first check for unfair outcomes?',
   '["Assume the model is neutral","Measure outcomes across relevant groups","Raise the model temperature"]', 1,
   'Fairness is measured by outcomes across groups, not assumed.', 4),
  ('The triple constraint of a project is...',
   '["Scope, time and cost","People, process and tools","Risk, reward and return"]', 0,
   'Change one of scope, time or cost and the others move.', 5),
  ('Every important outcome needs...',
   '["One accountable owner","Many owners","No owner"]', 0,
   'Shared responsibility with no owner is how tasks are quietly dropped.', 6),
  ('When is SWOT most useful?',
   '["When weaknesses are stated honestly","When weaknesses are hidden","When it is filed away"]', 0,
   'Its value depends on honesty about weaknesses, not on a tidy grid.', 7),
  ('A strategy means choosing...',
   '["Where to compete and what not to do","Everything for everyone","Only a slogan"]', 0,
   'A strategy that promises everything to everyone is not a strategy.', 8),
  ('Retaining an existing customer usually...',
   '["Costs less than winning a new one","Costs more","Is impossible"]', 0,
   'Retention usually costs less than acquisition; poor service erodes the base.', 9),
  ('What makes change stick?',
   '["Communication and support, not a single announcement","A single announcement","Ignoring resistance"]', 0,
   'People adopt change when they understand why and are supported through it.', 10)
) AS v(prompt, options, correct_index, explanation, sort_order)
WHERE l.code = 'business-book';

-- Source links --------------------------------------------------------------
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'adapted', 'Condensed the project-management material into original textbook prose.'
FROM lab_lessons l, content_sources cs
WHERE l.code = 'business-book' AND cs.title = 'Project Management'
ON CONFLICT DO NOTHING;
