-- VerifAI AI Lab — IT / Software textbook.
-- Structure: book > chapter > topic > subtopic. Original text (security and ML
-- sources are BY-SA, so they are linked/inspired by, not adapted). Idempotent.

INSERT INTO lab_lessons (code, track_id, title, summary, estimated_minutes, level, is_original, competency, sort_order)
VALUES
  ('it-book', (SELECT id FROM industry_tracks WHERE name = 'IT / Software'),
   'IT and software: a working textbook',
   'How software is built, kept secure and deployed, how data is stored, and what machine learning can and cannot promise.',
   60, 1, TRUE, 'Verification', 110)
ON CONFLICT (code) DO UPDATE SET
  track_id = EXCLUDED.track_id, title = EXCLUDED.title, summary = EXCLUDED.summary,
  estimated_minutes = EXCLUDED.estimated_minutes, level = EXCLUDED.level,
  is_original = EXCLUDED.is_original, competency = EXCLUDED.competency, sort_order = EXCLUDED.sort_order;

DELETE FROM lab_lessons WHERE code IN ('it-verify-generated-code', 'it-model-limits');

DELETE FROM lab_lesson_sections WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'it-book');

-- Chapters ------------------------------------------------------------------
INSERT INTO lab_lesson_sections (lesson_id, heading, body, parent_id, sort_order)
SELECT l.id, v.heading, v.body, NULL, v.sort_order
FROM lab_lessons l, (VALUES
  ('How software is built', 'From requirements to a running program.', 1),
  ('Secure coding', 'Writing code that resists hostile input.', 2),
  ('Data and databases', 'Storing, querying and protecting data.', 3),
  ('Machine learning basics', 'How models learn, and where they fail.', 4),
  ('Systems, networks and deployment', 'Running software reliably and safely in production.', 5),
  ('AI in software', 'Checking AI-generated code and understanding model limits.', 6)
) AS v(heading, body, sort_order)
WHERE l.code = 'it-book';

-- Topics --------------------------------------------------------------------
INSERT INTO lab_lesson_sections (lesson_id, heading, body, parent_id, sort_order)
SELECT l.id, v.heading, v.body, ch.id, v.tsort
FROM lab_lessons l,
(VALUES
  ('How software is built', 'The development cycle', 'Requirements, design, build, test, release.', 1),
  ('How software is built', 'Version control', 'Tracking every change and working safely in a team.', 2),
  ('How software is built', 'Testing', 'Why tests exist and what good ones cover.', 3),

  ('Secure coding', 'Input validation', 'Never trust anything from outside the program.', 1),
  ('Secure coding', 'Authentication and authorisation', 'Proving who someone is, and what they may do.', 2),
  ('Secure coding', 'Secrets and dependencies', 'Handling keys and third-party libraries safely.', 3),

  ('Data and databases', 'Relational data', 'Tables, keys and the shape of structured data.', 1),
  ('Data and databases', 'Queries and indexing', 'Retrieving data quickly, and why indexes matter.', 2),
  ('Data and databases', 'Protecting data', 'Encryption, access control and backups.', 3),

  ('Machine learning basics', 'Supervised learning', 'Learning a mapping from labelled examples.', 1),
  ('Machine learning basics', 'Overfitting and generalisation', 'Why a model can be perfect on training data and fail in the world.', 2),
  ('Machine learning basics', 'Evaluation', 'Judging a model on data it has never seen.', 3),

  ('Systems, networks and deployment', 'Operating systems and processes', 'What a process is and how resources are shared.', 1),
  ('Systems, networks and deployment', 'Networking basics', 'Addresses, ports and the request-response model.', 2),
  ('Systems, networks and deployment', 'Deployment and monitoring', 'Releasing safely and knowing when something breaks.', 3),

  ('AI in software', 'Verifying AI-generated code', 'Treat generated code as a proposal to review.', 1),
  ('AI in software', 'Understanding model limits', 'Know what a model does and does not guarantee.', 2)
) AS v(chapter, heading, body, tsort),
lab_lesson_sections ch
WHERE l.code = 'it-book'
  AND ch.lesson_id = l.id AND ch.parent_id IS NULL AND ch.heading = v.chapter;

