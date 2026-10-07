-- Verification — Finance (6 tasks)
-- Source: Finance_seed_data.docx (EASY 2 / MEDIUM 2 / COMPLEX 2).

SELECT seed_verification(
  'verification-finance-01', 'Finance',
  $$The Gross Profit Trap$$,
  $$You are a junior analyst. Your manager asked an AI to draft a quick income statement summary for a client presentation. The AI reports: Revenue R2,450,000; Cost of Sales R1,680,000; Gross Profit R870,000; Operating Expenses R320,000; Operating Profit R550,000, and concludes the company achieved a healthy gross margin. Review it before it goes out.$$,
  $$The arithmetic is wrong: R2,450,000 - R1,680,000 = R770,000, not R870,000. Gross profit is overstated by R100,000, and operating profit cascades to R450,000, not R550,000.$$,
  $$Recalculate gross profit (R770,000) and operating profit (R450,000), correct the summary, and only then send it to the client.$$,
  $$A R100,000 overstatement misrepresents profitability. If used in a loan application or investor pitch it could be a material misrepresentation. Verifying arithmetic before client delivery is non-negotiable.$$,
  'easy',
  $j$[
    {"label":"Recalculate: gross profit is R770,000 and operating profit R450,000, then correct the summary.","score":100},
    {"label":"Send it as-is; the AI figures look internally consistent.","score":0},
    {"label":"Fix only the operating profit and leave gross profit.","score":0},
    {"label":"Round the figures to the nearest R1,000 and present.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-finance-02', 'Finance',
  $$The Growth Rate That Isn't$$,
  $$You are preparing a quarterly performance report for a retail client. The AI calculated year-on-year revenue growth as (R9,450,000 / R8,200,000) x 100 = 115.2% and states the company achieved 115.2% revenue growth. Your manager needs it for the board in 30 minutes.$$,
  $$The formula is wrong. Dividing two numbers and multiplying by 100 gives revenue as a percentage of the prior year, not the growth rate. Correct: Growth = ((New - Old) / Old) x 100.$$,
  $$Recompute growth as ((9,450,000 - 8,200,000) / 8,200,000) x 100 = 15.24% and correct the board figure.$$,
  $$Telling a board that revenue grew 115% when it grew about 15% is catastrophic; board members make investment and staffing decisions off these figures.$$,
  'easy',
  $j$[
    {"label":"Recompute the growth rate as 15.24%.","score":100},
    {"label":"Present 115.2% growth as calculated.","score":0},
    {"label":"Present 15.2% but keep 115.2% as an 'index'.","score":0},
    {"label":"Report only the absolute increase of R1,250,000.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-finance-03', 'Finance',
  $$The Misclassified Loan Repayment$$,
  $$You are at a financial services firm. The AI drafted a Cash Flow Statement for a manufacturing client. Operating activities include 'Less: Repayment of bank loan (R500,000)', giving Net cash from operating activities of R1,040,000. Financing activities show only dividends paid (R200,000). It must be reviewed before inclusion in the annual financial statements.$$,
  $$The R500,000 loan repayment is misclassified as an operating activity. Under IAS 7, repayments of borrowings are financing activities, not day-to-day operations.$$,
  $$Move the R500,000 loan repayment to financing: operating becomes R1,540,000 and financing becomes (R700,000).$$,
  $$Operating cash flow is one of the most-watched metrics by analysts and lenders. Inflating it by burying loan repayments inside it creates a falsely healthy picture.$$,
  'medium',
  $j$[
    {"label":"Move the loan repayment to financing; operating becomes R1,540,000.","score":100},
    {"label":"Leave it; loan repayments are part of day-to-day operations.","score":0},
    {"label":"Move it to investing activities instead.","score":0},
    {"label":"Net it against the equipment purchase.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-finance-04', 'Finance',
  $$The Ratio That Doesn't Ratio$$,
  $$You are a graduate analyst at a bank's credit department. The AI calculated a small business's current ratio as Total Assets / Current Liabilities = R2,090,000 / R420,000 = 4.98 and recommends approving the loan. You must verify the ratios before the credit committee meets.$$,
  $$Wrong formula: the current ratio uses current assets only, not total assets. Including non-current assets (R1,200,000) overstates liquidity. Correct: R890,000 / R420,000 = 2.12.$$,
  $$Recompute the current ratio as 2.12 using current assets only, and re-assess the recommendation on the correct figure.$$,
  $$A credit officer approving a loan on a current ratio of 4.98 is deciding on wrong data. Using the wrong formula could miscalculate risk across the whole loan book.$$,
  'medium',
  $j$[
    {"label":"Recompute as 2.12 using current assets divided by current liabilities.","score":100},
    {"label":"Approve at 4.98; liquidity is excellent.","score":0},
    {"label":"Use total assets but subtract inventory.","score":0},
    {"label":"Reject the loan outright.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-finance-05', 'Finance',
  $$The Revenue That Wasn't Earned Yet$$,
  $$You are a junior accountant at a software company. A new enterprise client signed a 12-month software licence (R360,000, full payment upfront on 1 October 2025). The AI prepared the revenue recognition schedule for the CFO: it recognises R360,000 in October 2025, cites 'IFRS 15 basis: revenue recognized at the point the customer pays', and records Dr Bank R360,000 / Cr Revenue R360,000.$$,
  $$The AI misapplied IFRS 15. Revenue is recognised when performance obligations are satisfied, not when payment is received. A 12-month licence is delivered over time, so recognising all R360,000 in October is premature.$$,
  $$Recognise R30,000 per month (R360,000 / 12): record Dr Bank R360,000 / Cr Deferred Revenue R360,000, then release R30,000 to revenue each month.$$,
  $$Recognising R360,000 instead of R30,000 inflates Q4 2025 revenue by R330,000. For a listed company that misstates earnings and breaches IFRS 15, triggering audit findings.$$,
  'hard',
  $j$[
    {"label":"Recognise R30,000 per month and hold R360,000 as deferred revenue.","score":100},
    {"label":"Keep R360,000 in October because the cash was received.","score":0},
    {"label":"Recognise R360,000 but disclose it as prepaid.","score":0},
    {"label":"Split it 50/50 across FY2025 and FY2026.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-finance-06', 'Finance',
  $$The VAT Overclaim$$,
  $$You are at a tax advisory firm. A colleague used AI to calculate a manufacturing client's input VAT claim before submission to SARS. Tax period July-September 2025, VAT rate 15%. The AI totals expenditure at R1,835,000 (raw materials R240,000; machinery R850,000; staff salaries R380,000; client entertainment R45,000; passenger motor vehicle R320,000) and claims input VAT of R275,250.$$,
  $$Three items are blocked input credits under the VAT Act 89 of 1991: salaries and wages (not a VAT supply), entertainment (section 17(2)(a)), and a passenger motor car (section 17(2)(c)). Only raw materials and machinery qualify.$$,
  $$Claim only on R240,000 + R850,000 = R1,090,000, giving input VAT of R163,500. The AI overclaimed by R111,750.$$,
  $$An incorrect VAT claim is a compliance failure: SARS can impose penalties up to 200% plus interest, and prosecution if it is found to be intentional.$$,
  'hard',
  $j$[
    {"label":"Claim R163,500 - only raw materials and machinery qualify.","score":100},
    {"label":"Submit R275,250 as calculated.","score":0},
    {"label":"Claim on everything except salaries.","score":0},
    {"label":"Claim on everything except entertainment.","score":0}
  ]$j$::jsonb
);
