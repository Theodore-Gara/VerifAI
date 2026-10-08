-- Interview Practice — Legal (ungraded, read-only)
-- Source: VerifAI_Legal_Task_Bank_Expanded_FIXED.docx (Interview Practice Panels).

SELECT seed_interview('Legal',
  $$You are handed AI-drafted heads of argument the night before a filing deadline. Walk me through what you do before it is filed.$$,
  $$I treat every citation as unverified until I have located it myself on SAFLII or Juta using the exact case name and citation, and read the paragraph the proposition is supposedly drawn from. If I cannot locate and confirm a citation within the time available, I remove it and note the gap to the supervising attorney rather than filing it on trust - even under deadline pressure.$$,
  $$A concrete, repeatable verification workflow rather than a general assurance of care.$$,
  1);

SELECT seed_interview('Legal',
  $$Some say cases like Northbound Processing show AI should not be used in litigation at all. Do you agree?$$,
  $$I do not think the tool itself was the problem - the failure was filing without independent verification. AI can still speed up first-draft research and drafting; what has not changed, and cannot be delegated to a tool, is the professional duty to check what goes in front of a court before it is filed.$$,
  $$Nuanced reasoning over a blanket 'AI is bad' or 'AI is fine' position.$$,
  2);

SELECT seed_interview('Legal',
  $$True or false: a correctly formatted citation is good evidence that a case is real.$$,
  $$False. Generative AI models are very good at producing citations that follow the correct report formatting conventions whether or not the underlying case exists - which is exactly why formatting fluency proves nothing about factual accuracy, and why the only reliable check is finding the case itself on a primary source.$$,
  $$Understanding that fluency and factual accuracy are unrelated properties of generative AI output.$$,
  3);

SELECT seed_interview('Legal',
  $$Tell me about a time you had to push back on an AI-generated conclusion in an employment matter.$$,
  $$An AI review tool concluded a dismissal was procedurally fair without checking whether the employee's chosen representative was actually present at the hearing. I caught it by reading the representation requirements against the hearing transcript directly, rather than trusting the tool's summary judgement.$$,
  $$A specific, plausible example with a clear, checkable reasoning process.$$,
  4);

SELECT seed_interview('Legal',
  $$What is the difference between using AI to summarise a CCMA award and using AI to decide whether to appeal it?$$,
  $$Summarising is low-risk as long as I still read the award myself afterwards to confirm the summary is accurate. Deciding whether to take a review or appeal further involves weighing litigation cost, precedent risk, and the client's actual risk tolerance - that is a judgement call I own personally, not something I delegate to a tool.$$,
  $$A clear boundary between using AI as a tool and letting AI make a decision.$$,
  5);

SELECT seed_interview('Legal',
  $$In one sentence - why can AI not reliably predict a commissioner's ruling?$$,
  $$Because commissioner-specific tendencies built up from unpublished institutional experience are not captured in public training data the way reported case law is.$$,
  $$Concise, accurate reasoning delivered under a tight format constraint.$$,
  6);

SELECT seed_interview('Legal',
  $$A client wants faster contract review using AI during a tight deal timeline. How do you approach it?$$,
  $$I would use AI for a first-pass redline to flag obvious issues quickly, but I would personally review every clause touching liability, termination, or payment before it goes back to the client - those are the clauses where a missed nuance actually costs money, so the time saved elsewhere gets reinvested there.$$,
  $$Balancing genuine speed gains with risk-weighted human review.$$,
  7);

SELECT seed_interview('Legal',
  $$Convince me the AI-drafted clause in front of us is safe to send without your review.$$,
  $$I would not try to convince you of that - even a well-drafted clause needs to be checked against this specific client's deal facts before it goes out. I can tell you what I would check first if that would help move things along faster.$$,
  $$Resisting pressure to overstate confidence in unreviewed output.$$,
  8);

SELECT seed_interview('Legal',
  $$An AI tool tells you a title deed is clear of any servitudes. How do you confirm that before advising a buyer?$$,
  $$I would pull the actual deed myself, and where needed the Deeds Office records, rather than relying on the AI summary - a missed servitude is exactly the kind of error that leads to a negligence claim down the line, and it is cheap to check properly before transfer but expensive to fix after.$$,
  $$A concrete, source-based verification habit rather than a general statement of caution.$$,
  9);

SELECT seed_interview('Legal',
  $$Why does an AI 'low risk' flag not end your FICA due diligence on a transaction?$$,
  $$Because my FICA due diligence obligations are personal and statutory - they sit with me as the accountable institution's representative, not with a tool's risk score. If something about the transaction looks unusual to me on the facts, I still have to raise it regardless of what the AI concluded.$$,
  $$Ownership of a statutory obligation independent of a tool's output.$$,
  10);

SELECT seed_interview('Legal',
  $$Why might you refuse to let AI draft a founding affidavit involving domestic abuse allegations, even if it could do so competently?$$,
  $$Beyond the confidentiality and physical safety risk of the information itself passing through an unapproved tool, a survivor's own words often carry particular weight in how an affidavit reads to a court - a generic AI tone can flatten that and undercut the very credibility the document needs to convey.$$,
  $$Judgement that goes beyond pure competence or drafting accuracy.$$,
  11);

SELECT seed_interview('Legal',
  $$AI recommends a standard 50/50 care arrangement. What would make you deviate from it?$$,
  $$Anything specific to this particular family that a standard template does not know about - shift work, a child's school logistics, or an existing routine the child depends on. The best-interests standard is about this specific child's circumstances, not the average case.$$,
  $$Applying the Children's Act best-interests standard to real, specific facts rather than a template.$$,
  12);

SELECT seed_interview('Legal',
  $$An AI tool says a transaction is 'compliant.' In one sentence, what is the first thing you would check?$$,
  $$Whether the AI actually applied the specific statutory test and shows its working, or just asserted compliance without demonstrating the calculation or analysis behind it.$$,
  $$Fast, accurate reasoning delivered under a tight format constraint.$$,
  13);

SELECT seed_interview('Legal',
  $$How would you explain to a partner why an AI 'compliant' flag on a BEE restructuring is not the end of the analysis?$$,
  $$I would explain that BEE compliance turns on substance - genuine economic interest, real voting rights, actual financial benefit - not just the shareholding percentages an automated check is likely to have looked at, so I would want to walk through the substance test myself before we sign off.$$,
  $$Communicating a technical limitation clearly to a senior stakeholder.$$,
  14);
