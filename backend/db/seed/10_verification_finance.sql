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

-- ===========================================================================
-- Additional line_text tasks (9) — VerifAI_Finance_Verification_Tasks.pdf
-- ===========================================================================

SELECT seed_verification_text(
  'verification-finance-07', 'Finance', $$The Invoice VAT$$,
  $$You work in accounts receivable at an office-supplies distributor in Johannesburg. AI prepared a tax invoice that will be emailed to a customer in the next batch. The VAT rate is 15%.$$,
  'easy',
  ARRAY[
    $$TAX INVOICE  INV-2026-0418$$,
    $$Customer: Mokoena Legal Inc.$$,
    $$$$,
    $$Item                        Qty    Unit price      Line total$$,
    $$A4 paper (box of 5)          40       R185.00       R7,400.00$$,
    $$Toner cartridge              25       R200.00       R5,000.00$$,
    $$Subtotal (excl. VAT)                               R12,400.00$$,
    $$VAT @ 15%                                           R1,660.00$$,
    $$TOTAL DUE                                          R14,060.00$$
  ],
  ARRAY[8, 9],
  $$Lines 8 to 9. The VAT line is wrong and the total inherits the error. 15% of R12,400 is not R1,660.$$,
  $$VAT = R12,400 x 15% = R1,860.00. Total due = R12,400 + R1,860 = R14,260.00. The invoice is under-charged by R200.$$,
  $$A tax invoice with the wrong VAT understates the output VAT the company owes SARS and short-charges the customer by R200. The customer would also claim the wrong input VAT.$$,
  ARRAY[$$1,860|1860$$, $$14,260|14260$$, $$12,400 x 15|15% of 12,400|12400 x 15$$],
  ARRAY[$$output vat$$, $$sars$$, $$under-charged|undercharged|under charged$$, $$tax invoice$$, $$input vat$$]
);

SELECT seed_verification_text(
  'verification-finance-08', 'Finance', $$The Straight-Line Depreciation$$,
  $$At month-end for a Durban logistics company, AI prepared the depreciation entry for a new delivery truck. Company policy is straight-line depreciation over 5 years with a residual value of R60,000.$$,
  'easy',
  ARRAY[
    $$Asset:             Delivery truck (full-year charge)$$,
    $$Cost:              R480,000$$,
    $$Residual value:    R60,000$$,
    $$Useful life:       5 years$$,
    $$Method:            Straight-line$$,
    $$$$,
    $$Annual depreciation = Cost / Useful life$$,
    $$                    = R480,000 / 5$$,
    $$                    = R96,000$$,
    $$$$,
    $$Journal:  Dr Depreciation expense          R96,000$$,
    $$          Cr Accumulated depreciation      R96,000$$
  ],
  ARRAY[7, 8, 9],
  $$Lines 7 to 9. The formula ignores the residual value, so it depreciates the full cost instead of the depreciable amount.$$,
  $$Depreciable amount = Cost - Residual value = R480,000 - R60,000 = R420,000. Annual depreciation = R420,000 / 5 = R84,000.$$,
  $$Depreciation is calculated on cost less residual value (IAS 16). Overstating the charge understates profit and the carrying amount of the asset every year, and the error repeats across all five years.$$,
  ARRAY[$$84,000|84000$$, $$420,000|420000$$, $$residual value$$],
  ARRAY[$$depreciable amount$$, $$ias 16$$, $$overstated|overstate$$, $$profit$$, $$carrying amount$$]
);

SELECT seed_verification_text(
  'verification-finance-09', 'Finance', $$The Margin That Is Really a Markup$$,
  $$You are preparing a benchmarking slide for a retail client. AI calculated the client's gross margin and compared it with the industry average of 31%.$$,
  'easy',
  ARRAY[
    $$Revenue                         R850,000$$,
    $$Cost of sales                   R595,000$$,
    $$Gross profit                    R255,000$$,
    $$$$,
    $$Gross margin = Gross profit / Cost of sales$$,
    $$             = R255,000 / R595,000$$,
    $$             = 42.9%$$,
    $$$$,
    $$Industry average gross margin: 31%$$,
    $$Conclusion: the client's gross margin is well above the industry average.$$
  ],
  ARRAY[5, 6, 7, 10],
  $$Lines 5 to 7 and 10. Gross margin is divided by cost of sales, which gives the markup, not the margin, so the conclusion is wrong.$$,
  $$Gross margin = Gross profit / Revenue = R255,000 / R850,000 = 30.0%. The client is slightly below the 31% industry average, not well above it.$$,
  $$Margin and markup are easy to mix up, and here the mix-up flips the conclusion. A slide that says a client is outperforming the industry when it is slightly behind leads to the wrong advice.$$,
  ARRAY[$$30%|30.0|30 percent$$, $$revenue$$],
  ARRAY[$$markup$$, $$denominator$$, $$industry average$$, $$below$$, $$margin$$]
);