-- Subtopics -----------------------------------------------------------------
INSERT INTO lab_lesson_sections (lesson_id, heading, body, parent_id, sort_order)
SELECT l.id, v.heading, v.body, tp.id, v.ssort
FROM lab_lessons l,
(VALUES
  ('How software is built', 'The development cycle', 'Requirements first',
   'Good software starts from a clear statement of what it must do and for whom. Skipping that step produces code that is technically fine and still solves the wrong problem.', 1),
  ('How software is built', 'The development cycle', 'Iterate in small steps',
   'Deliver in small increments so that feedback arrives early and mistakes stay cheap to correct. A large release hides its problems until they are expensive.', 2),
  ('How software is built', 'Version control', 'Every change is recorded',
   'Version control records who changed what and why, and lets you return to a known-good state. It makes collaboration possible without overwriting each other''s work.', 1),
  ('How software is built', 'Version control', 'Branches and reviews',
   'Work on a branch, then have someone review the change before it merges. Review catches design and security problems that a quick test run will not.', 2),
  ('How software is built', 'Testing', 'Tests are executable expectations',
   'A test states what the code should do and fails when it does not. Tests protect against regressions when the code is changed later.', 1),
  ('How software is built', 'Testing', 'Cover the edges',
   'The most valuable tests check empty, oversized and hostile input, not just the happy path. Bugs cluster at the boundaries.', 2),

  ('Secure coding', 'Input validation', 'Trust nothing external',
   'Every value that enters the program - from a user, a file or another service - is untrusted until validated. Reject what does not fit the expected form rather than cleaning it up.', 1),
  ('Secure coding', 'Input validation', 'Prevent injection',
   'Never build queries or commands by string concatenation. Use parameterised queries and safe APIs so that data cannot be read as code.', 2),
  ('Secure coding', 'Authentication and authorisation', 'Prove identity, then check permission',
   'Authentication confirms who someone is; authorisation decides what they may do. Checking the first without the second lets a legitimate user reach things they should not.', 1),
  ('Secure coding', 'Authentication and authorisation', 'Least privilege',
   'Give every account and service only the access it needs. Limiting privilege reduces the damage any single compromise can cause.', 2),
  ('Secure coding', 'Secrets and dependencies', 'Keep secrets out of code',
   'Keys and passwords belong in secure storage, not in the source tree or logs. A secret committed to version control is compromised even if it is later deleted.', 1),
  ('Secure coding', 'Secrets and dependencies', 'Third-party code is your code',
   'A dependency runs with your program''s privileges. Pin versions, watch for known vulnerabilities, and remove libraries you no longer need.', 2),

  ('Data and databases', 'Relational data', 'Tables and keys',
   'Relational data lives in tables of rows and columns. A primary key identifies a row; a foreign key links one table to another.', 1),
  ('Data and databases', 'Relational data', 'Constraints protect meaning',
   'Constraints - unique, not-null and foreign-key - keep invalid data out of the database. They encode rules the application should not be trusted to enforce alone.', 2),
  ('Data and databases', 'Queries and indexing', 'Asking precise questions',
   'A query selects and joins the rows you need. The clearer the question, the less data is moved and the faster the answer.', 1),
  ('Data and databases', 'Queries and indexing', 'Indexes trade space for speed',
   'An index lets the database find rows without scanning the whole table, at the cost of extra storage and slower writes. Index the columns you filter and join on.', 2),
  ('Data and databases', 'Protecting data', 'Encrypt and control access',
   'Encrypt data in transit and at rest, and grant database access on a need-to-know basis. Defence in depth means one failure is not enough to expose the data.', 1),
  ('Data and databases', 'Protecting data', 'Backups and recovery',
   'A backup you have never restored is only a hope. Test recovery regularly, because an untested backup often turns out not to work when it is needed.', 2),

  ('Machine learning basics', 'Supervised learning', 'Learning from examples',
   'Supervised learning fits a function that maps inputs to known outputs using labelled examples. The quality of the labels bounds the quality of the model.', 1),
  ('Machine learning basics', 'Supervised learning', 'Training and inference',
   'Training adjusts the model to fit the examples; inference applies the fitted model to new input. The two stages have very different cost and risk profiles.', 2),
  ('Machine learning basics', 'Overfitting and generalisation', 'Memorising versus learning',
   'A model that memorises its training data scores well there and poorly in the world. What matters is performance on data it has never seen.', 1),
  ('Machine learning basics', 'Overfitting and generalisation', 'Distribution shift',
   'Performance degrades when live data differs from training data. Monitor for drift and re-evaluate when the world changes.', 2),
  ('Machine learning basics', 'Evaluation', 'Hold out a test set',
   'Judge a model on data kept out of training, or the score is meaningless. The test set must reflect the conditions the model will meet.', 1),
  ('Machine learning basics', 'Evaluation', 'Accuracy is not enough',
   'On unbalanced data, accuracy flatters a model that ignores the rare class. Choose measures such as precision and recall that match the cost of each kind of error.', 2),

  ('Systems, networks and deployment', 'Operating systems and processes', 'A process is a running program',
   'The operating system gives each process its own memory and a share of the processor, and isolates processes from one another.', 1),
  ('Systems, networks and deployment', 'Operating systems and processes', 'Files, permissions and users',
   'The operating system controls who may read, write and execute each file. Running a service as an unprivileged user limits what a bug can reach.', 2),
  ('Systems, networks and deployment', 'Networking basics', 'Addresses and ports',
   'A request travels to an address and a port that identifies the service. Most traffic should be encrypted with TLS so it cannot be read or altered in transit.', 1),
  ('Systems, networks and deployment', 'Networking basics', 'The request-response model',
   'Clients send requests; servers return responses. Failures and delays are normal, so clients must time out and retry deliberately.', 2),
  ('Systems, networks and deployment', 'Deployment and monitoring', 'Release safely',
   'Deploy behind checks and, where possible, gradually. A change that can be rolled back quickly turns an incident into a small setback.', 1),
  ('Systems, networks and deployment', 'Deployment and monitoring', 'Observe the running system',
   'Logs, metrics and alerts tell you what the system is doing. Without them, failures are discovered by users rather than by you.', 2),

  ('AI in software', 'Verifying AI-generated code', 'Read for security, not style',
   'Generated code is usually plausible. The failures that matter cluster in input validation, authentication, authorisation and secrets handling.', 1),
  ('AI in software', 'Verifying AI-generated code', 'Test the edges',
   'Run tests for empty, oversized and hostile inputs before merging. AI-written code rarely anticipates the adversarial case.', 2),
  ('AI in software', 'Understanding model limits', 'Predicting text, not truth',
   'A model produces likely continuations, not verified facts. Fluency is not a correctness signal.', 1),
  ('AI in software', 'Understanding model limits', 'Distribution shift',
   'Performance degrades when live data differs from training data. Monitor for drift and re-evaluate when the world changes.', 2)
) AS v(chapter, topic, heading, body, ssort),
lab_lesson_sections ch,
lab_lesson_sections tp
WHERE l.code = 'it-book'
  AND ch.lesson_id = l.id AND ch.parent_id IS NULL AND ch.heading = v.chapter
  AND tp.lesson_id = l.id AND tp.parent_id = ch.id AND tp.heading = v.topic;

