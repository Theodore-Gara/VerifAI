-- Verification — Business Consulting (6 tasks, new)
-- Real-world grounded: 2025-26 Big Four AI-hallucination incidents (Deloitte, EY,
-- KPMG, PwC) where AI-fabricated citations, statistics and case studies shipped
-- in published consulting reports.

SELECT seed_verification(
  'verification-bc-01', 'Business Consulting',
  $$The Report That Doesn't Exist$$,
  $$You are reviewing an AI-drafted client report. It cites a 'McKinsey Loyalty Economics Report' as the source for a statistic about loyalty points. You search for the report and cannot find any such publication.$$,
  $$The cited source appears not to exist. This is a fabricated citation - the exact failure that forced EY, KPMG and Deloitte to withdraw published reports in 2025-2026.$$,
  $$Remove the statistic unless it can be traced to a real, verifiable source. Treat any uncited or untraceable number as a draft, not a fact.$$,
  $$Fabricated citations survive review because they read fluently - a hallucinated citation is not incoherent, so reviewers trained on human failure modes miss it. Only source verification catches it.$$,
  'medium',
  $j$[
    {"label":"Remove the claim unless it can be traced to a real, verifiable source.","score":100},
    {"label":"Keep it; the report name looks credible.","score":0},
    {"label":"Replace 'McKinsey' with 'industry research'.","score":0},
    {"label":"Ask the AI for the report link and keep the claim.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-bc-02', 'Business Consulting',
  $$The Market Size Built on a Phantom Number$$,
  $$An AI-generated market-entry deck sizes the client's opportunity using a '$200 billion global loyalty economy' figure. The number has no traceable source but anchors the entire investment case.$$,
  $$The market-size figure is untraceable. A fabricated TAM propagates into every downstream recommendation, valuation and decision.$$,
  $$Trace every market figure to a primary source; if it cannot be traced, replace it or clearly label it as an assumption rather than a fact.$$,
  $$A hallucinated TAM flows into valuations and exit theses. In the real EY case the fabricated $200 billion figure was absorbed by AI tools and recirculated as fact - the contamination spread far beyond the original report.$$,
  'medium',
  $j$[
    {"label":"Trace it to a primary source or clearly label it as an assumption.","score":100},
    {"label":"Use it; the number is widely cited online.","score":0},
    {"label":"Round it down slightly to be safe.","score":0},
    {"label":"Attribute it vaguely to 'market estimates'.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-bc-03', 'Business Consulting',
  $$The Growth Rate That Isn't$$,
  $$An AI-drafted client brief states a target company's revenue grew 118% year on year. The working shows the AI calculated (current / prior) x 100 using R9.4m and R8.0m.$$,
  $$The formula is wrong. Dividing current by prior and multiplying by 100 gives revenue as a percentage of the prior year, not the growth rate. Correct: ((current - prior) / prior) x 100.$$,
  $$Recompute growth as ((9.4 - 8.0) / 8.0) x 100 = 17.5% and correct the brief.$$,
  $$A roughly ten-fold overstatement of growth can mislead a client's investment or expansion decision and damage the firm's credibility.$$,
  'easy',
  $j$[
    {"label":"Recompute the growth rate as 17.5%.","score":100},
    {"label":"Report 118% as calculated.","score":0},
    {"label":"Report 18% but keep 118% as an 'index'.","score":0},
    {"label":"Report only the absolute increase.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-bc-04', 'Business Consulting',
  $$The 'Broad Agreement' That Wasn't$$,
  $$You interviewed 12 managers at a client. An AI summary prepared for the steering committee states that 'managers broadly agree the main problem is the legacy system'. Re-reading your notes, only five of the twelve mentioned it and three disagreed.$$,
  $$The AI overstated agreement. Five of twelve is not 'broad agreement', and three managers disagreed.$$,
  $$Correct the summary to reflect what the managers actually said, and check every claim about consensus against the notes before it goes to the client.$$,
  $$Overstated consensus misleads decision-makers into acting on a mandate that does not exist. You are accountable for what the client reads.$$,
  'medium',
  $j$[
    {"label":"Correct the summary to reflect the actual responses before the client sees it.","score":100},
    {"label":"Send it; the AI summarised the notes.","score":0},
    {"label":"Change 'broadly agree' to 'some agree'.","score":0},
    {"label":"Add a disclaimer that the summary is AI-generated.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-bc-05', 'Business Consulting',
  $$Comparing Apples to Oranges$$,
  $$An AI-drafted competitor benchmark compares three companies' revenue growth. It uses a different financial year for one company and converts another company's figures to rand at an unstated exchange rate.$$,
  $$The comparison mixes reporting periods and applies an unstated FX rate, so the growth figures are not comparable across the three companies.$$,
  $$Align every company to the same period and a stated exchange rate before comparing, or flag the inconsistency explicitly.$$,
  $$Inconsistent periods and currencies make a benchmark meaningless - the ranking can flip once the figures are aligned, leading to the wrong conclusion.$$,
  'medium',
  $j$[
    {"label":"Align periods and a stated FX rate, then re-compare.","score":100},
    {"label":"Present it; the direction of growth is roughly right.","score":0},
    {"label":"Remove the odd company from the comparison.","score":0},
    {"label":"Add a footnote about the exchange rate and keep it.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-bc-06', 'Business Consulting',
  $$The Case Study the Client Disputes$$,
  $$An AI-drafted thought-leadership piece names a client and claims a specific AI outcome for them. The named client publicly disputes the claim, and the underlying interview it supposedly draws on was never conducted.$$,
  $$The named case study is misattributed or fabricated. Naming a real company without a verified, consented basis is a reputational and legal risk.$$,
  $$Remove or correct the case study unless it is backed by a verified, consented source, and get client sign-off before naming anyone.$$,
  $$KPMG had to pull a report after named companies disputed their own 'case studies'. Fabricated attribution destroys trust and invites claims - the brand name does the work that verification never did.$$,
  'medium',
  $j$[
    {"label":"Remove it unless it is backed by a verified, consented source.","score":100},
    {"label":"Keep it; the client is named in public sources.","score":0},
    {"label":"Anonymise the client name and keep the claim.","score":0},
    {"label":"Attribute it to 'a leading retailer'.","score":0}
  ]$j$::jsonb
);

-- ===========================================================================
-- Additional line_text tasks (9) — VerifAI_Business_Consulting_Verification_Tasks.pdf
-- ===========================================================================

SELECT seed_verification_text(
  'verification-bc-07', 'Business Consulting', $$The 3% Market Share$$,
  $$You are preparing a steering committee pack for a retail client. AI wrote the headline for the market share slide.$$,
  'easy',
  ARRAY[
    $$Market share update - Q3 2026$$,
    $$Client market share: 12% (Q3 2025)  ->  15% (Q3 2026)$$,
    $$Headline: "Market share grew 3% year on year"$$,
    $$Recommendation: continue current strategy.$$
  ],
  ARRAY[3],
  $$Line 3. A move from 12% to 15% is 3 percentage points, not 3%.$$,
  $$Market share rose by 3 percentage points. In relative terms that is growth of 25% ((15 - 12) / 12). The headline should say "up 3 percentage points (a 25% increase)".$$,
  $$"3%" reads as a small change when the client gained a quarter more share. Mixing percentage points with percentages is one of the most common slips in consulting decks, and executives notice it.$$,
  ARRAY[$$3 percentage points|three percentage points$$, $$25%|25 percent$$],
  ARRAY[$$percentage points$$, $$relative$$, $$misleading$$, $$understate$$]
);

SELECT seed_verification_text(
  'verification-bc-08', 'Business Consulting', $$The 112% Pie Chart$$,
  $$You are checking a revenue-by-region slide for a client. The chart labels sit next to a table of amounts. AI wrote the slide text.$$,
  'easy',
  ARRAY[
    $$FY2026 revenue by region (total R84.0m)$$,
    $$Gauteng            R31.9m    38%$$,
    $$Western Cape       R18.5m    22%$$,
    $$KwaZulu-Natal      R16.0m    19%$$,
    $$Eastern Cape        R9.2m    11%$$,
    $$Other               R8.4m    22%$$,
    $$Total                        112%$$
  ],
  ARRAY[6],
  $$Line 6. The percentages add up to 112%, and the 'Other' share does not match its rand amount.$$,
  $$Other = R8.4m / R84.0m = 10%, not 22% (it was copied from the Western Cape line). The shares then add up to 100%: 38 + 22 + 19 + 11 + 10.$$,
  $$A chart whose labels do not total 100% is visibly wrong and damages the client's trust in every other number in the pack. A thirty-second check of totals catches it.$$,
  ARRAY[$$10%|10 percent$$, $$8.4$$],
  ARRAY[$$100%$$, $$sum$$, $$total$$, $$copied$$, $$check$$]
);

SELECT seed_verification_text(
  'verification-bc-09', 'Business Consulting', $$The Average Growth Rate$$,
  $$You are writing the growth section of an investor pack. AI calculated the client's yearly growth from 2021 to 2025.$$,
  'easy',
  ARRAY[
    $$Revenue 2021: R50m      Revenue 2025: R80m$$,
    $$Total growth: (80 - 50) / 50 = 60%$$,
    $$Average annual growth: 60% / 4 years = 15% per year$$,
    $$Headline: "15% growth every year since 2021"$$
  ],
  ARRAY[3, 4],
  $$Lines 3 to 4. Dividing total growth by the number of years ignores compounding.$$,
  $$Compound annual growth rate = (80 / 50)^(1/4) - 1 = 12.5% a year. At 15% a year, R50m would grow to about R87.5m by 2025, not R80m.$$,
  $$Overstating the growth rate flatters the business and misleads investors. The compound rate is the standard way to express growth across several years.$$,
  ARRAY[$$12.5%|12.5 percent|cagr$$, $$compound$$],
  ARRAY[$$compounding$$, $$simple average$$, $$overstate$$, $$four years$$]
);

SELECT seed_verification_text(
  'verification-bc-10', 'Business Consulting', $$The Monthly Market$$,
  $$A client is considering an online grocery start-up. You are sizing the market bottom-up. AI produced the estimate for a slide.$$,
  'medium',
  ARRAY[
    $$Adults in South Africa (18+):                     40 million$$,
    $$Share who shop for groceries online:              2%  ->  0.8 million$$,
    $$Average spend per online shopper:                 R850 per month$$,
    $$Market size = 0.8m x R850 = R680 million per year$$
  ],
  ARRAY[4],
  $$Line 4. The R850 spend is monthly but the result is labelled as a yearly figure.$$,
  $$Annual market = 0.8 million x R850 x 12 = R8.16 billion a year, not R680 million. R680 million is the monthly figure.$$,
  $$The market is understated by a factor of 12. A start-up deciding whether to enter, and how much to invest, would be working from the wrong scale. Always check that units (monthly or annual) are consistent.$$,
  ARRAY[$$x 12|times 12|\\* 12$$, $$8.16$$, $$annual$$],
  ARRAY[$$monthly$$, $$units$$, $$annualise|annualize$$, $$12$$]
);

SELECT seed_verification_text(
  'verification-bc-11', 'Business Consulting', $$The Break-Even Shortcut$$,
  $$You are advising a coffee-shop franchise client on how many cups it must sell to break even. AI performed the calculation.$$,
  'medium',
  ARRAY[
    $$Fixed costs: R450,000 per month$$,
    $$Selling price per cup: R120$$,
    $$Variable cost per cup: R45$$,
    $$$$,
    $$Break-even units = Fixed costs / Selling price$$,
    $$                 = R450,000 / R120$$,
    $$                 = 3,750 cups per month$$
  ],
  ARRAY[5, 6, 7],
  $$Lines 5 to 7. Break-even divides fixed costs by the contribution per unit, not by the price.$$,
  $$Contribution per cup = R120 - R45 = R75. Break-even = R450,000 / R75 = 6,000 cups a month (revenue of R720,000). At 3,750 cups the client would lose about R168,750 a month.$$,
  $$Each sale first has to cover its own variable cost, so only the contribution reduces fixed costs. The AI figure is 37.5% too low, and a client acting on it would open the shop thinking it is profitable when it is not.$$,
  ARRAY[$$6,000|6000$$, $$contribution$$, $$75$$],
  ARRAY[$$variable cost$$, $$price minus variable$$, $$understate$$, $$loss$$]
);

SELECT seed_verification_text(
  'verification-bc-12', 'Business Consulting', $$The Negative NPS$$,
  $$You are summarising a customer survey for a telecoms client. 200 customers answered: 90 scored 9 or 10 (promoters), 70 scored 7 or 8 (passives) and 40 scored 0 to 6 (detractors). AI calculated the Net Promoter Score.$$,
  'medium',
  ARRAY[
    $$Responses: 200$$,
    $$Promoters (9-10):   90  = 45%$$,
    $$Passives (7-8):     70  = 35%$$,
    $$Detractors (0-6):   40  = 20%$$,
    $$$$,
    $$NPS = % promoters - (% passives + % detractors)$$,
    $$    = 45% - 55%$$,
    $$    = -10$$,
    $$Conclusion: customer loyalty is poor.$$
  ],
  ARRAY[6, 7, 8, 9],
  $$Lines 6 to 9. NPS only subtracts detractors from promoters. Passives are left out of the calculation.$$,
  $$NPS = % promoters - % detractors = 45% - 20% = +25. A positive score. The "poor loyalty" conclusion is not supported.$$,
  $$A client could launch an unnecessary rescue programme, or lose confidence in a service that is doing reasonably well. Knowing how standard metrics are defined, and recalculating them, is part of the job.$$,
  ARRAY[$$\\+25|25$$, $$detractors$$],
  ARRAY[$$passives$$, $$promoters minus detractors$$, $$excluded$$, $$definition$$]
);

SELECT seed_verification_text(
  'verification-bc-13', 'Business Consulting', $$The Undiscounted NPV$$,
  $$A client is deciding whether to invest R2,000,000 in new equipment. It will bring in R800,000 a year for 4 years, and the client's cost of capital is 12%. AI calculated the net present value.$$,
  'hard',
  ARRAY[
    $$Investment today: R2,000,000$$,
    $$Cash inflow: R800,000 per year for 4 years$$,
    $$Discount rate: 12%$$,
    $$$$,
    $$NPV = total inflows - investment$$,
    $$    = (4 x R800,000) - R2,000,000$$,
    $$    = R1,200,000$$,
    $$Conclusion: strongly positive, approve.$$
  ],
  ARRAY[5, 6, 7, 8],
  $$Lines 5 to 8. The 12% discount rate is stated but never applied. The inflows are added up at face value.$$,
  $$Discount each year's inflow: PV of inflows = R800,000 x 3.0373 (the 4-year annuity factor at 12%) = about R2,429,879. NPV = R2,429,879 - R2,000,000 = about R429,880. Still positive, but about a third of the AI figure.$$,
  $$Ignoring the time value of money overstates the value of the project by almost three times and hides how sensitive the decision is. Recommending approval on R1.2m when the real cushion is much thinner is a serious error for a client investing R2m.$$,
  ARRAY[$$429$$, $$discount$$, $$present value$$],
  ARRAY[$$time value of money$$, $$undiscounted$$, $$overstate$$, $$sensitivity$$]
);

SELECT seed_verification_text(
  'verification-bc-14', 'Business Consulting', $$The Store to Close$$,
  $$A retail client wants to cut costs. You give AI the store results and ask for a recommendation. The AI recommends closing a store.$$,
  'hard',
  ARRAY[
    $$Store    Revenue    Operating profit$$,
    $$A        R40.0m     R2.0m$$,
    $$B        R30.0m     R1.2m$$,
    $$C        R12.0m     R2.4m$$,
    $$$$,
    $$Recommendation: close Store C. It has the lowest revenue (R12.0m)$$,
    $$and contributes the least to group sales. Closing it will cut costs.$$
  ],
  ARRAY[6, 7],
  $$Lines 6 to 7. The recommendation is based on revenue alone, not on profit.$$,
  $$Operating margins: A 5%, B 4%, C 20%. Store C is the most profitable, earning R2.4m of the group's R5.6m profit (about 43%) from only about 15% of revenue. Closing it would cut group profit from R5.6m to about R3.2m unless shared costs are reduced.$$,
  $$Revenue is not profit. A recommendation that destroys the best-performing store could cost the client millions and embarrass the firm. Always test whether a conclusion actually follows from the data in the table.$$,
  ARRAY[$$20%|20 percent$$, $$most profitable$$, $$2.4$$],
  ARRAY[$$revenue is not profit$$, $$margin$$, $$not supported$$, $$shared costs$$, $$avoidable$$]
);

SELECT seed_verification_text(
  'verification-bc-15', 'Business Consulting', $$The Real Growth$$,
  $$You are writing a performance review for a client whose revenue went from R120m (2024) to R138m (2026). Consumer price inflation was 5.3% in the first year and 4.4% in the second. AI wrote the summary.$$,
  'hard',
  ARRAY[
    $$Revenue 2024: R120m      Revenue 2026: R138m$$,
    $$Growth over two years: (138 - 120) / 120 = 15%$$,
    $$Summary: "The business grew 15% in real terms over two years,$$,
    $$well ahead of the market."$$
  ],
  ARRAY[3, 4],
  $$Lines 3 to 4. 15% is nominal growth. It has not been adjusted for inflation, but the summary calls it real growth.$$,
  $$Cumulative inflation = 1.053 x 1.044 - 1 = about 9.9%. Real growth = 1.15 / 1.0993 - 1 = about 4.6%. In 2024 rands, 2026 revenue is about R125.5m, not R138m.$$,
  $$Presenting nominal growth as real growth overstates performance by more than three times. In a high-inflation economy a client could think it is doing well while its real revenue barely moves.$$,
  ARRAY[$$4.6%|4.6 percent$$, $$real$$, $$inflation$$],
  ARRAY[$$nominal$$, $$cpi$$, $$deflate$$, $$purchasing power$$]
);