SELECT seed_verification_text(
  'verification-finance-10', 'Finance', $$The Bank Reconciliation$$,
  $$You are a graduate accountant at a manufacturing firm. AI prepared the 30 June bank reconciliation. It shows an unexplained difference and recommends a fraud investigation.$$,
  'medium',
  ARRAY[
    $$Bank reconciliation - 30 June 2026$$,
    $$Balance per bank statement                                 R81,600$$,
    $$Add:  Deposits in transit                                   R9,500$$,
    $$Add:  Unpresented cheques                                   R6,200$$,
    $$Adjusted bank balance                                      R97,300$$,
    $$$$,
    $$Balance per cash book                                      R84,300$$,
    $$Less: Bank charges not yet in cash book                     (R350)$$,
    $$Add:  Direct deposit not yet in cash book                     R950$$,
    $$Adjusted cash book balance                                 R84,900$$,
    $$$$,
    $$Difference                                                 R12,400$$,
    $$Status: UNEXPLAINED. Escalate for possible fraud investigation.$$
  ],
  ARRAY[4, 5],
  $$Lines 4 to 5. Unpresented cheques are added to the bank balance when they should be deducted. That creates the whole R12,400 difference.$$,
  $$Unpresented cheques are deducted: R81,600 + R9,500 - R6,200 = R84,900, which equals the adjusted cash book balance, so there is no difference to investigate.$$,
  $$Unpresented cheques are cheques already recorded in the cash book that the bank has not yet paid, so the bank balance is higher than the true position. Getting the direction wrong triggers a needless fraud alarm.$$,
  ARRAY[$$deduct|less|subtract$$, $$84,900|84900$$, $$less$$],
  ARRAY[$$unpresented$$, $$not yet paid|not yet cleared$$, $$cleared$$, $$reconcil$$, $$fraud$$]
);

SELECT seed_verification_text(
  'verification-finance-11', 'Finance', $$The Obsolete Stock$$,
  $$You are on the year-end audit file of a Cape Town electronics retailer. A new phone model launched in November and the previous generation is selling slowly. AI wrote the inventory valuation note.$$,
  'medium',
  ARRAY[
    $$Inventory at 31 December 2025$$,
    $$Standard lines (at cost)                  R850,000$$,
    $$Previous-generation phones (at cost)      R400,000$$,
    $$Total inventory at cost                 R1,250,000$$,
    $$$$,
    $$Previous-generation phones: expected selling price R360,000;$$,
    $$estimated costs to sell R40,000.$$,
    $$$$,
    $$Conclusion: IAS 2 requires inventory to be measured at cost.$$,
    $$Cost of R1,250,000 stands. No write-down is required.$$
  ],
  ARRAY[9, 10],
  $$Lines 9 to 10. IAS 2 does not say inventory is held at cost. It says inventory is measured at the lower of cost and net realisable value (NRV).$$,
  $$NRV of the old phones = R360,000 - R40,000 = R320,000, which is below their cost of R400,000. Write down by R80,000; inventory is carried at R1,170,000.$$,
  $$Leaving slow-moving stock at cost overstates assets and profit. Auditors check this area closely, and an unrecorded write-down is a common audit adjustment.$$,
  ARRAY[$$80,000|80000$$, $$1,170,000|1170000$$, $$net realisable value|nrv$$],
  ARRAY[$$lower of cost$$, $$ias 2$$, $$write-down|writedown|write down$$, $$overstate$$]
);

SELECT seed_verification_text(
  'verification-finance-12', 'Finance', $$The Insurance Prepayment$$,
  $$A client pays its annual insurance premium on 1 October and has a 31 December year-end. AI prepared the journal and said no year-end adjustment is needed.$$,
  'medium',
  ARRAY[
    $$Premium paid 1 Oct 2025: R36,000 (12 months of cover to 30 Sep 2026)$$,
    $$Financial year-end: 31 December 2025$$,
    $$$$,
    $$Journal 1 October 2025:$$,
    $$  Dr Insurance expense      R36,000$$,
    $$  Cr Bank                   R36,000$$,
    $$$$,
    $$Year-end adjustment: none required. The full premium is an expense of$$,
    $$the year because it was paid during the year.$$
  ],
  ARRAY[5, 8, 9],
  $$Lines 5, 8 and 9. The whole premium is treated as an expense of the year because it was paid in the year. Only the part of the cover used by 31 December is an expense.$$,
  $$Only 3 months (October to December) are used: R36,000 x 3/12 = R9,000 is the expense. R27,000 is a prepayment (current asset). Year-end entry: Dr Prepaid insurance R27,000, Cr Insurance expense R27,000.$$,
  $$Accrual accounting matches expenses to the period in which the cover is used, not the period in which cash is paid. Expensing all R36,000 overstates expenses and understates profit by R27,000.$$,
  ARRAY[$$9,000|9000$$, $$27,000|27000$$, $$prepaid|prepayment$$],
  ARRAY[$$accrual$$, $$matching$$, $$expense overstated|overstates expense$$, $$profit understated|understates profit$$, $$3 months|three months$$]
);

