-- VerifAI AI Lab — Legal textbook.
-- Structure: book > chapter > topic > subtopic. Original text written around
-- South African primary law (official texts, no copyright). Idempotent.

INSERT INTO lab_lessons (code, track_id, title, summary, estimated_minutes, level, is_original, competency, sort_order)
VALUES
  ('legal-book', (SELECT id FROM industry_tracks WHERE name = 'Legal'),
   'Legal: a working textbook',
   'How South African law is made, the rights it protects, and the rules for contracts, consumers, data and companies.',
   60, 1, FALSE, 'Verification', 110)
ON CONFLICT (code) DO UPDATE SET
  track_id = EXCLUDED.track_id, title = EXCLUDED.title, summary = EXCLUDED.summary,
  estimated_minutes = EXCLUDED.estimated_minutes, level = EXCLUDED.level,
  competency = EXCLUDED.competency, sort_order = EXCLUDED.sort_order;

DELETE FROM lab_lessons WHERE code IN ('legal-primary-sources', 'legal-ai-citation-check');

DELETE FROM lab_lesson_sections WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'legal-book');

-- Chapters ------------------------------------------------------------------
INSERT INTO lab_lesson_sections (lesson_id, heading, body, parent_id, sort_order)
SELECT l.id, v.heading, v.body, NULL, v.sort_order
FROM lab_lessons l, (VALUES
  ('Sources of South African law', 'Where law comes from and how to find the primary text.', 1),
  ('The Constitution and rights', 'The supreme law and the rights it guarantees.', 2),
  ('Contracts', 'When an agreement becomes a binding, enforceable obligation.', 3),
  ('Consumer protection and data privacy', 'The Consumer Protection Act and POPIA.', 4),
  ('Companies and governance', 'How companies are formed, run and held to account.', 5),
  ('AI in law', 'Working from primary authority and checking an AI-cited source.', 6)
) AS v(heading, body, sort_order)
WHERE l.code = 'legal-book';

-- Topics --------------------------------------------------------------------
INSERT INTO lab_lesson_sections (lesson_id, heading, body, parent_id, sort_order)
SELECT l.id, v.heading, v.body, ch.id, v.tsort
FROM lab_lessons l,
(VALUES
  ('Sources of South African law', 'The Constitution', 'The supreme law that all other law must respect.', 1),
  ('Sources of South African law', 'Legislation', 'Acts of Parliament, regulations and municipal by-laws.', 2),
  ('Sources of South African law', 'Case law and precedent', 'How courts interpret the law and bind later courts.', 3),

  ('The Constitution and rights', 'Supremacy and the rule of law', 'No law or conduct may conflict with the Constitution.', 1),
  ('The Constitution and rights', 'The Bill of Rights', 'The rights of all people, and when they may be limited.', 2),
  ('The Constitution and rights', 'Enforcement', 'How a right is asserted and who may approach a court.', 3),

  ('Contracts', 'Formation', 'Offer, acceptance, intention and capacity.', 1),
  ('Contracts', 'Terms and breaches', 'What the parties promised and what happens when one fails.', 2),
  ('Contracts', 'Consumer contracts and the law', 'Some contracts are regulated to protect the weaker party.', 3),

  ('Consumer protection and data privacy', 'The Consumer Protection Act', 'Fair terms, honest marketing and the right to cancel.', 1),
  ('Consumer protection and data privacy', 'POPIA: the eight conditions', 'The rules for lawful processing of personal information.', 2),
  ('Consumer protection and data privacy', 'Breaches and notification', 'What to do when personal data is compromised.', 3),

  ('Companies and governance', 'Forming a company', 'Incorporation, the memorandum and separate legal personality.', 1),
  ('Companies and governance', 'Directors'' duties', 'Fiduciary and statutory duties of those in charge.', 2),
  ('Companies and governance', 'Accountability and liability', 'When directors can be held personally responsible.', 3),

  ('AI in law', 'Working from primary law', 'The Act and the judgment are the law; a summary is not.', 1),
  ('AI in law', 'Checking an AI-cited authority', 'Treat a citation as a claim to be verified.', 2)
) AS v(chapter, heading, body, tsort),
lab_lesson_sections ch
WHERE l.code = 'legal-book'
  AND ch.lesson_id = l.id AND ch.parent_id IS NULL AND ch.heading = v.chapter;

