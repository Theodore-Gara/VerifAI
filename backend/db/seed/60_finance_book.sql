-- VerifAI AI Lab — Finance textbook.
-- Structure: book > chapter (parent_id NULL) > topic > subtopic.
-- Original text, adapted only from CC BY / public-domain sources (see links at
-- the end). Idempotent: the book upserts by code and its sections, questions
-- and source links are replaced on every run.

INSERT INTO lab_lessons (code, track_id, title, summary, estimated_minutes, level, is_original, competency, sort_order)
VALUES
  ('finance-book', (SELECT id FROM industry_tracks WHERE name = 'Finance'),
   'Finance: a working textbook',
   'Budgeting, statements, ratios, the time value of money and how to verify the numbers an AI hands you.',
   60, 1, FALSE, 'Verification', 110)
ON CONFLICT (code) DO UPDATE SET
  track_id = EXCLUDED.track_id, title = EXCLUDED.title, summary = EXCLUDED.summary,
  estimated_minutes = EXCLUDED.estimated_minutes, level = EXCLUDED.level,
  competency = EXCLUDED.competency, sort_order = EXCLUDED.sort_order;

-- Retire the old two-lesson finance material; its content is folded in below as
-- the "AI in finance" chapter.
DELETE FROM lab_lessons WHERE code IN ('finance-read-the-numbers', 'finance-verify-a-forecast');

DELETE FROM lab_lesson_sections WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'finance-book');

-- Chapters ------------------------------------------------------------------
INSERT INTO lab_lesson_sections (lesson_id, heading, body, parent_id, sort_order)
SELECT l.id, v.heading, v.body, NULL, v.sort_order
FROM lab_lessons l, (VALUES
  ('The finance function', 'What finance does in a business, and the goal it works towards.', 1),
  ('Financial statements', 'The three statements that describe a business and how they fit together.', 2),
  ('Financial analysis', 'Turning the numbers into ratios that support a decision.', 3),
  ('The time value of money', 'Why a rand today is worth more than a rand next year.', 4),
  ('Capital budgeting and working capital', 'Choosing investments and keeping enough cash to operate.', 5),
  ('AI in finance', 'How to read and verify the financial numbers an AI produces.', 6)
) AS v(heading, body, sort_order)
WHERE l.code = 'finance-book';

-- Topics --------------------------------------------------------------------
INSERT INTO lab_lesson_sections (lesson_id, heading, body, parent_id, sort_order)
SELECT l.id, v.heading, v.body, ch.id, v.tsort
FROM lab_lessons l,
(VALUES
  ('The finance function', 'The goal of finance', 'Finance keeps the business solvent and directs money to its best use.', 1),
  ('The finance function', 'Financial decisions', 'Investment, financing and dividend choices are the three core decisions.', 2),
  ('The finance function', 'Profit, cash and value', 'Profit is a measure; cash is a fact; value is the point.', 3),

  ('Financial statements', 'The income statement', 'Performance over a period: revenue less costs to reach profit.', 1),
  ('Financial statements', 'The balance sheet', 'A snapshot at a point in time: what is owned, owed and invested.', 2),
  ('Financial statements', 'The cash flow statement', 'Where cash actually came from and where it went.', 3),

  ('Financial analysis', 'Liquidity ratios', 'Can the business meet its short-term obligations?', 1),
  ('Financial analysis', 'Profitability ratios', 'How much profit is earned from sales and from capital?', 2),
  ('Financial analysis', 'Leverage ratios', 'How much of the business is funded by debt, and can it be serviced?', 3),

  ('The time value of money', 'Compounding', 'Money grows when interest is earned on interest.', 1),
  ('The time value of money', 'Discounting', 'Future money is worth less today after the required return is applied.', 2),
  ('The time value of money', 'Annuities', 'A series of equal payments at regular intervals.', 3),

  ('Capital budgeting and working capital', 'Appraising an investment', 'NPV, IRR and payback rank competing uses of capital.', 1),
  ('Capital budgeting and working capital', 'The cash conversion cycle', 'How long cash is tied up before it returns.', 2),
  ('Capital budgeting and working capital', 'Sources of finance', 'Equity and debt, short term and long term.', 3),

  ('AI in finance', 'Reading AI-written financial summaries', 'Treat an AI summary as a draft to be traced, not a source to be trusted.', 1),
  ('AI in finance', 'Verifying an AI revenue forecast', 'Audit the assumptions behind a forecast before you act on it.', 2)
) AS v(chapter, heading, body, tsort),
lab_lesson_sections ch
WHERE l.code = 'finance-book'
  AND ch.lesson_id = l.id AND ch.parent_id IS NULL AND ch.heading = v.chapter;