SELECT seed_verification_text(
  'verification-finance-13', 'Finance', $$The Lease That Vanished$$,
  $$A Pretoria manufacturer signs a 3-year warehouse lease from 1 January 2026. Payments are R20,000 a month, paid at the end of each month. The incremental borrowing rate is 9% a year. AI wrote the accounting note.$$,
  'hard',
  ARRAY[
    $$Lease: warehouse, 36 months from 1 January 2026$$,
    $$Payments: R20,000 per month, paid at the end of each month$$,
    $$Incremental borrowing rate: 9% per year (0.75% per month)$$,
    $$$$,
    $$Treatment: rent is an operating expense.$$,
    $$  Each month: Dr Rent expense R20,000 / Cr Bank R20,000$$,
    $$  Annual rent expense: R240,000$$,
    $$  Balance sheet impact: none$$,
    $$  IFRS 16 disclosure: not required$$
  ],
  ARRAY[5, 6, 7, 8, 9],
  $$Lines 5 to 9. This is the old operating-lease treatment. IFRS 16 requires a lessee to put most leases on the balance sheet.$$,
  $$Recognise a lease liability and a right-of-use asset at the present value of the payments (about R628,936). Year-1 expense is depreciation of about R209,645 plus interest of about R48,847, about R258,492, not R240,000.$$,
  $$Leaving a R629k obligation off the balance sheet understates liabilities and makes gearing and debt covenants look better than they are. Lenders and auditors look for this, and IFRS 16 has applied since 2019.$$,
  ARRAY[$$right-of-use|right of use$$, $$lease liability$$, $$present value$$, $$628$$],
  ARRAY[$$ifrs 16$$, $$off balance sheet|off-balance$$, $$liabilities$$, $$gearing$$, $$covenant$$]
);

SELECT seed_verification_text(
  'verification-finance-14', 'Finance', $$The Unrevalued Payable$$,
  $$A South African company bought equipment from a Texas supplier. AI recorded the purchase and left the unpaid invoice unchanged at year-end because 'it is already recorded'.$$,
  'hard',
  ARRAY[
    $$Invoice: USD 50,000, dated 1 November 2025$$,
    $$Exchange rate on 1 Nov 2025: R18.20 per USD$$,
    $$Journal 1 Nov:  Dr Equipment            R910,000$$,
    $$                Cr Trade payables        R910,000$$,
    $$$$,
    $$Year-end 31 Dec 2025: spot rate R18.65 per USD$$,
    $$Trade payables remain at R910,000 because the invoice is already$$,
    $$recorded. No year-end adjustment is needed.$$
  ],
  ARRAY[7, 8],
  $$Lines 7 to 8. A foreign-currency payable is a monetary item. It must be retranslated at the closing rate at every reporting date.$$,
  $$Closing payable = USD 50,000 x R18.65 = R932,500. Record an exchange loss of R22,500 in profit or loss: Dr Foreign exchange loss R22,500, Cr Trade payables R22,500. The equipment stays at R910,000 (non-monetary, historical rate).$$,
  $$Ignoring the rand weakening understates the liability and hides a real FX loss. The unpaid invoice is also still exposed to further currency moves, which management should know about.$$,
  ARRAY[$$932,500|932500$$, $$22,500|22500$$, $$closing rate$$, $$exchange loss$$],
  ARRAY[$$monetary item$$, $$ias 21$$, $$historical rate$$, $$profit or loss$$]
);

SELECT seed_verification_text(
  'verification-finance-15', 'Finance', $$The Wrong Share Count$$,
  $$You are preparing the earnings per share (EPS) line for a mid-sized listed company with a 31 December year-end. New shares were issued at full market price during the year. AI divided profit by the closing number of shares.$$,
  'hard',
  ARRAY[
    $$Profit attributable to ordinary shareholders:   R12,000,000$$,
    $$Shares in issue at 1 January 2025:             4,000,000$$,
    $$Shares issued on 1 October 2025:               2,000,000$$,
    $$Shares in issue at 31 December 2025:           6,000,000$$,
    $$$$,
    $$EPS = Profit / Shares in issue at year-end$$,
    $$    = R12,000,000 / 6,000,000$$,
    $$    = R2.00 per share$$
  ],
  ARRAY[6, 7, 8],
  $$Lines 6 to 8. EPS must use the weighted average number of shares outstanding during the year, not the closing number.$$,
  $$Weighted average = 4,000,000 + (2,000,000 x 3/12) = 4,500,000. EPS = R12,000,000 / 4,500,000 = R2.67 per share, not R2.00.$$,
  $$The new shares were only in issue for 3 months and earned profit for 3 months, so they should count for 3 months. Using the closing number understates EPS by about 25%, which can change how investors read the results.$$,
  ARRAY[$$4,500,000|4500000$$, $$2.67$$, $$weighted average$$],
  ARRAY[$$ias 33$$, $$time$$, $$issued during the year$$, $$understate$$]
);