-- Subtopics -----------------------------------------------------------------
INSERT INTO lab_lesson_sections (lesson_id, heading, body, parent_id, sort_order)
SELECT l.id, v.heading, v.body, tp.id, v.ssort
FROM lab_lessons l,
(VALUES
  ('Sources of South African law', 'The Constitution', 'The supreme law',
   'The Constitution is the highest law in the country. Any legislation, common-law rule or conduct inconsistent with it is invalid to the extent of the inconsistency.', 1),
  ('Sources of South African law', 'The Constitution', 'Interpreting the law consistently',
   'Every statute must be read, if reasonably possible, in a way that is consistent with the Constitution. Where it cannot be, the courts may strike it down.', 2),
  ('Sources of South African law', 'Legislation', 'Acts and subordinate law',
   'Parliament passes Acts; ministers and municipalities make regulations and by-laws under authority given by an Act. Subordinate law is valid only within the powers it was granted.', 1),
  ('Sources of South African law', 'Legislation', 'Reading the current text',
   'An Act may be amended or repealed. Always confirm the wording in force on the date that matters, rather than relying on a summary of an earlier version.', 2),
  ('Sources of South African law', 'Case law and precedent', 'Judgments interpret the law',
   'Courts apply the law to facts and, in doing so, interpret it. That interpretation guides how later courts read the same provision.', 1),
  ('Sources of South African law', 'Case law and precedent', 'Binding and persuasive',
   'A decision of a higher court binds lower courts within its jurisdiction. Decisions of other courts may be persuasive but are not binding.', 2),

  ('The Constitution and rights', 'Supremacy and the rule of law', 'The Constitution prevails',
   'The rule of law means the state may act only under authority the law gives, and everyone, including the state, is subject to the law.', 1),
  ('The Constitution and rights', 'Supremacy and the rule of law', 'Two-stage review',
   'A court first asks whether a right was limited, then whether that limitation is justifiable. A limitation that is not reasonable and justifiable is unconstitutional.', 2),
  ('The Constitution and rights', 'The Bill of Rights', 'Rights belong to all people',
   'Many rights protect everyone in the country, not only citizens. They cover equality, dignity, privacy, expression and fair administrative action, among others.', 1),
  ('The Constitution and rights', 'The Bill of Rights', 'Limiting a right',
   'Rights may be limited by a law of general application, but only to the extent that is reasonable and justifiable in an open and democratic society.', 2),
  ('The Constitution and rights', 'Enforcement', 'Approaching a court',
   'Anyone whose rights are affected may approach a court for relief. A court may also grant appropriate relief to protect a right even when the applicant is not directly affected.', 1),
  ('The Constitution and rights', 'Enforcement', 'Just administrative action',
   'When the state makes a decision that affects you, it must be lawful, reasonable and procedurally fair, and give reasons where required.', 2),

  ('Contracts', 'Formation', 'Offer and acceptance',
   'A contract forms when one party makes a firm offer and the other accepts it, with the intention of creating a binding obligation and the capacity to do so.', 1),
  ('Contracts', 'Formation', 'Certainty and legality',
   'The terms must be certain enough to enforce, and the agreement must be lawful. An agreement to do something illegal is void.', 2),
  ('Contracts', 'Terms and breaches', 'Express and implied terms',
   'Terms may be stated in the contract or implied by law. Courts also read in terms the parties clearly intended, and may not enforce unfair terms in consumer contracts.', 1),
  ('Contracts', 'Terms and breaches', 'When a party fails',
   'A breach may entitle the innocent party to specific performance, cancellation or damages. The remedy depends on how serious the breach is.', 2),
  ('Contracts', 'Consumer contracts and the law', 'Protecting the weaker party',
   'Consumer legislation limits how far a supplier can impose terms, and gives consumers rights the contract cannot take away.', 1),
  ('Contracts', 'Consumer contracts and the law', 'Cooling-off and cancellation',
   'Some transactions may be cancelled within a set period, and fixed-term contracts must meet specific requirements. The contract cannot remove these rights.', 2),

  ('Consumer protection and data privacy', 'The Consumer Protection Act', 'The right to fair value and terms',
   'Consumers are entitled to goods of good quality, honest marketing and fair terms. Suppliers may not use terms that are unreasonable or misleading.', 1),
  ('Consumer protection and data privacy', 'The Consumer Protection Act', 'Direct marketing and the right to opt out',
   'Consumers may block unsolicited direct marketing, and may cancel certain agreements within a cooling-off period. The Act applies whether or not the consumer read the terms.', 2),
  ('Consumer protection and data privacy', 'POPIA: the eight conditions', 'Lawful processing',
   'POPIA sets conditions for processing personal information, including accountability, processing limitation, purpose specification, further processing limitation, information quality, openness, security safeguards and data-subject participation.', 1),
  ('Consumer protection and data privacy', 'POPIA: the eight conditions', 'Roles and responsibilities',
   'A responsible party decides why and how to process personal information; an operator processes it on the responsible party''s instructions. The responsible party remains accountable.', 2),
  ('Consumer protection and data privacy', 'Breaches and notification', 'Notifying the regulator and data subjects',
   'On discovering a compromise of personal information, the responsible party must notify the Information Regulator and, where there is a risk of harm, the affected data subjects.', 1),
  ('Consumer protection and data privacy', 'Breaches and notification', 'Minimising harm',
   'Good practice is to contain the breach, record what happened, and tell affected people what they can do to protect themselves. Delay increases the harm.', 2),

  ('Companies and governance', 'Forming a company', 'Incorporation and the memorandum',
   'A company is created by registration. Its memorandum sets out what it may do and how it is governed. Registration creates a separate legal person.', 1),
  ('Companies and governance', 'Forming a company', 'Separate personality',
   'A company owns its own property and owes its own debts. Shareholders are not, as a rule, liable for the company''s obligations.', 2),
  ('Companies and governance', 'Directors'' duties', 'Fiduciary duty',
   'A director must act in the best interests of the company, with the care, skill and diligence reasonably expected, and avoid conflicts of interest.', 1),
  ('Companies and governance', 'Directors'' duties', 'Statutory duties',
   'The Companies Act codifies duties of good faith, care and to not use the position for personal gain. These duties are owed to the company itself.', 2),
  ('Companies and governance', 'Accountability and liability', 'Lifting the corporate veil',
   'In limited cases, such as fraud or reckless trading, a court may hold individuals personally liable for what the company did.', 1),
  ('Companies and governance', 'Accountability and liability', 'Reckless trading and solvency',
   'Directors must not trade recklessly or allow the company to trade while insolvent. Doing so can attract personal liability and disqualification.', 2),

  ('AI in law', 'Working from primary law', 'Primary versus secondary',
   'The Act and the judgment are the law. A summary, a commentary or a headnote is someone''s reading of it, and may be wrong or out of date.', 1),
  ('AI in law', 'Working from primary law', 'Official texts carry no copyright',
   'Under section 12(8)(a) of the Copyright Act, no copyright subsists in official texts of a legislative, administrative or legal nature. You may quote the Act or a judgment; commentary and headnotes written by others are still protected.', 2),
  ('AI in law', 'Working from primary law', 'Read the provision, not the paraphrase',
   'Confirm the current wording and any amendments before you rely on a paraphrase. Law changes.', 3),
  ('AI in law', 'Checking an AI-cited authority', 'A citation is a lead, not proof',
   'An AI citation is a claim. Confirm the case or Act exists, that it is in force, and that it says what the AI claims it says.', 1),
  ('AI in law', 'Checking an AI-cited authority', 'Currency and context',
   'Check that a provision has not been amended and a judgment has not been overturned or distinguished. Authority is only authority if it is current and on point.', 2)
) AS v(chapter, topic, heading, body, ssort),
lab_lesson_sections ch,
lab_lesson_sections tp
WHERE l.code = 'legal-book'
  AND ch.lesson_id = l.id AND ch.parent_id IS NULL AND ch.heading = v.chapter
  AND tp.lesson_id = l.id AND tp.parent_id = ch.id AND tp.heading = v.topic;