-- Subtopics -----------------------------------------------------------------
INSERT INTO lab_lesson_sections (lesson_id, heading, body, parent_id, sort_order)
SELECT l.id, v.heading, v.body, tp.id, v.ssort
FROM lab_lessons l,
(VALUES
  ('The finance function', 'The goal of finance', 'Surviving and creating value',
   'A business must first stay solvent - pay its bills as they fall due - and then put its capital to work where it earns the best risk-adjusted return. Finance is the function that plans, raises and allocates that capital.', 1),
  ('The finance function', 'The goal of finance', 'Stakeholders and the objective',
   'Owners want value, lenders want repayment, employees want security, and the state wants tax. A sound finance function balances these claims; the working objective is usually to maximise the long-term value of the owners'' stake.', 2),
  ('The finance function', 'Financial decisions', 'Investment, financing and distribution',
   'The investment decision asks which assets to buy; the financing decision asks how to fund them; the distribution decision asks how much profit to return to owners. Each changes the risk and the value of the business.', 1),
  ('The finance function', 'Financial decisions', 'The agency problem',
   'Managers and owners do not always want the same things. Good governance - reporting, oversight and incentives - keeps decisions aligned with the owners'' interests.', 2),
  ('The finance function', 'Profit, cash and value', 'Profit is not cash',
   'A business can show a profit and still run out of cash if customers pay late or stock is bought upfront. Profit records earned income; cash records money in the bank.', 1),
  ('The finance function', 'Profit, cash and value', 'Value is forward-looking',
   'Value reflects the expected future cash flows, their timing and their risk. Two businesses with the same profit this year can be worth very different amounts.', 2),

  ('Financial statements', 'The income statement', 'Revenue to profit',
   'The income statement starts with revenue, subtracts the cost of sales to reach gross profit, then deducts operating expenses, interest and tax to reach net profit. It reports performance over a period such as a year.', 1),
  ('Financial statements', 'The income statement', 'Accrual versus cash',
   'Income is recorded when it is earned, not when the cash arrives. That is why revenue can rise while the bank balance falls.', 2),
  ('Financial statements', 'The balance sheet', 'Assets, liabilities and equity',
   'Assets are what the business owns or is owed; liabilities are what it owes; equity is the owners'' residual interest. It is a snapshot at a single date, not a flow over time.', 1),
  ('Financial statements', 'The balance sheet', 'The accounting equation',
   'Assets equal liabilities plus equity, always. Every transaction keeps the equation in balance; if it appears not to, a figure is missing or misread.', 2),
  ('Financial statements', 'The cash flow statement', 'Operating, investing and financing',
   'Operating cash flow comes from trading; investing from buying and selling assets; financing from raising and repaying capital. Together they explain the change in cash for the period.', 1),
  ('Financial statements', 'The cash flow statement', 'Why it exists',
   'Because profit uses accruals, the cash flow statement reconciles profit back to actual cash. It is the statement most resistant to accounting presentation choices.', 2),

  ('Financial analysis', 'Liquidity ratios', 'Current and quick ratio',
   'The current ratio divides current assets by current liabilities; the quick ratio removes inventory, the least liquid current asset. A low ratio signals a risk of not meeting short-term obligations.', 1),
  ('Financial analysis', 'Liquidity ratios', 'Working capital',
   'Working capital is current assets minus current liabilities. It funds the day-to-day gap between paying for inputs and collecting from customers.', 2),
  ('Financial analysis', 'Profitability ratios', 'Margins',
   'Gross margin is gross profit over revenue; net margin is net profit over revenue. Margins show how much of each rand of sales survives as profit.', 1),
  ('Financial analysis', 'Profitability ratios', 'Return on equity',
   'Return on equity divides net profit by owners'' equity. It rewards shareholders, but a high figure can come from heavy borrowing rather than good trading.', 2),
  ('Financial analysis', 'Leverage ratios', 'Debt to equity',
   'Debt to equity compares borrowed funds with owners'' funds. More debt magnifies both gains and losses, and adds a fixed interest obligation.', 1),
  ('Financial analysis', 'Leverage ratios', 'Interest cover',
   'Interest cover divides operating profit by interest expense. It measures how comfortably earnings can absorb the interest bill before trouble begins.', 2),

  ('The time value of money', 'Compounding', 'Future value',
   'Future value grows the present amount by the interest rate for each period: FV = PV x (1 + r)^n. The exponent is the number of periods, and interest earns interest.', 1),
  ('The time value of money', 'Compounding', 'Frequency matters',
   'Interest compounded more often, or at a higher rate, produces a larger future value over the same time. Always confirm the rate and the compounding period before comparing figures.', 2),
  ('The time value of money', 'Discounting', 'Present value',
   'Present value reverses compounding: PV = FV / (1 + r)^n. It answers what a future amount is worth today at the required return.', 1),
  ('The time value of money', 'Discounting', 'Choosing the rate',
   'The discount rate should reflect the risk of the cash flows and the return available elsewhere. A higher rate makes future cash less valuable today.', 2),
  ('The time value of money', 'Annuities', 'Ordinary annuities',
   'An annuity is a series of equal payments at regular intervals. Its present value is the sum of each payment discounted to today, usually using the annuity factor.', 1),
  ('The time value of money', 'Annuities', 'Perpetuities',
   'A perpetuity pays forever; its present value is the payment divided by the rate. It is a useful approximation for long-lived, stable cash flows.', 2),

  ('Capital budgeting and working capital', 'Appraising an investment', 'Net present value',
   'NPV discounts all of a project''s cash flows to today at the required return and subtracts the initial cost. A positive NPV means the project is expected to beat the required return.', 1),
  ('Capital budgeting and working capital', 'Appraising an investment', 'IRR and payback',
   'The internal rate of return is the discount rate that makes NPV zero; payback is the time to recover the initial cost. IRR can be misleading with unusual cash flows, and payback ignores value after the cut-off.', 2),
  ('Capital budgeting and working capital', 'The cash conversion cycle', 'Days inventory and debtors',
   'Days inventory outstanding plus days sales outstanding measures how long cash sits in stock and in unpaid invoices before it returns.', 1),
  ('Capital budgeting and working capital', 'The cash conversion cycle', 'Days payables',
   'Days payables outstanding is subtracted, because holding supplier money longer frees cash. CCC = inventory days + debtor days - creditor days.', 2),
  ('Capital budgeting and working capital', 'Sources of finance', 'Equity and debt',
   'Equity is owners'' money - no repayment obligation, but a claim on value. Debt is borrowed - cheaper and tax-deductible, but must be repaid with interest.', 1),
  ('Capital budgeting and working capital', 'Sources of finance', 'Matching term to need',
   'Short-term needs - working capital - suit short-term finance such as an overdraft; long-term assets suit long-term finance. Mismatching the two creates avoidable risk.', 2),

  ('AI in finance', 'Reading AI-written financial summaries', 'What the summary leaves out',
   'An AI summary often drops the reporting period, the currency and whether a figure is audited or an estimate. Before trusting a number, find where it came from and when it applies.', 1),
  ('AI in finance', 'Reading AI-written financial summaries', 'A ratio needs a benchmark',
   'Liquidity, leverage and profitability ratios only mean something next to a comparison - a prior period, a peer or a target. A ratio on its own is a bare number, not a conclusion.', 2),
  ('AI in finance', 'Reading AI-written financial summaries', 'A rand today is not a rand next year',
   'Any figure that spans time must state its discount rate and period, or the comparison is meaningless. Value, not just count.', 3),
  ('AI in finance', 'Verifying an AI revenue forecast', 'The assumptions are the forecast',
   'A forecast is only as good as its inputs. List them explicitly: the growth rate, the cost base, the market size and the exact data range used.', 1),
  ('AI in finance', 'Verifying an AI revenue forecast', 'When the input is stale',
   'A model projecting forward from last year''s data misses structural change. Ask what has happened since the data ends - a new entrant, a rate change, a supply shock.', 2)
) AS v(chapter, topic, heading, body, ssort),
lab_lesson_sections ch,
lab_lesson_sections tp
WHERE l.code = 'finance-book'
  AND ch.lesson_id = l.id AND ch.parent_id IS NULL AND ch.heading = v.chapter
  AND tp.lesson_id = l.id AND tp.parent_id = ch.id AND tp.heading = v.topic;