-- End-of-book questions -----------------------------------------------------
DELETE FROM lab_questions WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'it-book');
INSERT INTO lab_questions (lesson_id, prompt, options, correct_index, explanation, sort_order)
SELECT l.id, v.prompt, v.options::jsonb, v.correct_index, v.explanation, v.sort_order
FROM lab_lessons l, (VALUES
  ('Where is AI-generated code most likely to hide a security flaw?',
   '["In its comments","In input validation and auth paths","In its formatting"]', 1,
   'Validation, authentication and authorisation are the highest-risk paths in generated code.', 1),
  ('What is the responsible step before merging generated code that touches authentication?',
   '["Merge because it compiles","Review the security-sensitive paths and run edge-case tests","Remove the tests to ship faster"]', 1,
   'Read the security paths and test the edges before it reaches users.', 2),
  ('A model answers fluently and confidently. What does that tell you?',
   '["It is correct","Nothing about correctness","It verified its own answer"]', 1,
   'Fluency describes the text, not the truth of the claim.', 3),
  ('What happens when live data drifts from the training data?',
   '["Nothing","Model performance can silently degrade","The model retrains itself"]', 1,
   'Distribution shift degrades performance; it must be monitored and re-evaluated.', 4),
  ('To prevent injection you should...',
   '["Concatenate strings into queries","Use parameterised queries and safe APIs","Disable logging"]', 1,
   'Parameterised queries stop data from being read as code.', 5),
  ('Least privilege means giving an account...',
   '["Only the access it needs","Full administrator rights","No access at all"]', 0,
   'Least privilege limits the damage any single compromise can cause.', 6),
  ('Overfitting means a model...',
   '["Performs well on training data and poorly on new data","Is too simple","Trains too quickly"]', 0,
   'A model that memorises its training data fails on data it has never seen.', 7),
  ('Performance dropping because live data differs from training data is called...',
   '["Distribution shift","Compilation","Caching"]', 0,
   'Distribution shift degrades performance and must be monitored.', 8),
  ('A backup that has never been restored is...',
   '["Only a hope","A guarantee","Unnecessary"]', 0,
   'An untested backup often turns out not to work when it is needed.', 9),
  ('Running a service as an unprivileged user...',
   '["Limits what a bug can reach","Removes all security","Slows the service"]', 0,
   'Unprivileged users reduce the reach of any bug in the service.', 10)
) AS v(prompt, options, correct_index, explanation, sort_order)
WHERE l.code = 'it-book';

-- Source links --------------------------------------------------------------
-- Security and ML sources are CC BY-SA: linked or inspired by only, never adapted.
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'linked', NULL
FROM lab_lessons l, content_sources cs
WHERE l.code = 'it-book' AND cs.title = 'OWASP Cheat Sheet Series'
ON CONFLICT DO NOTHING;
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'inspired_by', NULL
FROM lab_lessons l, content_sources cs
WHERE l.code = 'it-book' AND cs.title = 'Dive into Deep Learning'
ON CONFLICT DO NOTHING;
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'adapted', 'Adapted the security and systems material into original textbook prose.'
FROM lab_lessons l, content_sources cs
WHERE l.code = 'it-book' AND cs.title = 'Critical Infrastructure Cybersecurity'
ON CONFLICT DO NOTHING;