-- End-of-book questions -----------------------------------------------------
DELETE FROM lab_questions WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'legal-book');
INSERT INTO lab_questions (lesson_id, prompt, options, correct_index, explanation, sort_order)
SELECT l.id, v.prompt, v.options::jsonb, v.correct_index, v.explanation, v.sort_order
FROM lab_lessons l, (VALUES
  ('Which of these is primary law?',
   '["A blog summary of POPIA","The text of an Act as published","A law firm''s newsletter"]', 1,
   'The published Act is the primary source; the others are secondary commentary.', 1),
  ('You want to quote a judgment. Does copyright prevent it?',
   '["Yes, all judgments are copyrighted","No - official legal texts carry no copyright","Only if you quote more than 50 words"]', 1,
   'Section 12(8)(a) of the Copyright Act excludes copyright in official legal texts; commentary about them may still be protected.', 2),
  ('An AI confidently cites a case. What should you do before relying on it?',
   '["Cite it as given - the AI sounds sure","Confirm it exists and supports the proposition","Assume it is current"]', 1,
   'Confirm existence, currency and relevance from the primary source before relying on it.', 3),
  ('A cited provision was amended after the AI was trained. What is the risk?',
   '["None - wording does not change","The AI may state law that is no longer in force","The citation becomes public domain"]', 1,
   'AI training data ages; the provision must be checked against its current wording.', 4),
  ('Which is the supreme law in South Africa?',
   '["The Constitution","The Companies Act","A court judgment"]', 0,
   'All law and conduct must respect the Constitution, the highest law.', 5),
  ('A contract forms from...',
   '["Offer and acceptance with intention and capacity","A handshake alone","Registration"]', 0,
   'Formation needs offer, acceptance, intention and capacity.', 6),
  ('Under POPIA, who decides why and how personal information is processed?',
   '["The responsible party","The operator","The data subject"]', 0,
   'The responsible party decides the purpose and means, and remains accountable.', 7),
  ('After a breach with a risk of harm, who must be notified?',
   '["Nobody","The Information Regulator and the affected data subjects","Only the police"]', 1,
   'The regulator and, where harm is likely, the affected people must be told.', 8),
  ('A director''s duties are owed to...',
   '["The company","The largest shareholder","The government"]', 0,
   'Directors owe their fiduciary and statutory duties to the company itself.', 9),
  ('Do official legal texts carry copyright?',
   '["Yes, all of them","No - official legal texts do not","Only judgments do"]', 1,
   'Section 12(8)(a) excludes copyright in official legal texts; commentary may still be protected.', 10)
) AS v(prompt, options, correct_index, explanation, sort_order)
WHERE l.code = 'legal-book';

-- Source links --------------------------------------------------------------
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'adapted', 'Wrote original textbook prose around the primary sources; quoted only official text.'
FROM lab_lessons l, content_sources cs
WHERE l.code = 'legal-book' AND cs.title = 'South African legislation and court judgments'
ON CONFLICT DO NOTHING;
