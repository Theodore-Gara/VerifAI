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

-- ===========================================================================
-- Set 2 (10 tasks) — VerifAI_Finance_AI_Judgement_Tasks_Set2.pdf
-- ===========================================================================

SELECT seed_choice_task(
  'judgement', 'judgement-finance-06', 'Finance', $$The Spreadsheet Formula$$,
  $$You are a graduate analyst. You need a spreadsheet formula to look up each supplier's code from a list. You are stuck, so you describe the layout to AI using made-up example names and ask how to build the formula. No real supplier data is shared.$$,
  $$Good use of AI. You get help with a technique without sharing real data, and the result is easy to test. Check it on a few rows with known answers before you apply it to the full list.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":50},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":0},
    {"kind":"reason","label":"A. You are asking for a method using made-up data, nothing sensitive is shared, and you can test the formula on a few rows where you already know the answers.","score":50},
    {"kind":"reason","label":"B. AI-written formulas are always correct, so you can apply them to the whole ledger straight away.","score":0},
    {"kind":"reason","label":"C. Spreadsheet formulas in finance must be learned from textbooks only, so asking AI is poor practice.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-finance-07', 'Finance', $$The Friendly Extension Request$$,
  $$You have drafted an email asking the finance director for two more days on a report due on Friday. It contains no figures or client names. You want AI to make the tone more professional without changing your message.$$,
  $$Rewording your own message is a safe, low-stakes use of AI. Read the new version to make sure it still says what you meant, especially the dates.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":50},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":0},
    {"kind":"reason","label":"A. Emails to senior staff must be written without any help so that they show your real ability.","score":0},
    {"kind":"reason","label":"B. It is your own text with no sensitive content, the stakes are low, and you can read the result before sending it.","score":50},
    {"kind":"reason","label":"C. AI will make the request more likely to be approved, so it should be used for every request you send.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-finance-08', 'Finance', $$The Exam Timetable$$,
  $$You are preparing for your professional accountancy exams. You paste the public list of syllabus topics into AI and ask it to build a 10-week study timetable around your work hours.$$,
  $$Low risk and easy to adjust. Treat the plan as a draft: check the topics against the official syllabus and weightings, and give more time to your weaker areas.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":50},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":0},
    {"kind":"reason","label":"A. A timetable from AI is only reliable if it carries the exam body's approval.","score":0},
    {"kind":"reason","label":"B. Planning is a human skill and AI cannot help with scheduling at all.","score":0},
    {"kind":"reason","label":"C. The syllabus is public, nothing confidential is shared, and a study plan is a suggestion you can adjust.","score":50}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-finance-09', 'Finance', $$The Debtor Reminder$$,
  $$Your firm's approved AI tool drafts reminder emails to customers with overdue invoices, using the debtors ledger. You are about to send 40 emails in one batch.$$,
  $$The tool saves time on the wording, but only you know which accounts are disputed, on payment plans or already paid. Check the amounts and exclude special cases before you send.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI can draft the wording quickly, but a wrong amount or a reminder sent to a customer in a dispute can damage the relationship and even support a legal claim, so a person should check the ledger first.","score":50},
    {"kind":"reason","label":"B. Reminders are routine, so if the tool produced them from the ledger they are correct and can go out as they are.","score":0},
    {"kind":"reason","label":"C. Customer emails should never be drafted by AI because customers can always tell and will be offended.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-finance-10', 'Finance', $$The Bank Line Matching$$,
  $$An AI feature matches 2,000 bank statement lines to ledger entries and shows a confidence level for each match. Your manager suggests accepting every match above 80% confidence without looking at them.$$,
  $$Use the tool for the bulk of the work, then spend your time where the risk is highest: large amounts, round figures, unmatched lines and a random sample of the accepted matches.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. Anything above 80% confidence is accurate, so human review only slows down the month-end close.","score":0},
    {"kind":"reason","label":"B. AI speeds up the matching, but a wrong match can hide an error or fraud, so a person should review large amounts, unmatched items and a sample of the rest.","score":50},
    {"kind":"reason","label":"C. Bank matching must be done by hand line by line because AI is not allowed near the ledger.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-finance-11', 'Finance', $$The Next-Year Budget$$,
  $$AI builds next year's budget by increasing every line of this year's budget by 8%. The finance director wants a first draft by tomorrow morning.$$,
  $$The AI draft is a useful skeleton. Replace the flat 8% with assumptions that reflect real changes, such as a contract ending, a salary increase or a price change, and note them so others can follow your reasoning.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. A single growth rate applied evenly is the standard budgeting method, so the draft is ready to submit.","score":0},
    {"kind":"reason","label":"B. AI cannot do arithmetic on a budget, so a spreadsheet must be built from scratch by hand.","score":0},
    {"kind":"reason","label":"C. A flat increase is a fast starting point, but it ignores one-off items, lost or new contracts and costs that rise at different rates, so a person must challenge the assumptions line by line.","score":50}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-finance-12', 'Finance', $$The Receipt Scanner$$,
  $$An AI tool reads staff expense receipts and codes each to a ledger account and VAT treatment. The first batch shows VAT claimed on a restaurant bill, a petrol slip and a handwritten receipt.$$,
  $$Scanning and coding is a good use of AI, but the tool does not carry the responsibility for the VAT rules. Check that each claim has a valid tax invoice and that blocked items, such as entertainment, are not claimed.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI can extract and code receipts quickly, but VAT can only be claimed on valid tax invoices and some categories are blocked, so a person should check the coding and sample the results.","score":50},
    {"kind":"reason","label":"B. If the tool coded the VAT, SARS will accept the claim because a system produced it.","score":0},
    {"kind":"reason","label":"C. Receipt data must always be typed in by hand because scanning tools are not allowed to read financial documents.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-finance-13', 'Finance', $$The Sign-Off$$,
  $$The deadline for the annual financial statements is close. A director suggests having an AI tool review them and 'sign off' that they are correct, so the board can approve them without anyone reading them in full.$$,
  $$AI can help by checking arithmetic and flagging inconsistencies, but it cannot approve anything. Responsibility sits with the directors, and they need to understand and own the numbers they sign.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. A thorough AI review is more accurate than the directors, so it is a valid substitute for their approval.","score":0},
    {"kind":"reason","label":"B. The directors are legally responsible for approving the financial statements, and a tool cannot take accountability, so people who understand the numbers must review and approve them.","score":50},
    {"kind":"reason","label":"C. AI should not be used anywhere near financial statements, even to check arithmetic or spot inconsistencies.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-finance-14', 'Finance', $$The New Bank Details$$,
  $$A supplier emails to say its bank account has changed and asks you to pay the next invoice of R185,000 into the new account. An AI assistant in the finance system offers to approve the change automatically because the email 'looks genuine'.$$,
  $$AI can flag unusual changes, but it cannot confirm who is really behind an email. Verify with a known contact by phone, record who confirmed it, and have a second person approve the change.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. If the email address and invoice look genuine, the AI's check is enough, and a phone call would only delay the payment.","score":0},
    {"kind":"reason","label":"B. The change should be refused outright because suppliers never change banks.","score":0},
    {"kind":"reason","label":"C. Changes to bank details are a common fraud method, so a person must verify the request by phoning the supplier on a number already on file before any payment is made.","score":50}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-finance-15', 'Finance', $$The Missing Invoice$$,
  $$You are an audit junior. One supplier invoice for R94,000 is missing from the file and the audit is due tomorrow. A colleague suggests asking AI to 'recreate' the invoice so the file looks complete.$$,
  $$Never use AI to make evidence that did not exist. Ask the supplier for a copy, find other evidence such as the bank payment, or tell your senior about the gap so it can be handled openly.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. Audit evidence must be genuine, and creating a document to replace a missing one is fabrication, so the right step is to request a copy from the supplier or document the gap.","score":50},
    {"kind":"reason","label":"B. A recreated invoice with the right amount and supplier name is equivalent to the original, so it can go in the file.","score":0},
    {"kind":"reason","label":"C. Missing evidence can be ignored when the amount is small compared with the total.","score":0}
  ]$j$::jsonb
);
