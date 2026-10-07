-- AI Judgement — Finance (5 tasks)
-- Source: VerifAI_Finance_AI_Judgement_Tasks.pdf.
-- Decision scale (ordered): Use AI (50) - Use AI with human review (25) - Don't use AI (0)
-- where the correct choice scores 50, its neighbour 25, the opposite 0.
-- Reason: correct 50, wrong 0.

SELECT seed_choice_task(
  'judgement', 'judgement-finance-01', 'Finance',
  $$The Month-End Agenda$$,
  $$You are a junior accountant at a mid-sized firm. Your manager asks you to prepare the agenda for Monday's month-end close meeting. It only lists the usual topics: outstanding reconciliations, accruals, and deadlines for each team member. No client names or figures are involved. A colleague suggests asking AI to draft it.$$,
  $$Good call. This is a low-stakes task with no sensitive information, and the output is easy to check at a glance. AI is a sensible tool here. Still skim it before you send it, as you would with any document that carries your name.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":50},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":0},
    {"kind":"reason","label":"A. It is a routine, low-risk document with no confidential data, and any mistake is easy to spot and fix.","score":50},
    {"kind":"reason","label":"B. AI should be used for every finance task because it saves time.","score":0},
    {"kind":"reason","label":"C. Anything written by AI looks unprofessional, so it should be avoided.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-finance-02', 'Finance',
  $$The Annual Report Summary$$,
  $$You have a client call tomorrow with a listed retailer. Your manager asks for a one-page summary of its published 120-page annual report: revenue, profit, debt, and outlook. You paste the report into your firm's approved AI tool and it returns a clean summary in seconds.$$,
  $$AI is genuinely useful for summarising long documents, but it can quote a wrong figure with complete confidence. You are the one who will be quoted on the call, so tick the key numbers back to the report before you rely on the summary.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. The report is public, so confidentiality is not the issue, but AI can misstate or invent figures, so every key number must be checked against the source.","score":50},
    {"kind":"reason","label":"B. Annual reports are too complex for AI, so it should never be used for them.","score":0},
    {"kind":"reason","label":"C. Because the report is published, the AI summary can be trusted without checking.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-finance-03', 'Finance',
  $$The Variance Commentary$$,
  $$Month-end management accounts show costs 18% over budget. The finance director wants a short commentary explaining the main variances. You have the ledger detail and notes from the department heads. You consider giving these to your firm's approved AI tool to draft the commentary.$$,
  $$AI is good at turning your notes into clear sentences. It cannot know why a cost really increased, and it may invent a plausible reason. Use it for the writing, and keep ownership of the facts. Use only your firm's approved tool for internal figures.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI can draft the wording quickly, but it does not know the real business reasons, so you must confirm every explanation against the ledger and what the department heads told you.","score":50},
    {"kind":"reason","label":"B. AI already knows why costs rose because it has seen similar companies.","score":0},
    {"kind":"reason","label":"C. Commentary must always be written by hand, so AI should not be used at all.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-finance-04', 'Finance',
  $$The Automatic Loan Decision$$,
  $$You work in the credit department of a lender. Management proposes letting an AI model automatically approve or decline personal loan applications. No staff member would look at declined applications, to clear a growing backlog.$$,
  $$AI can help by scoring and flagging applications, but the final decision should stay with a person. POPIA places limits on decisions made solely by automated processing that significantly affect someone, and lenders also have duties under the National Credit Act, such as assessing affordability. People also need a way to question a decline.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. A decision that significantly affects a person's finances needs an accountable human. AI can support with scoring, but it should not be the sole decision-maker.","score":50},
    {"kind":"reason","label":"B. AI is too slow to process loan applications.","score":0},
    {"kind":"reason","label":"C. Declined applicants do not need an explanation, so a person adds no value.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-finance-05', 'Finance',
  $$The Suspicious Transaction$$,
  $$You work in compliance at a bank. An AI monitoring tool flags a client who made several cash deposits, each just under the reporting threshold. A colleague suggests letting the AI decide whether this is suspicious and automatically file the report with the Financial Intelligence Centre (FIC).$$,
  $$The AI did its job by spotting the pattern. Whether to report is a legal judgement, and under FICA the duty to report suspicious transactions sits with the institution and its people. Let AI flag, and let a trained person decide and file.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. AI is useful for flagging patterns, but deciding whether activity is suspicious, and the legal responsibility for reporting, belongs to trained compliance staff.","score":50},
    {"kind":"reason","label":"B. AI should never be used in compliance work, even to flag transactions.","score":0},
    {"kind":"reason","label":"C. Every flag should be reported automatically, so no judgement is needed.","score":0}
  ]$j$::jsonb
);
