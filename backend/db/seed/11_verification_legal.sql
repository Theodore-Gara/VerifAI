-- Verification — Legal (6 tasks, one per practice area)
-- Source: VerifAI_Legal_Task_Bank_Expanded_FIXED.docx.

SELECT seed_verification(
  'verification-legal-01', 'Legal',
  $$The Nine Authorities You Can't Find$$,
  $$You are the associate reviewing heads of argument before they are filed in an urgent High Court application. The draft was prepared with an AI legal research tool and cites nine authorities. Working through them on SAFLII and Juta you can only locate two under the citations given - the other seven return no result, a different case, or a case that does not contain the proposition attributed to it. The filing deadline is two hours away.$$,
  $$Seven of the nine citations cannot be verified. AI-generated legal citations are frequently fabricated, and a fabricated authority undermines the credibility of the entire set, verified portions included.$$,
  $$Search each citation by exact name and citation on SAFLII and Juta; treat anything you cannot locate and read in full as unverified and do not file it. File only the heads built on the two verified authorities, strike the reasoning that depended on the rest, and escalate in writing to the supervising attorney.$$,
  $$This mirrors Northbound Processing (Pty) Ltd v The South African Diamond and Precious Metals Regulator, where fabricated citations were filed in an urgent application. Filing an authority you have not read is a serious breach of the duty owed to the court; an apology afterwards does not cure it.$$,
  'hard',
  $j$[
    {"label":"Verify each citation; file only the verified authorities and escalate in writing.","score":100},
    {"label":"File as-is; the citations look plausible and the deadline is tight.","score":0},
    {"label":"File now and raise the concern with the attorney afterwards.","score":0},
    {"label":"Replace the unverifiable citations with similar-looking cases.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-legal-02', 'Legal',
  $$The Ruling Built on Missing Authority$$,
  $$A disciplinary hearing chairperson has issued a written ruling dismissing three employees' procedural objection, citing case law in support of its reasoning. When you try to locate the cited authorities to advise your clients, you cannot find them under the citations given.$$,
  $$The ruling relies on authorities that cannot be verified. Reliance on non-existent or misdescribed authority is itself a recognised basis to challenge the ruling, separate from whether the underlying procedural point was correct.$$,
  $$Independently locate each authority via SAFLII or Juta; if one or more cannot be verified, raise it specifically as a ground for internal appeal or a CCMA referral.$$,
  $$This mirrors a 2025-2026 South African Labour Court matter (Matjhabeng Local Municipality) where a disciplinary chairperson's ruling relied on hallucinated authorities. AI-fabricated citations have reached quasi-judicial workplace decisions that determine whether ordinary employees keep their jobs.$$,
  'medium',
  $j$[
    {"label":"Verify the authorities; if unverifiable, raise it as a specific ground for appeal or referral.","score":100},
    {"label":"Accept the ruling; the chairperson decided the procedural point.","score":0},
    {"label":"Advise clients the procedural point is settled law.","score":0},
    {"label":"Ignore the citations; only the outcome matters.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-legal-03', 'Legal',
  $$The 'Standard' Arbitration Clause$$,
  $$An AI-generated legal opinion on a supply agreement states that its arbitration clause is 'enforceable and standard under South African law', and the commercial team wants to proceed to signature on the strength of that opinion without further legal review.$$,
  $$The opinion describes how the clause reads, not whether it satisfies the Arbitration Act 42 of 1965's formal validity requirements: that the agreement to arbitrate is in writing, that the scope of disputes is defined, that there is a workable mechanism for appointing arbitrator(s), and that the seat and rules are specified.$$,
  $$Check the clause directly against the Arbitration Act's formal requirements before signature; for a cross-border counterparty, separately confirm whether international arbitration rules or the International Arbitration Act 15 of 2017 apply.$$,
  $$An unenforceable arbitration clause typically only becomes apparent at the point of an actual dispute - when the client can least afford the clause to fail. That deferred, asymmetric cost is exactly what professional review exists to catch before signature.$$,
  'medium',
  $j$[
    {"label":"Check the clause against the Arbitration Act's formal requirements before signing.","score":100},
    {"label":"Sign; the AI opinion says it is enforceable and standard.","score":0},
    {"label":"Sign but note to review the clause if a dispute arises.","score":0},
    {"label":"Remove the arbitration clause entirely.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-legal-04', 'Legal',
  $$The Servitude That Wasn't Disclosed$$,
  $$An AI document-review tool summarises a title deed for a property under transfer and states that the property is 'free of any registered servitudes'. On pulling the actual deed and cross-checking the Deeds Office records yourself, you find a registered right-of-way servitude in favour of a neighbouring property that the AI summary did not mention.$$,
  $$The AI summary missed a registered servitude. A servitude registered against a title deed is binding on successive owners regardless of whether it was disclosed to the buyer.$$,
  $$Cross-check the summary against the actual deed and Deeds Office records; flag the servitude to the buyer, explain how it may affect the buyer's intended use of the property, and confirm informed acceptance before transfer proceeds.$$,
  $$An unnoticed servitude can materially affect what the buyer is legally entitled to do with the land and can expose the conveyancer to a professional negligence claim. It is cheap to check before transfer and expensive to fix after.$$,
  'medium',
  $j$[
    {"label":"Flag the servitude to the buyer and confirm informed acceptance before transfer.","score":100},
    {"label":"Rely on the AI summary; it reviewed the deed.","score":0},
    {"label":"Proceed to transfer; the servitude is the neighbour's concern.","score":0},
    {"label":"Ask the buyer to waive all servitude claims.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-legal-05', 'Legal',
  $$The Judgment That Doesn't Exist$$,
  $$AI-drafted correspondence prepared for a divorce matter references 'the recent Constitutional Court judgment on spousal maintenance' in support of a position being put to the other side, without giving a case name or citation. Before this claim is repeated to the client as settled law, or relied on in negotiation, you need to establish whether such a judgment actually exists.$$,
  $$Vague, unattributed references to 'a recent judgment' without a case name are a recognisable AI hallucination pattern: confident enough to sound authoritative but too vague to check at a glance.$$,
  $$Search SAFLII and the Constitutional Court's published judgment list for a matching judgment; if none can be found, treat the claim as unverified and remove it from the correspondence.$$,
  $$A client told their spouse's obligations changed under a Constitutional Court judgment that does not exist may make real decisions - accepting a settlement, abandoning a position - based on law that is not there.$$,
  'easy',
  $j$[
    {"label":"Verify on SAFLII and the ConCourt list; if no such judgment exists, remove the claim.","score":100},
    {"label":"Repeat the claim; it sounds authoritative.","score":0},
    {"label":"Soften it to 'recent case law' and keep it.","score":0},
    {"label":"Ask the AI for the citation and rely on it.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-legal-06', 'Legal',
  $$The Assertion Without the Test$$,
  $$An AI-generated legal opinion states that a proposed share buy-back by a client company 'complies with section 48 of the Companies Act 71 of 2008', but the opinion does not walk through the solvency and liquidity test applied to the company's current financial position - it simply asserts the conclusion.$$,
  $$Section 48 requires the actual solvency and liquidity test (read with section 4) applied to the company's real, current financial statements. A bare assertion of compliance is not evidence that the calculation was performed.$$,
  $$Request or perform the solvency and liquidity test on the company's current financials, document the figures relied on, and record the outcome as part of the final opinion.$$,
  $$Directors who approve a buy-back on the strength of an unsubstantiated compliance assertion are exposed to personal liability if the section 48 test was not actually met.$$,
  'medium',
  $j$[
    {"label":"Perform the section 48 solvency and liquidity test on the financials and document it.","score":100},
    {"label":"Accept the opinion; it cites section 48.","score":0},
    {"label":"Proceed and rely on the auditor's next review.","score":0},
    {"label":"Ask the AI to confirm the test was applied.","score":0}
  ]$j$::jsonb
);
