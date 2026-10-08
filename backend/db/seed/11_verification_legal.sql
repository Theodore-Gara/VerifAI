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

-- ===========================================================================
-- Additional line_text tasks (9) — VerifAI_Legal_Verification_Tasks.pdf
-- ===========================================================================

SELECT seed_verification_text(
  'verification-legal-07', 'Legal', $$The Ten-Year Debt$$,
  $$You are a candidate attorney. A client wants to sue for an unpaid invoice. AI wrote the prescription note below on 20 October 2026.$$,
  'easy',
  ARRAY[
    $$MEMO - Collection of unpaid invoice$$,
    $$Client: Dlamini Packaging (Pty) Ltd   Debtor: Karoo Foods CC$$,
    $$Invoice dated 15 March 2021, payable within 30 days (due 14 April 2021).$$,
    $$No summons issued. No written acknowledgement of debt by the debtor.$$,
    $$$$,
    $$Prescription: ordinary commercial debts prescribe after 10 years under$$,
    $$the Prescription Act 68 of 1969. The debt runs until 14 April 2031, so$$,
    $$the claim is still valid and we can issue summons now.$$
  ],
  ARRAY[6, 7, 8],
  $$Lines 6 to 8. The wrong prescription period. Ten years is not the general period for an ordinary commercial debt.$$,
  $$The general period is 3 years (Prescription Act, section 11(d)), running from the date the debt is due (section 12). The debt fell due on 14 April 2021, so it prescribed on 14 April 2024 unless interrupted. Neither summons nor acknowledgement happened, so the claim has prescribed.$$,
  $$Issuing summons on a prescribed debt invites a successful plea of prescription and an adverse costs order, and the client has relied on bad advice. The 30-year limit applies only to special debts such as judgment debts.$$,
  ARRAY[$$3 years|three years$$, $$section 11$$, $$14 april 2024$$, $$prescribed$$],
  ARRAY[$$interrupt$$, $$costs$$, $$prescription act$$, $$plea$$, $$summons$$]
);

SELECT seed_verification_text(
  'verification-legal-08', 'Legal', $$The 90-Day Referral$$,
  $$You work in the labour department of a law firm. A dismissed employee came to see you. AI summarised the referral deadline for the partner.$$,
  'easy',
  ARRAY[
    $$To: Partner      Re: Mr T. Naidoo, dismissed 12 October 2026$$,
    $$$$,
    $$Mr Naidoo was dismissed for alleged misconduct on 12 October 2026.$$,
    $$An unfair dismissal dispute must be referred to the CCMA within 90 days$$,
    $$of the date of dismissal. The deadline is therefore 10 January 2027.$$,
    $$There is no urgency: we can collect his documents in December.$$
  ],
  ARRAY[4, 5],
  $$Lines 4 to 5. The 90-day period is the wrong one for a dismissal dispute.$$,
  $$An unfair dismissal must be referred to the CCMA within 30 days of the date of dismissal (LRA section 191(1)(b)(i)). The deadline is 11 November 2026. The 90-day period applies to unfair labour practice disputes; a late referral needs condonation.$$,
  $$Believing there are 90 days means the referral could be filed about two months late. The employee then has to apply for condonation and may lose the case on the delay alone.$$,
  ARRAY[$$30 days|thirty days$$, $$11 november$$, $$section 191$$],
  ARRAY[$$condonation$$, $$unfair labour practice$$, $$late$$, $$ccma$$]
);

SELECT seed_verification_text(
  'verification-legal-09', 'Legal', $$The Two-Week Notice$$,
  $$You are drafting a termination letter for an employer. AI produced the notice paragraph. The employee has worked for the company since 1 March 2023 and the letter is dated 15 October 2026.$$,
  'easy',
  ARRAY[
    $$Dear Ms Pillay,$$,
    $$$$,
    $$Mavuso Logistics is terminating your employment for operational reasons.$$,
    $$You have been employed with us since 1 March 2023.$$,
    $$Under section 37 of the Basic Conditions of Employment Act you are$$,
    $$entitled to two weeks' notice. Your last day will be 29 October 2026.$$
  ],
  ARRAY[5, 6],
  $$Lines 5 to 6. The notice period is too short for an employee with more than a year of service.$$,
  $$Under BCEA section 37(1), an employee employed for more than one year is entitled to at least four weeks' notice (unless the contract or a collective agreement gives longer). Ms Pillay has over 3 years' service, so she must receive at least four weeks' notice, with a last day of 12 November 2026 at the earliest.$$,
  $$Too short a notice period is a breach of the BCEA. The employer would have to pay the shortfall, and it adds to the risk of a challenge to the whole termination process.$$,
  ARRAY[$$four weeks|4 weeks$$, $$section 37$$],
  ARRAY[$$more than one year$$, $$notice pay$$, $$breach$$, $$bcea$$]
);

