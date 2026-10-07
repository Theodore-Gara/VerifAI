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
