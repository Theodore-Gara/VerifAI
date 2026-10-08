-- Risk & Governance — Finance (6 tasks)
-- Source: VERIFAI.docx_my_part_final_final.docx (Finance Risk & Governance task bank).
-- Decision is binary: Proceed (0) / Don't proceed (50). Reason: correct 50, wrong 0.

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-finance-01', 'Finance',
  $$The Recommendation Without a Suitability Analysis$$,
  $$A financial advisor plans to send a client nearing retirement an AI-drafted investment recommendation letter, based on a short profile the advisor typed in from memory. The AI letter recommends a moderately aggressive equity-heavy portfolio and reads as professional and well-reasoned, but no documented needs analysis or risk-profiling was completed with the client.$$,
  $$Under the FAIS Act a documented needs analysis and risk-profiling process must happen before advice; a polished AI recommendation cannot substitute for it or be backfilled after the fact. Without it, the absence of a suitability record is typically decisive in an adverse FAIS Ombud finding.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. FAIS requires a documented needs analysis and risk-profiling before advice, and the AI letter cannot substitute for that process.","score":50},
    {"kind":"reason","label":"B. The AI recommendation is well-reasoned, so the letter can be sent as-is.","score":0},
    {"kind":"reason","label":"C. The advisor can backfill the suitability analysis after sending the letter.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-finance-02', 'Finance',
  $$The Unexplainable Credit Decline$$,
  $$A microlender wants to deploy an AI credit-scoring model that automatically approves or declines personal loan applications, with no documentation of the factors behind a score and no human-review path for declined applicants.$$,
  $$The National Credit Act requires credit providers to give reasons for declining credit, and POPIA gives the right not to be subject to a decision based solely on automated processing without safeguards. An unexplainable model with no human-review path fails both.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. The NCA requires reasons for declines and POPIA limits purely automated decisions, so the model needs factor-level explainability and a human-review path.","score":50},
    {"kind":"reason","label":"B. Telling the applicant the model scored them below the threshold is a sufficient reason.","score":0},
    {"kind":"reason","label":"C. Explaining the model's factors would let applicants game the system.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-finance-03', 'Finance',
  $$The Unverified Management Accounts$$,
  $$A finance team plans to release AI-drafted monthly management accounts to a client, feeding raw transaction exports to the AI to categorise and summarise, with no reconciliation of AI-categorised entries against source documents.$$,
  $$AI categorisation can misclassify material items - a once-off correction mislabelled as revenue can overstate operating performance. Without a materiality-based human reconciliation, the client may act on a financial position that does not exist, exposing the firm to a negligence claim.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. AI can misclassify material entries, so a qualified person must reconcile AI-categorised items above a materiality threshold before release.","score":50},
    {"kind":"reason","label":"B. AI categorises transactions accurately, so the accounts can be released as drafted.","score":0},
    {"kind":"reason","label":"C. The client can spot any errors themselves.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-finance-04', 'Finance',
  $$The Price-Sensitive Memo$$,
  $$An analyst at an investment firm plans to paste details of a listed client's pending, unannounced acquisition - the target's identity, the proposed deal structure, and the expected announcement date - into a consumer-grade AI writing tool to polish an internal memo.$$,
  $$Details of a pending, unannounced acquisition are inside information under the Financial Markets Act. The offence of unauthorised disclosure does not require proof that anyone traded on it - the disclosure to an uncontrolled third party is itself the risk event.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. Unannounced deal details are inside information, and disclosing them to an uncontrolled AI tool is itself the risk event, so this must not go ahead.","score":50},
    {"kind":"reason","label":"B. The analyst's intent is just better writing, so it is harmless.","score":0},
    {"kind":"reason","label":"C. It is fine as long as the tool has a privacy policy.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-finance-05', 'Finance',
  $$The PEP the AI Missed$$,
  $$A bank's onboarding team plans to rely on an AI tool's automated first-pass FICA risk classification for new corporate clients, including applications where ownership runs through layers of holding companies.$$,
  $$FICA requires a risk-based approach with enhanced measures for politically exposed persons. An AI that misses PEP status because it did not trace layered ownership is a foreseeable failure mode given how common such structures are - not a rare edge case.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. FICA requires enhanced due diligence for PEPs, and an AI that does not trace layered ownership can miss PEP status, so beneficial ownership needs human review.","score":50},
    {"kind":"reason","label":"B. The AI risk score is reliable enough to rely on for onboarding.","score":0},
    {"kind":"reason","label":"C. PEP status only matters for individual clients, not corporates.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-finance-06', 'Finance',
  $$The Robo-Advisor That Favours Itself$$,
  $$A fintech plans to launch a robo-advisory tool that recommends retirement annuity products from a short online questionnaire with no human advisor, and the model tends to recommend the firm's own higher-fee product over comparable lower-fee alternatives even where a user's profile would favour the cheaper option.$$,
  $$The FSCA's Treating Customers Fairly framework requires recommendations to serve the client's interests, not the provider's revenue interests. A model that systematically favours the firm's own product is a fair-dealing failure that operates at the scale of every user.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. TCF requires recommendations to serve the client's interests, so a model that systematically favours the firm's own product must not go live without independent review.","score":50},
    {"kind":"reason","label":"B. Recommendations are automated, so fair-dealing rules do not apply.","score":0},
    {"kind":"reason","label":"C. Users can choose a different product if they want to.","score":0}
  ]$j$::jsonb
);