SELECT seed_verification_text(
  'verification-legal-10', 'Legal', $$The Severance Estimate$$,
  $$Your firm acts for an employer retrenching staff for operational reasons. AI prepared the severance calculation for one employee and described it as the legal minimum.$$,
  'medium',
  ARRAY[
    $$Retrenchment summary - Ms L. Zulu$$,
    $$Monthly salary: R22,000     Completed years of service: 6$$,
    $$Reason for dismissal: operational requirements$$,
    $$$$,
    $$Statutory severance (BCEA section 41): one month's pay per completed$$,
    $$year of service.$$,
    $$R22,000 x 6 = R132,000$$,
    $$Offer: R132,000, which is the statutory minimum.$$
  ],
  ARRAY[5, 6, 7, 8],
  $$Lines 5 to 8. The statutory severance minimum is not one month's pay per year. The AI mixed it up with a common contractual or negotiated figure.$$,
  $$BCEA section 41 sets the minimum at one week's remuneration for each completed year of service. Weekly pay = R22,000 x 12 / 52 = R5,076.92. Severance minimum = R5,076.92 x 6 = R30,461.54. An offer of R132,000 is well above the statutory minimum.$$,
  $$Calling R132,000 the minimum misleads the client about its obligations and sets a high anchor in negotiations, costing the employer about R101,500 more than the law requires.$$,
  ARRAY[$$one week|1 week$$, $$30,461|30461$$, $$completed year$$],
  ARRAY[$$section 41$$, $$minimum$$, $$operational requirements$$, $$bcea$$]
);

SELECT seed_verification_text(
  'verification-legal-11', 'Legal', $$The Cooling-Off Claim$$,
  $$You work for a retailer's legal adviser. A customer wants her money back for a TV she bought in-store and no longer wants. AI wrote the advice below.$$,
  'medium',
  ARRAY[
    $$Client: Hi-Fi House (Pty) Ltd     Query: refund for a TV$$,
    $$Facts: TV bought in-store on 2 October 2026 and taken home the same day.$$,
    $$On 6 October the customer changed her mind. The TV works and is unused.$$,
    $$$$,
    $$Advice: Under section 16 of the Consumer Protection Act 68 of 2008 a$$,
    $$consumer may cancel any purchase within 5 business days without giving$$,
    $$a reason or paying a penalty. Hi-Fi House must refund her in full.$$
  ],
  ARRAY[5, 6, 7],
  $$Lines 5 to 7. Section 16 does not give a cooling-off right on every purchase.$$,
  $$The 5-business-day cooling-off right in CPA section 16 applies to transactions resulting from direct marketing (door-to-door or telephone sales), not ordinary in-store purchases. There is no general statutory right to return a working item bought in a shop; the customer's position depends on the store's own returns policy. Statutory remedies for in-store goods apply to defects (section 56).$$,
  $$Advising the retailer to refund every change-of-mind purchase would cost it money it does not owe, and it could also mislead the customer about her rights.$$,
  ARRAY[$$direct marketing$$, $$returns policy$$, $$in-store|in store$$],
  ARRAY[$$section 16$$, $$section 56$$, $$defect$$, $$cooling-off|cooling off$$]
);

SELECT seed_verification_text(
  'verification-legal-12', 'Legal', $$The 72-Hour Grace Period$$,
  $$A medical group discovered unauthorised access to patient records. You asked AI for advice on when it must notify the Information Regulator and patients.$$,
  'medium',
  ARRAY[
    $$Client: Sunrise Medical Group   Incident: unauthorised access to patient files$$,
    $$Discovered: Tuesday 6 October 2026, 09:00$$,
    $$$$,
    $$Advice: POPIA gives a responsible party 72 hours from discovery before$$,
    $$any notification is required. Complete the internal investigation first$$,
    $$and notify the Information Regulator and patients on Friday.$$
  ],
  ARRAY[4, 5, 6],
  $$Lines 4 to 6. This treats 72 hours as a legal grace period under POPIA.$$,
  $$POPIA section 22 requires notification of the Regulator and affected data subjects as soon as reasonably possible after discovery. There is no fixed hour limit or grace period in the Act. The 72-hour rule is a hard deadline in the EU GDPR, and the Regulator uses about 72 hours only as a benchmark. Only the time reasonably needed to establish the scope of the compromise and restore system integrity is allowed.$$,
  $$Deliberately waiting until Friday risks breaching section 22. The Information Regulator has issued enforcement notices for late notification, and patients need to be told quickly so they can protect themselves.$$,
  ARRAY[$$as soon as reasonably possible$$, $$section 22$$, $$no fixed$$],
  ARRAY[$$gdpr$$, $$benchmark$$, $$data subjects$$, $$regulator$$, $$delay$$]
);