-- End-of-book questions -----------------------------------------------------
DELETE FROM lab_questions WHERE lesson_id = (SELECT id FROM lab_lessons WHERE code = 'finance-book');
INSERT INTO lab_questions (lesson_id, prompt, options, correct_index, explanation, sort_order)
SELECT l.id, v.prompt, v.options::jsonb, v.correct_index, v.explanation, v.sort_order
FROM lab_lessons l, (VALUES
  ('An AI summary states "profit up 12%" with no period or source. What is the responsible first step?',
   '["Accept it - it is a specific number","Find the reporting period and source before relying on it","Round it to the nearest whole number"]', 1,
   'A number without a period and source cannot be verified. Locate both first.', 1),
  ('Which comparison is safe to make without adjustment?',
   '["Cash today versus cash in three years","Two figures from the same period and currency","Last year''s rand versus this year''s with no inflation note"]', 1,
   'Figures from the same period and currency are directly comparable; the others need a time-value adjustment.', 2),
  ('A forecast is built on data that ends before a major new competitor entered the market. What does that most affect?',
   '["The font of the report","The validity of the growth assumption","Nothing - forecasts are always accurate"]', 1,
   'Stale inputs invalidate the growth assumption, which drives the whole forecast.', 3),
  ('What is the most responsible way to use an AI forecast you cannot fully audit?',
   '["Present it as a certainty","Label it provisional and state the unverified assumptions","Delete it without comment"]', 1,
   'Communicate the uncertainty and the gaps rather than implying false confidence.', 4),
  ('Which statement reports performance over a period?',
   '["The income statement","The balance sheet","The cash flow statement"]', 0,
   'The income statement reports performance over a period; the balance sheet is a snapshot.', 5),
  ('Which equation must always hold on the balance sheet?',
   '["Assets = liabilities - equity","Assets = liabilities + equity","Equity = assets + liabilities"]', 1,
   'Assets always equal liabilities plus equity.', 6),
  ('Which ratio removes inventory from current assets?',
   '["The current ratio","The quick ratio","The net margin"]', 1,
   'The quick ratio excludes inventory, the least liquid current asset.', 7),
  ('A positive NPV means the project...',
   '["Earns less than the required return","Is expected to beat the required return","Only breaks even"]', 1,
   'Positive NPV means the project is expected to beat the required return.', 8),
  ('The cash conversion cycle equals inventory days plus debtor days minus...',
   '["Creditor days","Cash days","Tax days"]', 0,
   'CCC = inventory days + debtor days - creditor days.', 9),
  ('Which of these is debt rather than equity?',
   '["A bank loan","Share capital","Retained earnings"]', 0,
   'Debt carries a repayment obligation with interest; equity does not.', 10)
) AS v(prompt, options, correct_index, explanation, sort_order)
WHERE l.code = 'finance-book';

-- Source links --------------------------------------------------------------
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'adapted', 'Condensed into a working textbook and added South African rand examples.'
FROM lab_lessons l, content_sources cs
WHERE l.code = 'finance-book' AND cs.title = 'Financial Management for Small Businesses'
ON CONFLICT DO NOTHING;
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'adapted', 'Simplified the ratio and time-value explanations for a working textbook.'
FROM lab_lessons l, content_sources cs
WHERE l.code = 'finance-book' AND cs.title = 'Introduction to Financial Analysis'
ON CONFLICT DO NOTHING;
INSERT INTO lesson_sources (lesson_id, source_id, use_type, changes_made)
SELECT l.id, cs.id, 'adapted', 'Adapted the corporate-finance chapters on capital budgeting and the finance function.'
FROM lab_lessons l, content_sources cs
WHERE l.code = 'finance-book' AND cs.title = 'Corporate Finance'
ON CONFLICT DO NOTHING;
