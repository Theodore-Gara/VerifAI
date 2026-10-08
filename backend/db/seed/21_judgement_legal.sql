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

-- ===========================================================================
-- Set 2 (10 tasks) — VerifAI_Legal_AI_Judgement_Tasks_Set2.pdf
-- ===========================================================================

SELECT seed_choice_task(
  'judgement', 'judgement-legal-06', 'Legal', $$The Training Session Notes$$,
  $$Your firm held an internal training session on its new document-filing system. You typed rough bullet notes with no client information and want AI to turn them into a tidy one-page guide for new joiners.$$,
  $$A fine use of AI. Nothing confidential is involved and the output is easy to check against your own notes. Read it once to make sure the steps are in the right order.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":50},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":0},
    {"kind":"reason","label":"A. The notes contain no client or privileged information, the stakes are low, and you can read the guide to confirm it matches what was taught.","score":50},
    {"kind":"reason","label":"B. AI will correct any mistakes in your notes, so you do not need to read the final guide.","score":0},
    {"kind":"reason","label":"C. Anything written for a law firm must be drafted entirely by a lawyer, even a guide to a filing system.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-legal-07', 'Legal', $$The Recruitment Advert$$,
  $$The firm wants to advertise for a candidate attorney. You ask AI for five alternative opening lines for the advert. You give it only the job title and the firm's public description.$$,
  $$Safe and low risk. AI is useful for ideas on wording. A partner should still approve the final advert, because it speaks for the firm.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":50},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":0},
    {"kind":"reason","label":"A. Whatever the AI suggests will attract the best candidates, so the best option can be posted without approval.","score":0},
    {"kind":"reason","label":"B. Only public information is shared, no client matter is involved, and a partner will approve the final wording.","score":50},
    {"kind":"reason","label":"C. Anything that represents the firm to the public must be written without any outside help.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-legal-08', 'Legal', $$The Jargon Decoder$$,
  $$You are reading a supply contract and do not understand the term 'force majeure'. You ask AI to explain the concept in plain English, without pasting any of the client's contract.$$,
  $$A good use of AI as a learning aid. It explains the idea, but the wording of the clause and the governing law decide what it means in this contract, so read the clause and ask your supervisor.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":50},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":0},
    {"kind":"reason","label":"A. The AI's explanation tells you exactly how the clause works in this contract, so you do not need to read the clause.","score":0},
    {"kind":"reason","label":"B. Legal terms can only be understood from a law dictionary, so asking AI is a misuse of the tool.","score":0},
    {"kind":"reason","label":"C. You are asking about a general concept to help you learn, no client text is shared, and you will still read the actual clause and check with your supervisor.","score":50}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-legal-09', 'Legal', $$The Client Update$$,
  $$Using the file notes, the firm's approved AI tool drafts a letter updating a client on the progress of their dispute. The draft says the case is 'very likely to succeed'.$$,
  $$The draft is a time-saver, not a final letter. Check every fact against the file, change language that guarantees an outcome, and make sure the advice matches what the supervising attorney actually thinks.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI can save drafting time, but a lawyer must check the facts, remove promises about outcomes and make sure nothing inaccurate goes to the client.","score":50},
    {"kind":"reason","label":"B. The tool used the file notes, so the letter is accurate and the optimism is justified.","score":0},
    {"kind":"reason","label":"C. Client letters must only ever be written by the attorney, so the draft should be thrown away.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-legal-10', 'Legal', $$The Discovery Sort$$,
  $$In a litigation matter with 3,000 documents, an AI tool sorts them into 'relevant' and 'not relevant'. A colleague suggests disclosing exactly what the tool selects, with no one checking.$$,
  $$AI-assisted sorting is useful for large volumes. But disclosing a privileged document by mistake, or missing a relevant one, can seriously harm the client, so a lawyer must review borderline documents and a sample of the rest.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. Document sorting is mechanical, so the tool's selection is as good as a lawyer's review.","score":0},
    {"kind":"reason","label":"B. AI can speed up the sorting, but a lawyer must check a sample, review anything privileged or borderline, and take responsibility for what is disclosed.","score":50},
    {"kind":"reason","label":"C. AI cannot be used for discovery because every page must be read by a partner personally.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-legal-11', 'Legal', $$The Translated Statement$$,
  $$A client gives you a handwritten statement in isiZulu that must be used in a court application in English. AI produces an English version in seconds.$$,
  $$Use the AI translation to understand the statement quickly, then have a competent translator check it and make sure the client confirms it says what they meant. In sworn evidence, meaning matters as much as words.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI is trained on many languages, so the translation can be filed as it is.","score":0},
    {"kind":"reason","label":"B. Statements in other languages must never be translated with a tool, so you should leave it for the court to arrange.","score":0},
    {"kind":"reason","label":"C. AI gives a useful first draft, but a mistake in translation can change the meaning of sworn evidence, so a competent translator or the client must confirm it before it is used.","score":50}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-legal-12', 'Legal', $$The Lease Table$$,
  $$Your client owns 40 commercial leases. You ask AI to extract rent, renewal dates and termination notice periods into one table for a property sale.$$,
  $$Use AI to build the first version of the table, then check the dates, notice periods and unusual clauses against the originals, starting with the leases that matter most to the sale.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI saves hours of reading, but one wrong date or clause can affect the sale, so key entries must be checked against the original leases, with extra care for unusual clauses.","score":50},
    {"kind":"reason","label":"B. A table is only a summary of facts, so it cannot contain legal mistakes.","score":0},
    {"kind":"reason","label":"C. Leases are too long for AI, so every clause must be copied by hand.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-legal-13', 'Legal', $$The Opinion Letter$$,
  $$A partner is busy and suggests sending the client a legal opinion that was written by AI. No lawyer would read it, but it would go out on the firm's letterhead.$$,
  $$AI can help with research leads and first drafts, but the opinion belongs to the lawyer who signs it. An unchecked opinion sent in the firm's name creates professional and negligence risks.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. If the AI was given the relevant documents, its opinion is as good as a lawyer's and can be sent as it is.","score":0},
    {"kind":"reason","label":"B. A legal opinion is professional advice for which the firm is accountable, so a qualified lawyer must read, check and stand behind every word.","score":50},
    {"kind":"reason","label":"C. AI cannot be used in any part of preparing an opinion, even to organise research or draft an outline.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-legal-14', 'Legal', $$The Settlement Decision$$,
  $$The other side offers R400,000 to settle. The client is hard to reach, and a colleague suggests asking AI to decide whether to accept the offer and replying on the client's behalf.$$,
  $$AI can help you set out the strengths, risks and likely outcomes to put to the client. The decision and the instruction must come from the client, and you should ask for an extension rather than act without it.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. AI can weigh the risks better than the client, so it can decide when the client is not available.","score":0},
    {"kind":"reason","label":"B. Settlement offers should always be rejected until the client replies, whatever the deadline.","score":0},
    {"kind":"reason","label":"C. Whether to settle is the client's decision, made on the lawyer's advice, so an AI cannot decide or give instructions in the client's name.","score":50}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-legal-15', 'Legal', $$The Witness Statement$$,
  $$A witness gave you a few rough notes about a car accident. To save time, a colleague wants AI to write a full, polished statement 'in the witness's own words' that the witness will just sign.$$,
  $$Take down what the witness actually says, in their own words, and read it back to them. The content must be theirs. Invented detail can destroy a witness's credibility and the case with it.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. A statement must record what the witness actually remembers, in their own account, so AI-written detail could put words in their mouth and create false evidence.","score":50},
    {"kind":"reason","label":"B. As long as the witness signs, the origin of the text does not matter.","score":0},
    {"kind":"reason","label":"C. Witness statements must be handwritten by the witness, so no typed draft of any kind is allowed.","score":0}
  ]$j$::jsonb
);