SELECT seed_verification_text(
  'verification-legal-13', 'Legal', $$The Misread Judgment$$,
  $$You are reviewing AI-drafted heads of argument. The insurer is relying on a clause that bars any claim not brought within 90 days of repudiation. Your client wants to argue the clause is unenforceable. The AI cites a real Constitutional Court case, but you must check what it actually decided.$$,
  'hard',
  ARRAY[
    $$HEADS OF ARGUMENT (draft) - paragraph 14$$,
    $$The insurer relies on clause 9.2, which bars any claim not instituted$$,
    $$within 90 days of repudiation. The clause is unenforceable. In$$,
    $$Barkhuizen v Napier 2007 (5) SA 323 (CC) the Constitutional Court held$$,
    $$that contractual time-limit clauses are contrary to public policy and$$,
    $$cannot be enforced.$$
  ],
  ARRAY[3, 4, 5, 6],
  $$Lines 3 to 6. The case is real but it is described as supporting the opposite of what it decided.$$,
  $$In Barkhuizen v Napier the Constitutional Court held that time-limitation clauses are not inherently contrary to public policy. A court asks whether the clause is reasonable, and whether enforcing it would be unreasonable in the circumstances. The 90-day clause in that case was found reasonable and the claim failed, so the authority is adverse to the client unless the facts can be distinguished.$$,
  $$Misstating a case to the court is a serious professional risk and the opposing side will read the judgment. Heads of argument must deal honestly with adverse authority, so read the judgment itself on SAFLII rather than rely on an AI summary.$$,
  ARRAY[$$not contrary to public policy|not inherently$$, $$reasonable$$, $$adverse$$],
  ARRAY[$$read the judgment|read the case$$, $$saflii$$, $$court$$, $$distinguish$$, $$verify$$]
);

SELECT seed_verification_text(
  'verification-legal-14', 'Legal', $$The Quick Retrenchment$$,
  $$A client wants to retrench staff for operational reasons. You ask AI which procedure applies and how long the process takes.$$,
  'hard',
  ARRAY[
    $$Client: Cape Fabrics (Pty) Ltd - 120 employees$$,
    $$Plan: retrench 15 machine operators for operational reasons.$$,
    $$$$,
    $$Procedure: this is a standard section 189 retrenchment. Issue the$$,
    $$s189(3) notice, consult for 30 days, then issue notices of termination$$,
    $$on day 31. A facilitator and strike rights do not apply.$$
  ],
  ARRAY[4, 5, 6],
  $$Lines 4 to 6. With these numbers the large-scale procedure in section 189A applies, not just section 189.$$,
  $$Section 189A applies to an employer with more than 50 employees that contemplates dismissing at least 10 employees (where it employs up to 200). Cape Fabrics has 120 employees and plans 15 dismissals. Notice of termination may not be given until at least 60 days have passed from the section 189(3) notice. A CCMA facilitator can be requested, and employees may strike or approach the Labour Court.$$,
  $$Issuing termination notices on day 31 makes the process procedurally unfair and invites an urgent Labour Court application to stop it (section 189A(13)). The client could face delay, costs and compensation orders.$$,
  ARRAY[$$189a$$, $$60 days|sixty days$$, $$large-scale|large scale$$, $$at least 10$$],
  ARRAY[$$facilitator$$, $$strike$$, $$labour court$$, $$procedurally unfair$$, $$notice of termination$$]
);

SELECT seed_verification_text(
  'verification-legal-15', 'Legal', $$The Runaway Interest$$,
  $$A lender's attorney asks AI to draft a letter of demand for a business loan in default. No summons has been issued yet. You review the figures.$$,
  'hard',
  ARRAY[
    $$LETTER OF DEMAND (draft) - Mazibuko Finance v Ndlovu Builders CC$$,
    $$Capital outstanding on loan:                 R150,000$$,
    $$Arrear interest accrued to date:             R210,000$$,
    $$Total amount due:                            R360,000$$,
    $$Interest continues to accrue at the contract rate until payment.$$
  ],
  ARRAY[3, 4, 5],
  $$Lines 3 to 5. The claim ignores the in duplum rule, which caps arrear interest at the amount of the unpaid capital.$$,
  $$Under the in duplum rule, arrear interest stops running once it equals the unpaid capital. Interest is capped at R150,000, so the most the lender can claim is R150,000 + R150,000 = R300,000, not R360,000, and interest should not continue to accrue in the meantime.$$,
  $$Demanding more than the law allows exposes the lender to a challenge, a costs order and a loss of credibility. The rule is a long-standing one that protects borrowers from interest running without limit.$$,
  ARRAY[$$in duplum$$, $$150,000|150000$$, $$300,000|300000$$],
  ARRAY[$$capital$$, $$stops$$, $$double$$, $$cap$$, $$accru$$]
);
