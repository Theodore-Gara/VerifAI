-- Risk & Governance — Legal (6 tasks, one per practice area)
-- Source: VerifAI_Legal_Task_Bank_Expanded_FIXED.docx.
-- Decision is binary: Proceed (0) / Don't proceed (50). Reason: correct 50, wrong 0.

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-legal-01', 'Legal',
  $$The Privileged Recording$$,
  $$A candidate attorney plans to use a free, consumer-grade AI transcription and summarisation tool to process an audio recording of a privileged settlement negotiation, to save time writing up the attendance note afterwards.$$,
  $$Privileged without-prejudice communications are protected from disclosure precisely so parties can negotiate frankly, and that protection is undermined the moment the content is processed by a third-party tool with unclear retention practices. Uploading it risks unauthorised disclosure of privileged material and a POPIA-relevant processing without a lawful basis.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. Do not use the free tool for privileged material - write the note manually or use only an enterprise tool under a data-processing agreement with partner sign-off.","score":50},
    {"kind":"reason","label":"B. It is fine because the candidate attorney will review the transcript.","score":0},
    {"kind":"reason","label":"C. Free tools are acceptable for short recordings.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-legal-02', 'Legal',
  $$The Settlement Chatbot$$,
  $$An HR business partner plans to use a public, consumer-facing AI chatbot to draft a retrenched employee's settlement agreement, pasting in the employee's full ID number, complete salary history, and details of a recent period of medical boarding.$$,
  $$Medical boarding information is 'special personal information' under section 26 of POPIA, which imposes a materially higher processing threshold, and the settlement terms are commercially and reputationally sensitive. A tight signing deadline does not create an exception to that threshold.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. Do not paste this into a public chatbot - medical boarding is special personal information under POPIA and the settlement terms are sensitive; use an approved secure system.","score":50},
    {"kind":"reason","label":"B. It is fine because the HR partner will only use it to draft, not to send.","score":0},
    {"kind":"reason","label":"C. Deadline pressure justifies using the fastest available tool.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-legal-03', 'Legal',
  $$The Unapproved Redlining Plug-in$$,
  $$A commercial attorney plans to use a browser-based AI plug-in - not licensed or approved by the firm - to redline a counterparty's draft NDA before it comes back for signature. The plug-in's terms of service state that it may retain uploaded documents to improve its model.$$,
  $$Even a document drafted by the counterparty can contain commercially sensitive terms, so 'it is not our client's document' is not a valid basis for treating the confidentiality risk as absent. The plug-in also sits outside the firm's data-processing agreements and security review.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. Do not use the unapproved plug-in - use the firm's licensed tool or redline manually, as the counterparty's document is still confidential.","score":50},
    {"kind":"reason","label":"B. It is fine because the document came from the counterparty, not the client.","score":0},
    {"kind":"reason","label":"C. It is fine because the plug-in only retains documents, it does not share them.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-legal-04', 'Legal',
  $$The Rates Clearance Upload$$,
  $$A conveyancing secretary plans to speed up preparing a rates clearance certificate application by uploading the seller's full identity document and municipal account statement - including the account holder's linked banking details - into a general-purpose public AI assistant to auto-generate a first draft.$$,
  $$Municipal account and linked banking information are financial personal information under POPIA, and an identity document number is directly identifying. 'It is just an admin task' does not lower the POPIA threshold - the Act applies to the processing itself, not the perceived importance of the task.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. Do not upload ID, municipal or banking details into a public assistant - use the firm's approved secure system or prepare the draft manually.","score":50},
    {"kind":"reason","label":"B. It is fine because the task is routine admin work.","score":0},
    {"kind":"reason","label":"C. It is fine if the assistant is free and widely used.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-legal-05', 'Legal',
  $$The Affidavit With Abuse Allegations$$,
  $$A candidate attorney plans to use a public AI chatbot to help draft a founding affidavit for an urgent Rule 43 maintenance application, including details of the client's alleged domestic abuse and the minor child's school and daily routine.$$,
  $$This is among the most sensitive category a family law practice handles: allegations of domestic abuse and a child's routine, taken together, create a genuine physical safety risk if exposed to an alleged abuser. A public consumer tool with unclear data handling is never acceptable for this category of content.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. Do not put this in a public chatbot - the abuse and child details create a physical safety risk if exposed; draft manually or via an approved secure tool with extreme caution.","score":50},
    {"kind":"reason","label":"B. It is fine because the AI provider is reputable.","score":0},
    {"kind":"reason","label":"C. It is fine if the client consents to using the tool.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'risk_governance', 'risk-governance-legal-06', 'Legal',
  $$The STR Through a Public Tool$$,
  $$A compliance officer, working against a tight statutory deadline, plans to use a public AI tool to draft a suspicious transaction report (STR) referencing a client's actual account activity and identifying details.$$,
  $$STRs are themselves confidential, legally protected documents under FICA, and the reporting regime depends on the confidentiality of both the fact that a report was made and its content. A statutory deadline is a reason to prioritise drafting time, not to use an unapproved tool.$$,
  $j$[
    {"kind":"decision","label":"Proceed","score":0},
    {"kind":"decision","label":"Don't proceed","score":50},
    {"kind":"reason","label":"A. Do not use a public tool - STRs are confidential under FICA and must be drafted in the institution's secure compliance system or manually.","score":50},
    {"kind":"reason","label":"B. It is fine because the deadline is statutory.","score":0},
    {"kind":"reason","label":"C. It is fine because the client under suspicion will never see the draft.","score":0}
  ]$j$::jsonb
);
