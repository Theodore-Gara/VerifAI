-- AI Judgement — Legal (5 tasks)
-- Source: VerifAI_Legal_AI_Judgement_Tasks.pdf.

SELECT seed_choice_task(
  'judgement', 'judgement-legal-01', 'Legal',
  $$The Timesheet Reminder$$,
  $$You are a candidate attorney. The office manager asks you to send an email reminding all staff to submit their timesheets by Friday. No client names, matters or documents are involved. You consider asking AI to draft it.$$,
  $$Good call. There is no confidential or privileged material, the stakes are low, and you can check the result at a glance. Read it before you send it, because your name is on it.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":50},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":0},
    {"kind":"reason","label":"A. It is a routine admin email with no client or privileged information, and you can read it in seconds before sending.","score":50},
    {"kind":"reason","label":"B. AI should draft everything a law firm sends because it is faster than lawyers.","score":0},
    {"kind":"reason","label":"C. Law firms must never use AI for any email.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-legal-02', 'Legal',
  $$The Overnight Affidavit$$,
  $$Your firm is racing to file an urgent High Court application. A colleague suggests having an AI tool draft the whole founding affidavit overnight, saying 'we will review it in the morning anyway'. In the past, that has meant a quick skim an hour before the deadline.$$,
  $$South African courts have already dealt with filings that contained AI-invented case citations. An affidavit is sworn evidence, so the person who signs it is personally exposed if it is wrong. Use AI for the draft, schedule the checking as a real step, and ask for a short extension if there is no time.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI can speed up the first draft, but every fact and case citation must be checked against source documents in a scheduled review step, and the deponent must read it before signing under oath.","score":50},
    {"kind":"reason","label":"B. If the firm says it will review the draft, no specific review process is needed.","score":0},
    {"kind":"reason","label":"C. AI must never be used to draft court documents.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-legal-03', 'Legal',
  $$The Unlimited Indemnity$$,
  $$You are drafting a supply agreement for a client. An AI drafting tool recommends an uncapped indemnity covering any loss the other side might suffer, 'to protect the client from all possible risks'.$$,
  $$'Broader' is not the same as 'better protection'. A clause the client cannot actually stand behind, or that the other side will not sign, helps nobody. Use the AI suggestion as a starting point, narrow it to identified risks, add a cap, and confirm with the client's insurer that the cap fits their cover.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI can suggest clauses to start from, but an uncapped indemnity can exceed the client's insurance cover, stall negotiations and may not hold up, so a lawyer should tailor and cap it to specific risks.","score":50},
    {"kind":"reason","label":"B. More protection is always better, so the broadest possible clause should go in.","score":0},
    {"kind":"reason","label":"C. AI cannot draft contract clauses, so the suggestion should be ignored.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-legal-04', 'Legal',
  $$The Dismissal Summary$$,
  $$An AI tool reads a full disciplinary hearing transcript and concludes 'procedurally fair, dismissal recommended'. A partner wants to rely on that conclusion to tell the employee that a CCMA referral would be pointless. You read the transcript yourself and see that the employee's chosen shop steward was turned away at the door and the hearing went ahead with no representative.$$,
  $$AI can help you get through a long transcript, but it should not give the final answer on fairness. Procedure and the reason for dismissal are assessed separately, and a missing representative is a specific, nameable defect. Read the transcript against each requirement and raise the defect as a ground.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. Whether a dismissal was procedurally fair is a legal judgement against specific requirements, such as the right to be represented, and an AI summary can miss one requirement while sounding confident.","score":50},
    {"kind":"reason","label":"B. AI summaries are accurate enough to rely on, so the transcript does not need to be read.","score":0},
    {"kind":"reason","label":"C. A hearing is fair as long as the dismissal itself was justified.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-legal-05', 'Legal',
  $$The Low-Risk Label$$,
  $$You are in a conveyancing team. An AI tool processes a buyer's ID and documents and labels the transaction 'low risk, proceed with standard FICA checks'. The price is unusually high for the buyer's stated income and is being paid in one cash-equivalent transfer instead of through a bond. A colleague wants to close the FICA risk assessment on the AI's label.$$,
  $$AI can read documents quickly and flag points of interest, but the legal duty to assess risk and report suspicious activity is placed on the lawyer. A price that does not match the buyer's income, paired with an unusual payment method, is exactly the kind of fact that needs human judgement and enhanced checks.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. FICA duties fall on the conveyancer, not on a tool, and this combination of facts calls for a person to escalate for closer scrutiny whatever the label says.","score":50},
    {"kind":"reason","label":"B. A low-risk label from AI is enough because the tool already checked the documents.","score":0},
    {"kind":"reason","label":"C. Cash payments are always illegal, so the deal must be refused.","score":0}
  ]$j$::jsonb
);
