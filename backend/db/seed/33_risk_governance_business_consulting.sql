-- Risk & Governance — Business Consulting (6 tasks)
-- Source: VERIFAI.docx_my_part_final_final.docx (Business Consulting Risk & Governance task bank).
-- Decision is binary: Proceed (0) / Don't proceed (50). Reason: correct 50, wrong 0.

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-bc-01', 'Business Consulting',
  $$The Confidential Figures in a Chatbot$$,
  $$A junior consultant, under deadline pressure, plans to paste unpublished sales and margin figures into a free AI chatbot to generate competitor commentary.$$,
  $$Consulting contracts almost always include confidentiality clauses, and sharing unpublished client data with an uncontracted vendor breaches them. If personal data is involved, POPIA applies. Time pressure does not override compliance duties.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. Unpublished client data must not go into an uncontracted tool - use approved enterprise tooling or public data only, and report the incident.","score":50},
    {"kind":"reason","label":"B. The figures are not personal data, so confidentiality rules do not apply.","score":0},
    {"kind":"reason","label":"C. It is fine under deadline pressure as long as the output is reworded.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-bc-02', 'Business Consulting',
  $$The Undisclosed AI Report$$,
  $$A team plans to send a market-entry strategy report to a client, 40% of which was drafted using AI, without disclosing the AI use or having senior consultants review the AI-assisted sections.$$,
  $$Clients pay for professional judgement, not unchecked AI output. Undisclosed AI use risks negligence claims if recommendations prove wrong, and engagement letters may require disclosure. Accountability and verification cannot be delegated to the tool.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. Senior consultants must review all AI-assisted sections and check disclosure requirements before the report goes to the client.","score":50},
    {"kind":"reason","label":"B. AI use does not need to be disclosed if the final report reads well.","score":0},
    {"kind":"reason","label":"C. The client only cares about the recommendations, not how they were produced.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-bc-03', 'Business Consulting',
  $$The Fabricated CAGR$$,
  $$An AI tool summarises financial filings for a due-diligence report and states a revenue CAGR of 18% that does not appear in the source documents.$$,
  $$Due diligence informs multi-million-rand acquisitions. A fabricated number can mislead valuations and negotiations, exposing the firm to liability. AI outputs are leads to confirm, not facts to report.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. Exclude the figure unless it is verified against the primary filings, and document the verification.","score":50},
    {"kind":"reason","label":"B. Include it; the AI derived it from the filings.","score":0},
    {"kind":"reason","label":"C. Include it with a note that it is an AI estimate.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-bc-04', 'Business Consulting',
  $$The Recording in the Boardroom$$,
  $$During a restructuring workshop with a JSE-listed client, a consultant plans to let an AI notes tool record the discussion and sync it to a shared folder.$$,
  $$Unannounced restructuring is price-sensitive under the Financial Markets Act. Uncontrolled recording risks insider-trading exposure, and vendor terms may allow retention or training on the transcripts, breaching confidentiality.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. Disable the tool, delete any transcripts, take manual notes in restricted files, and share only with authorised people.","score":50},
    {"kind":"reason","label":"B. The recording is internal, so there is no risk.","score":0},
    {"kind":"reason","label":"C. It is fine if the shared folder is access-controlled.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-bc-05', 'Business Consulting',
  $$The BEE Structure That Is Fronting$$,
  $$An AI tool suggests a shareholding arrangement that meets B-BBEE percentage requirements but denies the black shareholders real economic benefit or voting rights.$$,
  $$Such arrangements are fronting, which is unlawful under the B-BBEE Codes' substance-over-form requirements and can blacklist clients from procurement. AI tools have no awareness of the legal substance test, making human review essential.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. Reject the structure - it is fronting - and test it against the B-BBEE substance-over-form requirements before advising.","score":50},
    {"kind":"reason","label":"B. The percentages meet the target, so the structure is compliant.","score":0},
    {"kind":"reason","label":"C. Fronting is only a problem if the shareholders complain.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-bc-06', 'Business Consulting',
  $$The Firm-Wide Rollout Without Governance$$,
  $$A consulting firm plans to deploy a general AI tool across all staff without a use policy or vendor agreement.$$,
  $$Deploying AI without governance delegates confidentiality obligations to vendor terms and exposes the firm to POPIA breaches. Regulators can enforce compliance regardless of whether AI-specific laws exist.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. Pause the rollout until a data-processing agreement and a written AI policy (prohibited data, approvals, escalation) are in place.","score":50},
    {"kind":"reason","label":"B. Roll it out now and write the policy once staff are using it.","score":0},
    {"kind":"reason","label":"C. Vendor terms are enough governance for a general tool.","score":0}
  ]$j$::jsonb
);
