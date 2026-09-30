-- VerifAI Deliverable 4 seed data
-- Safe to re-run for tracks, tasks, and achievements.

INSERT INTO industry_tracks (name, description) VALUES
  ('Finance', 'Financial services and banking scenarios'),
  ('Legal', 'Legal research and compliance scenarios'),
  ('IT / Software', 'Software development and IT operations scenarios'),
  ('Business Consulting', 'Management consulting and strategy scenarios')
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description;

-- Prototype users from the original team seed. In production, Firebase Auth owns credentials.
INSERT INTO users (firebase_uid, email, display_name)
VALUES
  ('theo@verif.com', 'theo@verif.com', 'Theodore Nangara'),
  ('vusani@verif.com', 'vusani@verif.com', 'Vusani Earl Mulaudzi'),
  ('naledi@verif.com', 'naledi@verif.com', 'Lwandle Naledi Chloe Mvelase'),
  ('mpho@verif.com', 'mpho@verif.com', 'Mpho Mokoena'),
  ('meshaque@verif.com', 'meshaque@verif.com', 'Meshaque Kalonji')
ON CONFLICT (firebase_uid) DO UPDATE
SET email = EXCLUDED.email,
    display_name = EXCLUDED.display_name;

-- Four employer-style workplace scenarios per track = 16 tasks total.
INSERT INTO tasks (track_id, title, scenario, correct_answer, feedback, dimension, difficulty)
SELECT it.id, x.title, x.scenario, x.correct_answer, x.feedback, x.dimension, x.difficulty
FROM industry_tracks it
JOIN (VALUES
  ('Finance', 'Verify an AI-generated credit summary', 'An AI assistant summarizes a customer credit file and says the customer has no recent missed payments. The source file contains a missed payment from last month. What should you do before using the summary?', 'Keywords: verify source records, check the original credit file, correct the missed payment, do not rely on the AI summary without verification.', 'Strong responses verify the original record, identify the contradiction, correct the summary, and avoid treating generated text as authoritative.', 'Verification', 'easy'),
  ('Finance', 'Choose an appropriate AI use case', 'A finance team wants AI to automatically approve or reject loan applications without human review. How should you respond?', 'Keywords: AI should not make the final high impact decision alone, require human review, use AI as decision support, validate for bias and accuracy.', 'High-impact financial decisions require appropriate human oversight and controls. AI can assist analysis but should not silently become the final decision-maker.', 'AI Judgement', 'medium'),
  ('Finance', 'Improve a financial analysis prompt', 'You need an AI model to compare quarterly revenue across three products using an internal dataset. What should a reliable prompt specify?', 'Keywords: define the dataset, specify the periods and products, request calculations, require assumptions, cite source data, flag missing information.', 'A good prompt constrains the data, calculation method, assumptions, and evidence requirements rather than asking for an unsupported conclusion.', 'Prompt Design', 'medium'),
  ('Finance', 'Protect confidential financial data', 'An analyst wants to paste a spreadsheet containing customer account numbers and transaction details into a public AI chatbot. What should you recommend?', 'Keywords: do not share confidential customer data, remove personal identifiers, use an approved secure AI system, follow privacy policy.', 'Sensitive customer information should not be pasted into an unapproved public service. De-identification and approved enterprise tooling reduce privacy risk.', 'Risk & Governance', 'easy'),

  ('Legal', 'Verify an AI legal citation', 'An AI draft memo cites a court case as support for a legal proposition. What should the lawyer do before including the citation?', 'Keywords: verify the case exists, check the original judgment, confirm the quoted holding, confirm the citation and jurisdiction.', 'AI-generated legal citations must be checked against authoritative sources before they are relied upon.', 'Verification', 'easy'),
  ('Legal', 'Decide whether AI can draft advice', 'A client asks for legal advice on a high-value dispute. A junior employee proposes sending the facts to a general AI chatbot and forwarding its answer directly to the client. What is the appropriate response?', 'Keywords: do not rely on unreviewed AI output, protect client confidentiality, use approved tools, require qualified human review.', 'The workflow needs confidentiality controls and qualified legal review. AI output is not a substitute for professional judgment.', 'AI Judgement', 'medium'),
  ('Legal', 'Prompt for contract review', 'You want AI to identify unusual termination clauses in a contract. What should the prompt include?', 'Keywords: provide the contract text, define unusual clause criteria, identify clause locations, quote relevant language, state uncertainty.', 'Specific criteria and evidence requirements make the review more auditable and reduce vague outputs.', 'Prompt Design', 'medium'),
  ('Legal', 'Manage privileged information', 'A legal team wants to use an external AI tool on a document containing privileged client communications. What is the key risk to address first?', 'Keywords: confidentiality, privilege, approved vendor, data retention, access controls, do not upload until authorised.', 'Confidentiality and privilege obligations must be assessed before information is sent to an external AI provider.', 'Risk & Governance', 'hard'),

  ('IT / Software', 'Review an AI-generated code fix', 'An AI assistant proposes a database query that appears to solve a bug but uses user input directly in the SQL string. What should the developer do?', 'Keywords: inspect the query, use parameterized queries, test the fix, reject direct string concatenation, security review.', 'The proposed fix introduces a SQL injection risk. The developer should use parameterized queries and test the corrected implementation.', 'Verification', 'easy'),
  ('IT / Software', 'Choose AI for production decisions', 'A team wants an AI coding assistant to automatically merge every generated change into production. What is the safer approach?', 'Keywords: human review, automated tests, code review, CI checks, security scanning, controlled deployment.', 'Generated code should pass normal engineering controls. Automation can accelerate delivery without removing review and testing gates.', 'AI Judgement', 'medium'),
  ('IT / Software', 'Prompt for reproducible debugging', 'You want AI to help diagnose a production error. What information should a strong prompt request or provide?', 'Keywords: exact error message, relevant logs, reproduction steps, environment, expected behavior, actual behavior, minimal code context.', 'Reproducible debugging prompts provide evidence and constraints rather than asking the model to guess.', 'Prompt Design', 'easy'),
  ('IT / Software', 'Handle secrets in AI tools', 'A developer plans to paste an API key into an AI chat to ask why an integration is failing. What should they do?', 'Keywords: never share secrets, revoke exposed key, use placeholders, use approved secure tooling, rotate credentials if exposed.', 'Credentials should never be placed in chat prompts. If a secret was exposed, it should be rotated according to the incident process.', 'Risk & Governance', 'easy'),

  ('Business Consulting', 'Validate an AI market claim', 'An AI-generated market report says a competitor grew 42% last year but provides no source. What should the consultant do?', 'Keywords: verify the claim, locate authoritative source, check reporting period, compare multiple sources, label uncertainty.', 'Unsupported market claims should be verified before they appear in client-facing analysis.', 'Verification', 'easy'),
  ('Business Consulting', 'Use AI in executive recommendations', 'A consultant asks AI to choose a restructuring strategy for a client based only on a short summary. What is the appropriate use of AI?', 'Keywords: use AI to support analysis, gather more evidence, consider stakeholder context, human judgment, validate recommendations.', 'AI can help structure analysis and alternatives, but the recommendation should be based on sufficient evidence and professional judgment.', 'AI Judgement', 'medium'),
  ('Business Consulting', 'Prompt for scenario analysis', 'You need AI to compare three business scenarios. What should the prompt specify?', 'Keywords: assumptions, scenarios, metrics, time horizon, constraints, calculations, sensitivity analysis, source data.', 'Explicit assumptions, metrics and constraints make scenario analysis easier to inspect and reproduce.', 'Prompt Design', 'medium'),
  ('Business Consulting', 'Protect client information', 'A consultant wants to paste a confidential client strategy document into a public AI service to create a presentation. What should they do?', 'Keywords: do not upload confidential information, use approved enterprise tooling, anonymize data, follow client confidentiality requirements.', 'Client confidentiality and approved-tool policies must be respected before using AI with client material.', 'Risk & Governance', 'easy')
) AS x(track_name, title, scenario, correct_answer, feedback, dimension, difficulty)
ON it.name = x.track_name
WHERE NOT EXISTS (
  SELECT 1 FROM tasks t WHERE t.track_id = it.id AND t.title = x.title
);

INSERT INTO achievements (code, name, description) VALUES
  ('first-task', 'First Assessment', 'Complete your first workplace readiness task.'),
  ('five-tasks', 'Five in the Bag', 'Complete five workplace readiness tasks.'),
  ('ten-tasks', 'Consistent Practitioner', 'Complete ten workplace readiness tasks.'),
  ('xp-500', '500 XP', 'Earn at least 500 XP.'),
  ('dimension-80', 'Strong Dimension', 'Reach a score of at least 80 in one readiness dimension.')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;
