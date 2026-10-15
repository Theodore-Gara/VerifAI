-- VerifAI AI Lab — capstone papers (multi-scenario, grouped questions).
-- Each paper uses three scenarios and six numbered Questions (1..6). A Question
-- is a group of sub-questions (x.1, x.2, ...) shown together on one page; the
-- app groups by payload.question_no. Every question repeats its scenario facts
-- so the answer can be found on the page. 75 marks, 90 minutes, 60% pass,
-- 3 attempts, 70 XP + 15 tokens + badge. Idempotent: assessments upsert by
-- code; questions are replaced. Marks sum to total_marks and every rubric sums
-- to its question marks.

INSERT INTO achievements (code, name, description) VALUES ('capstone-finance', 'Finance Capstone', 'Passed the Finance Capstone.')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

INSERT INTO lab_capstone_assessments
  (code, track_id, title, summary, scenario, instructions, total_marks, grade_bands,
   time_limit_seconds, pass_score, max_attempts, xp_reward, token_reward, achievement_code, sort_order)
VALUES ('cap-fin', (SELECT id FROM industry_tracks WHERE name = 'Finance'),
  'Finance Capstone', 'Three scenarios across six numbered questions: multiple-choice, short-answer, matching and one written answer.',
  '{"title":"Finance Capstone: three scenarios","background":"This paper uses three scenarios. Each Question tells you which scenario to use and repeats the figures you need.","facts":["Scenario 1: Mokoena Print Studio (Pty) Ltd","Scenario 2: Kopano Hardware Store","Case Study: Dlamini Couriers (Pty) Ltd: the depot expansion"]}'::jsonb,
  '["Answer ALL questions. The paper is worth 75 marks and has six numbered questions, each worth the marks shown, and must be completed in 90 minutes.","Each question belongs to one of three scenarios; the relevant figures are repeated with every question.","Multiple-choice, matching and short-answer questions are marked automatically. The written question is marked against a marking guide - write in full sentences for a non-specialist reader."]'::jsonb,
  75, '[{"label":"Distinction","min_percent":75},{"label":"Merit","min_percent":60},{"label":"Competent","min_percent":50},{"label":"Not yet competent","min_percent":0}]'::jsonb, 5400, 60, 3, 70, 15, 'capstone-finance', 10)
ON CONFLICT (code) DO UPDATE SET
  track_id = EXCLUDED.track_id, title = EXCLUDED.title, summary = EXCLUDED.summary,
  scenario = EXCLUDED.scenario, instructions = EXCLUDED.instructions, total_marks = EXCLUDED.total_marks,
  grade_bands = EXCLUDED.grade_bands, time_limit_seconds = EXCLUDED.time_limit_seconds,
  pass_score = EXCLUDED.pass_score, max_attempts = EXCLUDED.max_attempts,
  xp_reward = EXCLUDED.xp_reward, token_reward = EXCLUDED.token_reward,
  achievement_code = EXCLUDED.achievement_code, sort_order = EXCLUDED.sort_order;

DELETE FROM lab_capstone_questions WHERE assessment_id = (SELECT id FROM lab_capstone_assessments WHERE code = 'cap-fin');
INSERT INTO lab_capstone_questions
  (assessment_id, type, section, scenario, competency, cognitive_level, source_refs, prompt, payload, correct,
   explanation, rubric, model_answer, code_lines, word_limit, marks, marking, sort_order)
SELECT c.id, v.type, v.section, v.scenario, v.competency, v.cognitive_level, v.source_refs::jsonb, v.prompt,
       v.payload::jsonb, v.correct::jsonb, v.explanation, v.rubric::jsonb, v.model_answer,
       v.code_lines::jsonb, v.word_limit::jsonb, v.marks, v.marking, v.sort_order
FROM lab_capstone_assessments c, (VALUES
  ('numeric', 'Section A · Application', 'Mokoena Print Studio (Pty) Ltd

Thabo Mokoena owns a small print shop in Gauteng. He is considering buying a digital press and has asked you, as his finance adviser, to evaluate the purchase.

• The press costs R480,000 today and has no resale value after 4 years.
• It is expected to bring in net cash inflows of R160,000 at the end of each of the next 4 years.
• Thabo''s required return is 10% per year.
• The studio holds inventory for 45 days, customers pay after 60 days, and suppliers are paid after 30 days.

Expected cash flows of the press
Year | Cash flow
0 (today) | -R480,000
1 | +R160,000
2 | +R160,000
3 | +R160,000
4 | +R160,000', 'Capital budgeting', 'apply', '["FIN-01","FIN-03"]'::jsonb, '1.1 Evaluate the digital-press investment using the Mokoena Print Studio figures.', '{"question_no":1,"parts":[{"label":"(a)","prompt":"Calculate the present value of the four R160,000 inflows at a 10% required return (nearest rand).","marks":7,"unit":null},{"label":"(b)","prompt":"Calculate the net present value (NPV) of the press (nearest rand).","marks":8,"unit":null}]}'::jsonb, '{"parts":[{"answer":507178,"tolerance":100,"marks":7},{"answer":27178,"tolerance":100,"marks":8}]}'::jsonb, 'Annuity factor at 10% for 4 years = (1 - 1.1^-4) / 0.1 = 3.1699. PV = 160,000 x 3.1699 = R507,178. NPV = 507,178 - 480,000 = R27,178.', NULL, NULL, NULL, NULL, 15, 'auto', 1),
  ('multiple_choice', 'Section A · Application', 'Mokoena Print Studio (Pty) Ltd

Thabo Mokoena owns a small print shop in Gauteng. He is considering buying a digital press and has asked you, as his finance adviser, to evaluate the purchase.

• The press costs R480,000 today and has no resale value after 4 years.
• It is expected to bring in net cash inflows of R160,000 at the end of each of the next 4 years.
• Thabo''s required return is 10% per year.
• The studio holds inventory for 45 days, customers pay after 60 days, and suppliers are paid after 30 days.

Expected cash flows of the press
Year | Cash flow
0 (today) | -R480,000
1 | +R160,000
2 | +R160,000
3 | +R160,000
4 | +R160,000', 'Time value of money', 'apply', '["FIN-01"]'::jsonb, '1.2 Thabo considers an alternative to the press: putting R480,000 in a fixed deposit at 10% a year, compounded annually, for 2 years. What would it be worth at the end of year 2?', '{"question_no":1,"options":["R528,000","R576,000","R580,800","R600,000"]}'::jsonb, '{"answer_index":2}'::jsonb, 'Future value = 480,000 x (1.10)^2 = R580,800. Interest is earned on the interest as well, so the answer is more than a simple 20% rise.', NULL, NULL, NULL, NULL, 2, 'auto', 2),
  ('multiple_choice', 'Section A · Application', 'Mokoena Print Studio (Pty) Ltd

Thabo Mokoena owns a small print shop in Gauteng. He is considering buying a digital press and has asked you, as his finance adviser, to evaluate the purchase.

• The press costs R480,000 today and has no resale value after 4 years.
• It is expected to bring in net cash inflows of R160,000 at the end of each of the next 4 years.
• Thabo''s required return is 10% per year.
• The studio holds inventory for 45 days, customers pay after 60 days, and suppliers are paid after 30 days.

Expected cash flows of the press
Year | Cash flow
0 (today) | -R480,000
1 | +R160,000
2 | +R160,000
3 | +R160,000
4 | +R160,000', 'Capital budgeting', 'apply', '["FIN-01","FIN-03"]'::jsonb, '1.3 The press is expected to bring in R160,000 at the end of each of the next 4 years. What is the present value of these inflows at a required return of 10%?', '{"question_no":1,"options":["R480,000","R507,178","R576,000","R640,000"]}'::jsonb, '{"answer_index":1}'::jsonb, 'Annuity factor = (1 - 1.1^-4) / 0.1 = 3.1699. PV = 160,000 x 3.1699 = R507,178. The R640,000 simple total ignores the time value of money.', NULL, NULL, NULL, NULL, 2, 'auto', 3),
  ('multiple_choice', 'Section A · Application', 'Mokoena Print Studio (Pty) Ltd

Thabo Mokoena owns a small print shop in Gauteng. He is considering buying a digital press and has asked you, as his finance adviser, to evaluate the purchase.

• The press costs R480,000 today and has no resale value after 4 years.
• It is expected to bring in net cash inflows of R160,000 at the end of each of the next 4 years.
• Thabo''s required return is 10% per year.
• The studio holds inventory for 45 days, customers pay after 60 days, and suppliers are paid after 30 days.

Expected cash flows of the press
Year | Cash flow
0 (today) | -R480,000
1 | +R160,000
2 | +R160,000
3 | +R160,000
4 | +R160,000', 'Capital budgeting', 'apply', '["FIN-03"]'::jsonb, '1.4 The press costs R480,000 and the present value of its inflows is about R507,178. What is the NPV, and what does the NPV rule say Thabo should do?', '{"question_no":1,"options":["About R27,178, so reject the press","About -R27,178, so reject the press","About R160,000, so accept the press","About R27,178, so accept the press"]}'::jsonb, '{"answer_index":3}'::jsonb, 'NPV = 507,178 - 480,000 = R27,178. A positive NPV means the press is expected to earn more than the required return, so it should be accepted.', NULL, NULL, NULL, NULL, 2, 'auto', 4),
  ('multiple_choice', 'Section A · Application', 'Mokoena Print Studio (Pty) Ltd

Thabo Mokoena owns a small print shop in Gauteng. He is considering buying a digital press and has asked you, as his finance adviser, to evaluate the purchase.

• The press costs R480,000 today and has no resale value after 4 years.
• It is expected to bring in net cash inflows of R160,000 at the end of each of the next 4 years.
• Thabo''s required return is 10% per year.
• The studio holds inventory for 45 days, customers pay after 60 days, and suppliers are paid after 30 days.

Expected cash flows of the press
Year | Cash flow
0 (today) | -R480,000
1 | +R160,000
2 | +R160,000
3 | +R160,000
4 | +R160,000', 'Capital budgeting', 'analyse', '["FIN-03"]'::jsonb, '1.5 Thabo''s required return rises to 20%. At 20% the 4-year annuity factor is 2.5887. What is the NPV of the press now?', '{"question_no":1,"options":["About R65,800","About -R480,000","About R27,178","About -R65,800"]}'::jsonb, '{"answer_index":3}'::jsonb, 'PV = 160,000 x 2.5887 = about R414,200. NPV = 414,200 - 480,000 = about -R65,800, so the press would no longer be acceptable.', NULL, NULL, NULL, NULL, 2, 'auto', 5),
  ('multiple_choice', 'Section A · Application', 'Mokoena Print Studio (Pty) Ltd

Thabo Mokoena owns a small print shop in Gauteng. He is considering buying a digital press and has asked you, as his finance adviser, to evaluate the purchase.

• The press costs R480,000 today and has no resale value after 4 years.
• It is expected to bring in net cash inflows of R160,000 at the end of each of the next 4 years.
• Thabo''s required return is 10% per year.
• The studio holds inventory for 45 days, customers pay after 60 days, and suppliers are paid after 30 days.

Expected cash flows of the press
Year | Cash flow
0 (today) | -R480,000
1 | +R160,000
2 | +R160,000
3 | +R160,000
4 | +R160,000', 'Capital budgeting', 'analyse', '["FIN-03"]'::jsonb, '1.6 Which ONE change would INCREASE the NPV of the press?', '{"question_no":1,"options":["A lower purchase price","A higher required return","Smaller yearly cash inflows","Receiving each inflow one year later"]}'::jsonb, '{"answer_index":0}'::jsonb, 'A lower purchase price reduces the amount subtracted from the present value of the inflows. The other changes all lower the NPV.', NULL, NULL, NULL, NULL, 2, 'auto', 6),
  ('multiple_choice', 'Section A · Application', 'Mokoena Print Studio (Pty) Ltd

Thabo Mokoena owns a small print shop in Gauteng. He is considering buying a digital press and has asked you, as his finance adviser, to evaluate the purchase.

• The press costs R480,000 today and has no resale value after 4 years.
• It is expected to bring in net cash inflows of R160,000 at the end of each of the next 4 years.
• Thabo''s required return is 10% per year.
• The studio holds inventory for 45 days, customers pay after 60 days, and suppliers are paid after 30 days.

Expected cash flows of the press
Year | Cash flow
0 (today) | -R480,000
1 | +R160,000
2 | +R160,000
3 | +R160,000
4 | +R160,000', 'Working capital', 'apply', '["FIN-04"]'::jsonb, '2.1 The studio holds inventory for 45 days, customers pay after 60 days, and suppliers are paid after 30 days. What is its cash conversion cycle?', '{"question_no":2,"options":["15 days","75 days","105 days","135 days"]}'::jsonb, '{"answer_index":1}'::jsonb, 'CCC = days inventory + days sales outstanding - days payables = 45 + 60 - 30 = 75 days.', NULL, NULL, NULL, NULL, 2, 'auto', 7),
  ('multiple_choice', 'Section A · Application', 'Mokoena Print Studio (Pty) Ltd

Thabo Mokoena owns a small print shop in Gauteng. He is considering buying a digital press and has asked you, as his finance adviser, to evaluate the purchase.

• The press costs R480,000 today and has no resale value after 4 years.
• It is expected to bring in net cash inflows of R160,000 at the end of each of the next 4 years.
• Thabo''s required return is 10% per year.
• The studio holds inventory for 45 days, customers pay after 60 days, and suppliers are paid after 30 days.

Expected cash flows of the press
Year | Cash flow
0 (today) | -R480,000
1 | +R160,000
2 | +R160,000
3 | +R160,000
4 | +R160,000', 'Working capital', 'understand', '["FIN-04"]'::jsonb, '2.2 Why are payables (creditor) days SUBTRACTED when calculating the cash conversion cycle?', '{"question_no":2,"options":["Because they measure how long stock is held","Because suppliers pay the studio sooner","Because creditor days are always a cost","Because supplier credit delays the point at which cash leaves the business"]}'::jsonb, '{"answer_index":3}'::jsonb, 'Paying suppliers later means the studio keeps its cash for longer, which shortens the period its cash is tied up.', NULL, NULL, NULL, NULL, 2, 'auto', 8),
  ('multiple_choice', 'Section A · Application', 'Mokoena Print Studio (Pty) Ltd

Thabo Mokoena owns a small print shop in Gauteng. He is considering buying a digital press and has asked you, as his finance adviser, to evaluate the purchase.

• The press costs R480,000 today and has no resale value after 4 years.
• It is expected to bring in net cash inflows of R160,000 at the end of each of the next 4 years.
• Thabo''s required return is 10% per year.
• The studio holds inventory for 45 days, customers pay after 60 days, and suppliers are paid after 30 days.

Expected cash flows of the press
Year | Cash flow
0 (today) | -R480,000
1 | +R160,000
2 | +R160,000
3 | +R160,000
4 | +R160,000', 'Working capital', 'apply', '["FIN-04"]'::jsonb, '2.3 Thabo negotiates 45-day payment terms with his suppliers. Inventory days (45) and customer days (60) stay the same. What is the new cash conversion cycle?', '{"question_no":2,"options":["30 days","60 days","75 days","90 days"]}'::jsonb, '{"answer_index":1}'::jsonb, 'CCC = 45 + 60 - 45 = 60 days. Longer supplier terms shorten the cycle by 15 days.', NULL, NULL, NULL, NULL, 2, 'auto', 9),
  ('multiple_choice', 'Section A · Application', 'Mokoena Print Studio (Pty) Ltd

Thabo Mokoena owns a small print shop in Gauteng. He is considering buying a digital press and has asked you, as his finance adviser, to evaluate the purchase.

• The press costs R480,000 today and has no resale value after 4 years.
• It is expected to bring in net cash inflows of R160,000 at the end of each of the next 4 years.
• Thabo''s required return is 10% per year.
• The studio holds inventory for 45 days, customers pay after 60 days, and suppliers are paid after 30 days.

Expected cash flows of the press
Year | Cash flow
0 (today) | -R480,000
1 | +R160,000
2 | +R160,000
3 | +R160,000
4 | +R160,000', 'Working capital', 'apply', '["FIN-04"]'::jsonb, '2.4 Which ONE action would SHORTEN the studio''s cash conversion cycle?', '{"question_no":2,"options":["Offering a small discount to customers who pay within 30 days","Paying suppliers after 15 days instead of 30","Allowing customers 75 days to pay instead of 60","Buying extra paper and ink to hold in stock"]}'::jsonb, '{"answer_index":0}'::jsonb, 'An early-payment discount reduces the days customers take to pay. The other options all lengthen the cycle.', NULL, NULL, NULL, NULL, 2, 'auto', 10),
  ('multiple_choice', 'Section A · Application', 'Mokoena Print Studio (Pty) Ltd

Thabo Mokoena owns a small print shop in Gauteng. He is considering buying a digital press and has asked you, as his finance adviser, to evaluate the purchase.

• The press costs R480,000 today and has no resale value after 4 years.
• It is expected to bring in net cash inflows of R160,000 at the end of each of the next 4 years.
• Thabo''s required return is 10% per year.
• The studio holds inventory for 45 days, customers pay after 60 days, and suppliers are paid after 30 days.

Expected cash flows of the press
Year | Cash flow
0 (today) | -R480,000
1 | +R160,000
2 | +R160,000
3 | +R160,000
4 | +R160,000', 'Working capital', 'analyse', '["FIN-04","FIN-05"]'::jsonb, '2.5 Thabo must pay R480,000 for the press upfront. Why does the studio''s 75-day cash conversion cycle matter for this decision?', '{"question_no":2,"options":["It shows the press will pay for itself in 75 days","It only matters for businesses that hold no inventory","It replaces the need to calculate the NPV","Cash is tied up for about 75 days between paying for materials and collecting from customers, so he needs enough cash or finance to bridge it"]}'::jsonb, '{"answer_index":3}'::jsonb, 'A positive NPV does not guarantee enough cash. The cycle shows how long cash is locked in operations, which affects how much funding Thabo needs.', NULL, NULL, NULL, NULL, 2, 'auto', 11),
  ('multiple_choice', 'Section B · Scenario and case study', 'Kopano Hardware Store

Palesa Kopano owns a hardware store. Last year was busy, but she is worried because her bank account looks worse than her results suggest.

• The store reported a net profit of R120,000 last year.
• Its bank balance fell by R90,000 over the same year.
• The amount owed to the store by customers rose by R100,000, and stock on the shelves rose by R80,000.
• Inventory turnover fell from 8 times a year to 5 times a year.', 'Ratio analysis', 'apply', '["FIN-02"]'::jsonb, '3.1 Kopano has current assets of R350,000 and current liabilities of R280,000. What is its current ratio?', '{"question_no":3,"options":["0.80","1.25","1.60","5.00"]}'::jsonb, '{"answer_index":1}'::jsonb, 'Current ratio = current assets / current liabilities = 350,000 / 280,000 = 1.25.', NULL, NULL, NULL, NULL, 2, 'auto', 12),
  ('multiple_choice', 'Section B · Scenario and case study', 'Kopano Hardware Store

Palesa Kopano owns a hardware store. Last year was busy, but she is worried because her bank account looks worse than her results suggest.

• The store reported a net profit of R120,000 last year.
• Its bank balance fell by R90,000 over the same year.
• The amount owed to the store by customers rose by R100,000, and stock on the shelves rose by R80,000.
• Inventory turnover fell from 8 times a year to 5 times a year.', 'Ratio analysis', 'understand', '["FIN-02"]'::jsonb, '3.2 What does a current ratio of 1.25 tell Palesa?', '{"question_no":3,"options":["The store has R1.25 of current assets for every R1 of current liabilities, so it can cover its short-term debts","The store earns R1.25 of profit for every R1 of sales","The store owes R1.25 to lenders for every R1 of owner funds","The store sells and replaces its stock 1.25 times a year"]}'::jsonb, '{"answer_index":0}'::jsonb, 'The current ratio is a liquidity measure. Above 1 means current assets exceed current liabilities.', NULL, NULL, NULL, NULL, 2, 'auto', 13),
  ('multiple_choice', 'Section B · Scenario and case study', 'Kopano Hardware Store

Palesa Kopano owns a hardware store. Last year was busy, but she is worried because her bank account looks worse than her results suggest.

• The store reported a net profit of R120,000 last year.
• Its bank balance fell by R90,000 over the same year.
• The amount owed to the store by customers rose by R100,000, and stock on the shelves rose by R80,000.
• Inventory turnover fell from 8 times a year to 5 times a year.', 'Ratio analysis', 'apply', '["FIN-02"]'::jsonb, '3.3 Kopano has borrowings of R400,000 and owner''s equity of R500,000. What is its debt-to-equity ratio?', '{"question_no":3,"options":["0.20","0.80","1.25","2.40"]}'::jsonb, '{"answer_index":1}'::jsonb, 'Debt-to-equity = 400,000 / 500,000 = 0.80. The inverse (1.25) is a common wrong answer.', NULL, NULL, NULL, NULL, 2, 'auto', 14),
  ('multiple_choice', 'Section B · Scenario and case study', 'Kopano Hardware Store

Palesa Kopano owns a hardware store. Last year was busy, but she is worried because her bank account looks worse than her results suggest.

• The store reported a net profit of R120,000 last year.
• Its bank balance fell by R90,000 over the same year.
• The amount owed to the store by customers rose by R100,000, and stock on the shelves rose by R80,000.
• Inventory turnover fell from 8 times a year to 5 times a year.', 'Ratio analysis', 'apply', '["FIN-02"]'::jsonb, '3.4 Kopano''s sales were R2,400,000 and its net profit was R120,000. What is its net profit margin?', '{"question_no":3,"options":["2%","5%","20%","50%"]}'::jsonb, '{"answer_index":1}'::jsonb, 'Net profit margin = 120,000 / 2,400,000 = 5%, meaning 5 cents of profit from every rand of sales.', NULL, NULL, NULL, NULL, 2, 'auto', 15),
  ('multiple_choice', 'Section B · Scenario and case study', 'Kopano Hardware Store

Palesa Kopano owns a hardware store. Last year was busy, but she is worried because her bank account looks worse than her results suggest.

• The store reported a net profit of R120,000 last year.
• Its bank balance fell by R90,000 over the same year.
• The amount owed to the store by customers rose by R100,000, and stock on the shelves rose by R80,000.
• Inventory turnover fell from 8 times a year to 5 times a year.', 'Ratio analysis', 'apply', '["FIN-02"]'::jsonb, '4.1 Kopano''s cost of sales was R1,600,000 and its average inventory was R320,000. What is this year''s inventory turnover?', '{"question_no":4,"options":["0.2 times","5 times","8 times","12.5 times"]}'::jsonb, '{"answer_index":1}'::jsonb, 'Inventory turnover = cost of sales / average inventory = 1,600,000 / 320,000 = 5 times. Last year''s figure was 8.', NULL, NULL, NULL, NULL, 2, 'auto', 16),
  ('multiple_choice', 'Section B · Scenario and case study', 'Kopano Hardware Store

Palesa Kopano owns a hardware store. Last year was busy, but she is worried because her bank account looks worse than her results suggest.

• The store reported a net profit of R120,000 last year.
• Its bank balance fell by R90,000 over the same year.
• The amount owed to the store by customers rose by R100,000, and stock on the shelves rose by R80,000.
• Inventory turnover fell from 8 times a year to 5 times a year.', 'Profit vs cash', 'analyse', '["FIN-05"]'::jsonb, '4.2 Palesa earned a profit of R120,000, but her bank balance fell by R90,000. Which is the MOST plausible explanation?', '{"question_no":4,"options":["Depreciation was higher than last year","She paid suppliers later than last year","Cash is tied up in higher amounts owed by customers and in more stock","Customers paid faster than last year"]}'::jsonb, '{"answer_index":2}'::jsonb, 'Sales not yet collected and cash locked in stock reduce cash without reducing profit. Depreciation is non-cash, and later payments to suppliers or faster collections would raise cash.', NULL, NULL, NULL, NULL, 2, 'auto', 17),
  ('multiple_choice', 'Section B · Scenario and case study', 'Kopano Hardware Store

Palesa Kopano owns a hardware store. Last year was busy, but she is worried because her bank account looks worse than her results suggest.

• The store reported a net profit of R120,000 last year.
• Its bank balance fell by R90,000 over the same year.
• The amount owed to the store by customers rose by R100,000, and stock on the shelves rose by R80,000.
• Inventory turnover fell from 8 times a year to 5 times a year.', 'Profit vs cash', 'apply', '["FIN-05"]'::jsonb, '4.3 Start from the profit of R120,000. Receivables rose by R100,000 and inventory rose by R80,000. Ignoring all other items, what is the cash effect of these together?', '{"question_no":4,"options":["+R300,000","+R120,000","-R60,000","-R180,000"]}'::jsonb, '{"answer_index":2}'::jsonb, '120,000 - 100,000 - 80,000 = -R60,000. Increases in receivables and stock use cash.', NULL, NULL, NULL, NULL, 2, 'auto', 18),
  ('multiple_choice', 'Section B · Scenario and case study', 'Kopano Hardware Store

Palesa Kopano owns a hardware store. Last year was busy, but she is worried because her bank account looks worse than her results suggest.

• The store reported a net profit of R120,000 last year.
• Its bank balance fell by R90,000 over the same year.
• The amount owed to the store by customers rose by R100,000, and stock on the shelves rose by R80,000.
• Inventory turnover fell from 8 times a year to 5 times a year.', 'Profit vs cash', 'understand', '["FIN-05"]'::jsonb, '4.4 Which statement about profit and cash is CORRECT?', '{"question_no":4,"options":["Profit and cash are always the same number","Only loss-making businesses run out of cash","Cash can never be lower than profit","A profitable business can still run out of cash because of timing differences"]}'::jsonb, '{"answer_index":3}'::jsonb, 'Profit counts sales when they are made, but cash only moves when customers and suppliers are paid.', NULL, NULL, NULL, NULL, 2, 'auto', 19),
  ('matching', 'Section B · Scenario and case study', 'Kopano Hardware Store

Palesa Kopano owns a hardware store. Last year was busy, but she is worried because her bank account looks worse than her results suggest.

• The store reported a net profit of R120,000 last year.
• Its bank balance fell by R90,000 over the same year.
• The amount owed to the store by customers rose by R100,000, and stock on the shelves rose by R80,000.
• Inventory turnover fell from 8 times a year to 5 times a year.', 'Ratio analysis', 'apply', '["FIN-02","FIN-04"]'::jsonb, '4.5 Match each measure to what it mainly shows.', '{"question_no":4,"left":["Current ratio","Debt-to-equity ratio","Net profit margin","Inventory turnover","Cash conversion cycle"],"right":["Short-term liquidity","Financial leverage (borrowings against owner funds)","Profitability (profit as a share of sales)","How quickly stock is sold and replaced","Days cash is tied up between paying suppliers and collecting from customers"]}'::jsonb, '{"mapping":{"Current ratio":"Short-term liquidity","Debt-to-equity ratio":"Financial leverage (borrowings against owner funds)","Net profit margin":"Profitability (profit as a share of sales)","Inventory turnover":"How quickly stock is sold and replaced","Cash conversion cycle":"Days cash is tied up between paying suppliers and collecting from customers"}}'::jsonb, 'Each measure answers a different question: liquidity, leverage, profitability, stock efficiency and cash tied up in operations.', NULL, NULL, NULL, NULL, 5, 'auto', 20),
  ('multi_select', 'Section B · Scenario and case study', 'Dlamini Couriers (Pty) Ltd: the depot expansion

Sipho Dlamini runs a courier company. He is thinking of opening a new depot and used an AI assistant to summarise his position (see Question 5). You have been asked to review that summary and advise him in writing (see Question 6).

• The depot would cost R300,000 today and has no resale value after 3 years.
• It is expected to bring in net cash inflows of R120,000 at the end of each of the next 3 years.
• Sipho''s required return is 12% per year.
• Last year the company reported a net profit of R85,000, yet its bank balance fell by R40,000.
• Clients take about 75 days to pay their invoices.

Extract from Dlamini Couriers'' records
Item | Amount
Current assets | R160,000
Current liabilities | R200,000
Net profit last year | R85,000
Change in bank balance | -R40,000
Annual depot inflow (3 years) | R120,000
Depot cost today | R300,000', 'Verifying AI output', 'evaluate', '["FIN-01","FIN-02","FIN-03","FIN-04","FIN-05"]'::jsonb, '5.1 Sipho''s AI assistant drafted the statements below. Using the figures in the case study, select ALL statements that are INCORRECT.', '{"question_no":5,"options":["The depot''s NPV is about -R11,780, so at a 12% required return it should be rejected.","A current ratio of 0.8 shows that Dlamini Couriers can comfortably meet its short-term obligations.","Because the company made a profit of R85,000, its bank balance must have increased by R85,000.","If clients paid their invoices faster, the cash conversion cycle would become shorter."]}'::jsonb, '{"indices":[1,2]}'::jsonb, 'Statement 2 is wrong: current assets R160,000 / current liabilities R200,000 = 0.8, which is below 1, so liquidity is weak. Statement 3 is wrong: the bank balance actually fell by R40,000. Statements 1 and 4 are correct (PV of inflows is about R288,220, so NPV is about -R11,780).', NULL, NULL, NULL, NULL, 4, 'auto', 21),
  ('extended_response', 'Section B · Scenario and case study', 'Dlamini Couriers (Pty) Ltd: the depot expansion

Sipho Dlamini runs a courier company. He is thinking of opening a new depot and used an AI assistant to summarise his position (see Question 5). You have been asked to review that summary and advise him in writing (see Question 6).

• The depot would cost R300,000 today and has no resale value after 3 years.
• It is expected to bring in net cash inflows of R120,000 at the end of each of the next 3 years.
• Sipho''s required return is 12% per year.
• Last year the company reported a net profit of R85,000, yet its bank balance fell by R40,000.
• Clients take about 75 days to pay their invoices.

Extract from Dlamini Couriers'' records
Item | Amount
Current assets | R160,000
Current liabilities | R200,000
Net profit last year | R85,000
Change in bank balance | -R40,000
Annual depot inflow (3 years) | R120,000
Depot cost today | R300,000', 'Recommendation', 'evaluate', '["FIN-02","FIN-03","FIN-04","FIN-05"]'::jsonb, '6.1 Write a recommendation (150 to 250 words) to Sipho on whether to open the depot. Use the NPV of the depot, the current ratio, and the difference between profit and cash to support your advice, and suggest one action to improve his cash position.', '{"question_no":6,"word_limit":{"min":150,"max":250}}'::jsonb, NULL, NULL, '[{"criterion":"Clear recommendation consistent with the negative NPV (do not proceed as planned, or delay or renegotiate)","marks":4},{"criterion":"Cites the NPV figure (about -R11,780) and explains that the depot is expected to earn less than the required return","marks":4},{"criterion":"Uses the current ratio of 0.8 to explain the liquidity risk, and links profit not equalling cash to the slow-paying clients","marks":4},{"criterion":"Proposes a relevant action (e.g. collect from clients sooner, improve liquidity before expanding, find a cheaper option with positive NPV)","marks":2},{"criterion":"Clear, professional wording a non-specialist can follow","marks":1}]'::jsonb, 'Sipho, I recommend that you do not open the depot as planned. At your required return of 12%, the three inflows of R120,000 are worth about R288,220 today, which is less than the R300,000 cost. The NPV is therefore about negative R11,780, so the depot is expected to earn less than you require. Your cash position also worries me. Your current ratio is 0.8, which means you have only 80 cents of current assets for every rand of current liabilities, so you may struggle to pay short-term debts. Last year''s profit of R85,000 did not stop your bank balance falling by R40,000, because clients take about 75 days to pay. A R300,000 project now would put even more pressure on your cash, and you could struggle to pay suppliers on time. I suggest you first collect from clients sooner and strengthen your liquidity, and then look again at expansion, perhaps with a cheaper option that earns a positive NPV.', NULL, '{"min":150,"max":250}'::jsonb, 15, 'rubric', 22)
) AS v(type, section, scenario, competency, cognitive_level, source_refs, prompt, payload, correct, explanation, rubric, model_answer, code_lines, word_limit, marks, marking, sort_order)
WHERE c.code = 'cap-fin';

INSERT INTO achievements (code, name, description) VALUES ('capstone-it', 'IT / Software Capstone', 'Passed the IT / Software Capstone.')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

INSERT INTO lab_capstone_assessments
  (code, track_id, title, summary, scenario, instructions, total_marks, grade_bands,
   time_limit_seconds, pass_score, max_attempts, xp_reward, token_reward, achievement_code, sort_order)
VALUES ('cap-it', (SELECT id FROM industry_tracks WHERE name = 'IT / Software'),
  'IT / Software Capstone', 'Three scenarios across six numbered questions: multiple-choice, short-answer, matching and one written answer.',
  '{"title":"IT / Software Capstone: three scenarios","background":"This paper uses three scenarios. Each Question tells you which scenario to use and repeats the figures you need.","facts":["Scenario 1: CampusConnect: the backend review","Scenario 2: CampusConnect: the fake-listing model","Case Study: CampusConnect: the Friday release"]}'::jsonb,
  '["Answer ALL questions. The paper is worth 75 marks and has six numbered questions, each worth the marks shown, and must be completed in 90 minutes.","Each question belongs to one of three scenarios; the relevant figures are repeated with every question.","Multiple-choice, matching and short-answer questions are marked automatically. The written question is marked against a marking guide - write in full sentences for a non-specialist reader."]'::jsonb,
  75, '[{"label":"Distinction","min_percent":75},{"label":"Merit","min_percent":60},{"label":"Competent","min_percent":50},{"label":"Not yet competent","min_percent":0}]'::jsonb, 5400, 60, 3, 70, 15, 'capstone-it', 30)
ON CONFLICT (code) DO UPDATE SET
  track_id = EXCLUDED.track_id, title = EXCLUDED.title, summary = EXCLUDED.summary,
  scenario = EXCLUDED.scenario, instructions = EXCLUDED.instructions, total_marks = EXCLUDED.total_marks,
  grade_bands = EXCLUDED.grade_bands, time_limit_seconds = EXCLUDED.time_limit_seconds,
  pass_score = EXCLUDED.pass_score, max_attempts = EXCLUDED.max_attempts,
  xp_reward = EXCLUDED.xp_reward, token_reward = EXCLUDED.token_reward,
  achievement_code = EXCLUDED.achievement_code, sort_order = EXCLUDED.sort_order;

DELETE FROM lab_capstone_questions WHERE assessment_id = (SELECT id FROM lab_capstone_assessments WHERE code = 'cap-it');
INSERT INTO lab_capstone_questions
  (assessment_id, type, section, scenario, competency, cognitive_level, source_refs, prompt, payload, correct,
   explanation, rubric, model_answer, code_lines, word_limit, marks, marking, sort_order)
SELECT c.id, v.type, v.section, v.scenario, v.competency, v.cognitive_level, v.source_refs::jsonb, v.prompt,
       v.payload::jsonb, v.correct::jsonb, v.explanation, v.rubric::jsonb, v.model_answer,
       v.code_lines::jsonb, v.word_limit::jsonb, v.marks, v.marking, v.sort_order
FROM lab_capstone_assessments c, (VALUES
  ('numeric', 'Section A · Application', 'CampusConnect: the backend review

CampusConnect is a student marketplace with a Flutter mobile app, a Node/Express API and a PostgreSQL database. The team uses an AI assistant to generate code. You are the reviewing engineer.

• The search endpoint builds its SQL by joining strings together (see Question 1).
• The sign-up endpoint stores passwords using MD5 with no salt.', 'Machine learning', 'apply', '["IT-04"]'::jsonb, '1.1 The fake-listing model flags 100 listings; 92 of them are genuine and 8 are false positives.', '{"question_no":1,"unit":"percent"}'::jsonb, '{"answer":92,"tolerance":0}'::jsonb, '92 of the 100 flagged listings were correctly genuine, so 92%.', NULL, NULL, NULL, NULL, 5, 'auto', 1),
  ('multiple_choice', 'Section A · Application', 'CampusConnect: the backend review

CampusConnect is a student marketplace with a Flutter mobile app, a Node/Express API and a PostgreSQL database. The team uses an AI assistant to generate code. You are the reviewing engineer.

• The search endpoint builds its SQL by joining strings together (see Question 1).
• The sign-up endpoint stores passwords using MD5 with no salt.', 'Secure coding', 'analyse', '["IT-01"]'::jsonb, '1.2 The AI assistant produced the search endpoint shown. What is the vulnerability?', '{"question_no":1,"options":["User input is joined into the SQL string, which allows SQL injection","The query is too slow for large tables","The endpoint returns JSON instead of HTML","The endpoint uses async/await"]}'::jsonb, '{"answer_index":0}'::jsonb, 'Joining raw input into the SQL text lets an attacker change the meaning of the command.', NULL, NULL, '["app.get(''/search'', async (req, res) => {","  const q = req.query.q;","  const rows = await db.query(","    \"SELECT * FROM listings WHERE title LIKE ''%\" + q + \"%''\"","  );","  res.json(rows);","});"]'::jsonb, NULL, 2, 'auto', 2),
  ('multiple_choice', 'Section A · Application', 'CampusConnect: the backend review

CampusConnect is a student marketplace with a Flutter mobile app, a Node/Express API and a PostgreSQL database. The team uses an AI assistant to generate code. You are the reviewing engineer.

• The search endpoint builds its SQL by joining strings together (see Question 1).
• The sign-up endpoint stores passwords using MD5 with no salt.', 'Secure coding', 'understand', '["IT-01"]'::jsonb, '1.3 Which statement best describes the risk if an attacker sends specially crafted text as q?', '{"question_no":1,"options":["The attacker can only slow the server down","The attacker can change the SQL command itself, for example to return every listing or read other tables","The attacker can only see their own listings","The attacker can only crash the Flutter app"]}'::jsonb, '{"answer_index":1}'::jsonb, 'Because the input becomes part of the command, it can alter what the database does.', NULL, NULL, '["app.get(''/search'', async (req, res) => {","  const q = req.query.q;","  const rows = await db.query(","    \"SELECT * FROM listings WHERE title LIKE ''%\" + q + \"%''\"","  );","  res.json(rows);","});"]'::jsonb, NULL, 2, 'auto', 3),
  ('multiple_choice', 'Section A · Application', 'CampusConnect: the backend review

CampusConnect is a student marketplace with a Flutter mobile app, a Node/Express API and a PostgreSQL database. The team uses an AI assistant to generate code. You are the reviewing engineer.

• The search endpoint builds its SQL by joining strings together (see Question 1).
• The sign-up endpoint stores passwords using MD5 with no salt.', 'Secure coding', 'apply', '["IT-01"]'::jsonb, '1.4 What is the BEST fix for the search endpoint?', '{"question_no":1,"options":["Strip single quotes from q with a replace() before building the string","Serve the API over HTTPS only","Use a parameterised query such as db.query(\"SELECT * FROM listings WHERE title LIKE $1\", [''%'' + q + ''%''])","Turn off detailed database error messages"]}'::jsonb, '{"answer_index":2}'::jsonb, 'Parameterised queries keep input as data. The other options do not stop injection.', NULL, NULL, '["app.get(''/search'', async (req, res) => {","  const q = req.query.q;","  const rows = await db.query(","    \"SELECT * FROM listings WHERE title LIKE ''%\" + q + \"%''\"","  );","  res.json(rows);","});"]'::jsonb, NULL, 2, 'auto', 4),
  ('multiple_choice', 'Section A · Application', 'CampusConnect: the backend review

CampusConnect is a student marketplace with a Flutter mobile app, a Node/Express API and a PostgreSQL database. The team uses an AI assistant to generate code. You are the reviewing engineer.

• The search endpoint builds its SQL by joining strings together (see Question 1).
• The sign-up endpoint stores passwords using MD5 with no salt.', 'Secure coding', 'understand', '["IT-01"]'::jsonb, '1.5 Why does a parameterised query prevent SQL injection?', '{"question_no":1,"options":["It encrypts the user''s input","It removes all special characters from the database","It makes the query run faster","The database treats the input strictly as data, never as part of the SQL command"]}'::jsonb, '{"answer_index":3}'::jsonb, 'The command and the data travel separately, so input cannot change the command.', NULL, NULL, '["app.get(''/search'', async (req, res) => {","  const q = req.query.q;","  const rows = await db.query(","    \"SELECT * FROM listings WHERE title LIKE ''%\" + q + \"%''\"","  );","  res.json(rows);","});"]'::jsonb, NULL, 2, 'auto', 5),
  ('multiple_choice', 'Section A · Application', 'CampusConnect: the backend review

CampusConnect is a student marketplace with a Flutter mobile app, a Node/Express API and a PostgreSQL database. The team uses an AI assistant to generate code. You are the reviewing engineer.

• The search endpoint builds its SQL by joining strings together (see Question 1).
• The sign-up endpoint stores passwords using MD5 with no salt.', 'Secure coding', 'apply', '["IT-01"]'::jsonb, '1.6 Which extra measure helps limit the damage if some injection flaw still exists?', '{"question_no":1,"options":["Connecting with a database account that has only the permissions the API needs","Making the API key longer","Renaming the listings table","Disabling HTTPS"]}'::jsonb, '{"answer_index":0}'::jsonb, 'A least-privilege database account limits what an attacker can read or change.', NULL, NULL, '["app.get(''/search'', async (req, res) => {","  const q = req.query.q;","  const rows = await db.query(","    \"SELECT * FROM listings WHERE title LIKE ''%\" + q + \"%''\"","  );","  res.json(rows);","});"]'::jsonb, NULL, 2, 'auto', 6),
  ('multiple_choice', 'Section A · Application', 'CampusConnect: the backend review

CampusConnect is a student marketplace with a Flutter mobile app, a Node/Express API and a PostgreSQL database. The team uses an AI assistant to generate code. You are the reviewing engineer.

• The search endpoint builds its SQL by joining strings together (see Question 1).
• The sign-up endpoint stores passwords using MD5 with no salt.', 'Secure coding', 'analyse', '["IT-02"]'::jsonb, '2.1 The sign-up endpoint stores md5(password) with no salt. Why is this unsuitable?', '{"question_no":2,"options":["MD5 is too slow for modern servers","MD5 is fast and unsalted, so stolen hashes can be cracked quickly","MD5 hashes can be reversed with the app''s source code","MD5 only works for short passwords"]}'::jsonb, '{"answer_index":1}'::jsonb, 'Fast, unsalted hashes allow attackers to guess billions of passwords or use precomputed tables.', NULL, NULL, NULL, NULL, 2, 'auto', 7),
  ('multiple_choice', 'Section A · Application', 'CampusConnect: the backend review

CampusConnect is a student marketplace with a Flutter mobile app, a Node/Express API and a PostgreSQL database. The team uses an AI assistant to generate code. You are the reviewing engineer.

• The search endpoint builds its SQL by joining strings together (see Question 1).
• The sign-up endpoint stores passwords using MD5 with no salt.', 'Secure coding', 'apply', '["IT-02"]'::jsonb, '2.2 What is the BEST way to store passwords?', '{"question_no":2,"options":["Encrypt them with AES and keep the key in the code repository","Store them as plain text in a protected database","Hash them with a salted, slow algorithm such as Argon2id or bcrypt","Hash them twice with MD5"]}'::jsonb, '{"answer_index":2}'::jsonb, 'Salted, slow hashing makes large-scale cracking expensive.', NULL, NULL, NULL, NULL, 2, 'auto', 8),
  ('multiple_choice', 'Section A · Application', 'CampusConnect: the backend review

CampusConnect is a student marketplace with a Flutter mobile app, a Node/Express API and a PostgreSQL database. The team uses an AI assistant to generate code. You are the reviewing engineer.

• The search endpoint builds its SQL by joining strings together (see Question 1).
• The sign-up endpoint stores passwords using MD5 with no salt.', 'Secure coding', 'understand', '["IT-02"]'::jsonb, '2.3 What does a salt do?', '{"question_no":2,"options":["It is a secret key stored only in the app","It encrypts the password so the hash can be reversed","It makes the hash shorter","It is a unique random value added to each password before hashing, so identical passwords give different hashes"]}'::jsonb, '{"answer_index":3}'::jsonb, 'Unique salts defeat precomputed tables and stop one cracked hash from revealing other users with the same password.', NULL, NULL, NULL, NULL, 2, 'auto', 9),
  ('multiple_choice', 'Section A · Application', 'CampusConnect: the backend review

CampusConnect is a student marketplace with a Flutter mobile app, a Node/Express API and a PostgreSQL database. The team uses an AI assistant to generate code. You are the reviewing engineer.

• The search endpoint builds its SQL by joining strings together (see Question 1).
• The sign-up endpoint stores passwords using MD5 with no salt.', 'Secure coding', 'analyse', '["IT-03"]'::jsonb, '2.4 The maximum listing price is checked only inside the Flutter form. An attacker sends a request with a negative price straight to the API. Which control stops this?', '{"question_no":2,"options":["Validating and authorising every request on the server","Obfuscating the mobile app''s code","Removing the price field from the form","Stricter validation in the Flutter form"]}'::jsonb, '{"answer_index":0}'::jsonb, 'Anything the client does can be skipped. The server must enforce its own rules.', NULL, NULL, NULL, NULL, 2, 'auto', 10),
  ('multiple_choice', 'Section A · Application', 'CampusConnect: the backend review

CampusConnect is a student marketplace with a Flutter mobile app, a Node/Express API and a PostgreSQL database. The team uses an AI assistant to generate code. You are the reviewing engineer.

• The search endpoint builds its SQL by joining strings together (see Question 1).
• The sign-up endpoint stores passwords using MD5 with no salt.', 'Secure coding', 'understand', '["IT-03"]'::jsonb, '2.5 What is client-side validation still useful for?', '{"question_no":2,"options":["Replacing server-side validation","Giving users fast feedback, as long as the server re-checks everything","Stopping attackers from calling the API","Encrypting data in transit"]}'::jsonb, '{"answer_index":1}'::jsonb, 'Client-side checks improve the user experience but are not a security control.', NULL, NULL, NULL, NULL, 2, 'auto', 11),
  ('multi_select', 'Section A · Application', 'CampusConnect: the backend review

CampusConnect is a student marketplace with a Flutter mobile app, a Node/Express API and a PostgreSQL database. The team uses an AI assistant to generate code. You are the reviewing engineer.

• The search endpoint builds its SQL by joining strings together (see Question 1).
• The sign-up endpoint stores passwords using MD5 with no salt.', 'Secure coding', 'analyse', '["IT-01","IT-02","IT-03"]'::jsonb, '2.6 Which of these would reduce the risk in the CampusConnect backend? Select ALL that apply.', '{"question_no":2,"options":["Use parameterised SQL queries instead of string concatenation","Hash passwords with a salted, slow algorithm such as Argon2id or bcrypt","Validate and authorise every request on the server","Rely on the Flutter form to enforce the maximum price"]}'::jsonb, '{"indices":[0,1,2]}'::jsonb, 'Parameterised queries, slow salted hashing and server-side validation all reduce risk; client-only validation can be bypassed.', NULL, NULL, NULL, NULL, 4, 'auto', 12),
  ('fill_blank', 'Section A · Application', 'CampusConnect: the backend review

CampusConnect is a student marketplace with a Flutter mobile app, a Node/Express API and a PostgreSQL database. The team uses an AI assistant to generate code. You are the reviewing engineer.

• The search endpoint builds its SQL by joining strings together (see Question 1).
• The sign-up endpoint stores passwords using MD5 with no salt.', 'Secure coding', 'remember', '["IT-02"]'::jsonb, '2.7 Compared with MD5, a password hash should be deliberately ___.', '{"question_no":2}'::jsonb, '{"accepted":["slow"]}'::jsonb, 'Slow, salted hashes make large-scale cracking expensive; MD5 is fast and unsalted.', NULL, NULL, NULL, NULL, 2, 'auto', 13),
  ('fill_blank', 'Section A · Application', 'CampusConnect: the backend review

CampusConnect is a student marketplace with a Flutter mobile app, a Node/Express API and a PostgreSQL database. The team uses an AI assistant to generate code. You are the reviewing engineer.

• The search endpoint builds its SQL by joining strings together (see Question 1).
• The sign-up endpoint stores passwords using MD5 with no salt.', 'Machine learning', 'remember', '["IT-05"]'::jsonb, '2.8 A large gap between training and validation accuracy signals ___.', '{"question_no":2}'::jsonb, '{"accepted":["overfitting"]}'::jsonb, 'Overfitting means the model fits the training data too closely and generalises poorly.', NULL, NULL, NULL, NULL, 2, 'auto', 14),
  ('fill_blank', 'Section A · Application', 'CampusConnect: the backend review

CampusConnect is a student marketplace with a Flutter mobile app, a Node/Express API and a PostgreSQL database. The team uses an AI assistant to generate code. You are the reviewing engineer.

• The search endpoint builds its SQL by joining strings together (see Question 1).
• The sign-up endpoint stores passwords using MD5 with no salt.', 'Secure coding', 'remember', '["IT-01"]'::jsonb, '2.9 A password or key committed to source control must be ___ once it is found.', '{"question_no":2}'::jsonb, '{"accepted":["rotated","changed"]}'::jsonb, 'A committed secret is compromised; rotate it rather than deleting the line.', NULL, NULL, NULL, NULL, 2, 'auto', 15),
  ('multiple_choice', 'Section B · Scenario and case study', 'CampusConnect: the fake-listing model

The team has trained a machine-learning model to flag fake listings and wants to know whether it is ready to use.

• All 1,200 labelled listings come from a single campus.
• The listings were split into a training set and a validation set.

Model results
Dataset | Listings | Accuracy
Training | 960 | 99%
Validation | 240 | 71%', 'Machine learning', 'analyse', '["IT-04"]'::jsonb, '3.1 The model scores 99% on the training set and 71% on the validation set. What does this most likely show?', '{"question_no":3,"options":["Underfitting: the model is too simple to learn from the data","The model is ready for release because training accuracy is high","Overfitting: the model has memorised the training data instead of learning patterns that generalise","The validation set is wrong and should be ignored"]}'::jsonb, '{"answer_index":2}'::jsonb, 'A very high training score with a much lower validation score is the classic sign of overfitting.', NULL, NULL, NULL, NULL, 2, 'auto', 16),
  ('multiple_choice', 'Section B · Scenario and case study', 'CampusConnect: the fake-listing model

The team has trained a machine-learning model to flag fake listings and wants to know whether it is ready to use.

• All 1,200 labelled listings come from a single campus.
• The listings were split into a training set and a validation set.

Model results
Dataset | Listings | Accuracy
Training | 960 | 99%
Validation | 240 | 71%', 'Machine learning', 'understand', '["IT-04","IT-05"]'::jsonb, '3.2 Why is the validation accuracy a more honest indicator of real-world performance than the training accuracy?', '{"question_no":3,"options":["It uses more listings","It ignores fake listings","It is always lower than the test accuracy","It measures performance on data the model was not trained on"]}'::jsonb, '{"answer_index":3}'::jsonb, 'Performance on unseen data shows whether the model generalises.', NULL, NULL, NULL, NULL, 2, 'auto', 17),
  ('multiple_choice', 'Section B · Scenario and case study', 'CampusConnect: the fake-listing model

The team has trained a machine-learning model to flag fake listings and wants to know whether it is ready to use.

• All 1,200 labelled listings come from a single campus.
• The listings were split into a training set and a validation set.

Model results
Dataset | Listings | Accuracy
Training | 960 | 99%
Validation | 240 | 71%', 'Machine learning', 'remember', '["IT-05"]'::jsonb, '3.3 What is the validation set mainly used for?', '{"question_no":3,"options":["Tuning the model''s settings and choosing between model versions","Reporting the final score to users","Training the model''s parameters","Replacing the test set"]}'::jsonb, '{"answer_index":0}'::jsonb, 'The validation set guides tuning and model selection during development.', NULL, NULL, NULL, NULL, 2, 'auto', 18),
  ('multiple_choice', 'Section B · Scenario and case study', 'CampusConnect: the fake-listing model

The team has trained a machine-learning model to flag fake listings and wants to know whether it is ready to use.

• All 1,200 labelled listings come from a single campus.
• The listings were split into a training set and a validation set.

Model results
Dataset | Listings | Accuracy
Training | 960 | 99%
Validation | 240 | 71%', 'Machine learning', 'remember', '["IT-05"]'::jsonb, '3.4 What is the test set used for?', '{"question_no":3,"options":["Tuning the model''s settings","A final, unbiased estimate of performance, used once at the end","Training a second model","Cleaning the data"]}'::jsonb, '{"answer_index":1}'::jsonb, 'The test set must stay untouched until the end so that its score is honest.', NULL, NULL, NULL, NULL, 2, 'auto', 19),
  ('multiple_choice', 'Section B · Scenario and case study', 'CampusConnect: the fake-listing model

The team has trained a machine-learning model to flag fake listings and wants to know whether it is ready to use.

• All 1,200 labelled listings come from a single campus.
• The listings were split into a training set and a validation set.

Model results
Dataset | Listings | Accuracy
Training | 960 | 99%
Validation | 240 | 71%', 'Machine learning', 'analyse', '["IT-05"]'::jsonb, '4.1 Which of these would be a MISTAKE in this project?', '{"question_no":4,"options":["Using the validation set to choose between two model versions","Keeping the test set untouched until the end","Repeatedly tuning the model''s settings against the test set","Reporting validation and test results separately"]}'::jsonb, '{"answer_index":2}'::jsonb, 'Tuning against the test set uses it up, so its score is no longer an honest estimate.', NULL, NULL, NULL, NULL, 2, 'auto', 20),
  ('multiple_choice', 'Section B · Scenario and case study', 'CampusConnect: the fake-listing model

The team has trained a machine-learning model to flag fake listings and wants to know whether it is ready to use.

• All 1,200 labelled listings come from a single campus.
• The listings were split into a training set and a validation set.

Model results
Dataset | Listings | Accuracy
Training | 960 | 99%
Validation | 240 | 71%', 'Machine learning', 'apply', '["IT-04"]'::jsonb, '4.2 All 1,200 labelled listings come from one campus. Which action would MOST likely improve how the model performs on new listings?', '{"question_no":4,"options":["Remove the validation set","Train for many more rounds on the same data","Report the 99% training accuracy to users","Add more varied training data, including listings from other campuses"]}'::jsonb, '{"answer_index":3}'::jsonb, 'More varied data helps the model learn patterns that generalise rather than quirks of one campus.', NULL, NULL, NULL, NULL, 2, 'auto', 21),
  ('multiple_choice', 'Section B · Scenario and case study', 'CampusConnect: the fake-listing model

The team has trained a machine-learning model to flag fake listings and wants to know whether it is ready to use.

• All 1,200 labelled listings come from a single campus.
• The listings were split into a training set and a validation set.

Model results
Dataset | Listings | Accuracy
Training | 960 | 99%
Validation | 240 | 71%', 'Machine learning', 'understand', '["IT-04"]'::jsonb, '4.3 What does regularisation do?', '{"question_no":4,"options":["It discourages the model from fitting noise, for example by penalising complexity","It adds more listings to the training set","It increases the training accuracy","It removes the test set"]}'::jsonb, '{"answer_index":0}'::jsonb, 'Regularisation reduces overfitting by limiting how closely the model can fit the training data.', NULL, NULL, NULL, NULL, 2, 'auto', 22),
  ('multiple_choice', 'Section B · Scenario and case study', 'CampusConnect: the fake-listing model

The team has trained a machine-learning model to flag fake listings and wants to know whether it is ready to use.

• All 1,200 labelled listings come from a single campus.
• The listings were split into a training set and a validation set.

Model results
Dataset | Listings | Accuracy
Training | 960 | 99%
Validation | 240 | 71%', 'Machine learning', 'understand', '["IT-04"]'::jsonb, '4.4 What does early stopping do?', '{"question_no":4,"options":["It stops the app from loading","It stops training when performance on the validation set stops improving","It stops the test set from being used","It deletes the weakest listings"]}'::jsonb, '{"answer_index":1}'::jsonb, 'Early stopping ends training before the model starts memorising the training data.', NULL, NULL, NULL, NULL, 2, 'auto', 23),
  ('multi_select', 'Section B · Scenario and case study', 'CampusConnect: the fake-listing model

The team has trained a machine-learning model to flag fake listings and wants to know whether it is ready to use.

• All 1,200 labelled listings come from a single campus.
• The listings were split into a training set and a validation set.

Model results
Dataset | Listings | Accuracy
Training | 960 | 99%
Validation | 240 | 71%', 'Machine learning', 'analyse', '["IT-04","IT-05"]'::jsonb, '4.5 Select the TWO most appropriate actions to improve how the model performs on new listings.', '{"question_no":4,"options":["Add more varied training data, including listings from other campuses","Apply regularisation or early stopping","Report 99% as the accuracy users should expect","Tune the model''s settings using the test set","Delete the validation set"]}'::jsonb, '{"indices":[0,1]}'::jsonb, 'More varied data and regularisation or early stopping help the model generalise. Reporting training accuracy, tuning on the test set, or deleting the validation set would hide the problem.', NULL, NULL, NULL, NULL, 4, 'auto', 24),
  ('multi_select', 'Section B · Scenario and case study', 'CampusConnect: the Friday release

The team plans to release a new checkout feature and an updated model on Friday. Their AI assistant wrote a release-review summary (see Question 5), and you have been asked to prepare a pre-release checklist (see Question 6).

• The AI assistant wrote the checkout endpoint. The maximum price and the quantity are checked only inside the Flutter form.
• To reach 90% accuracy, the team repeatedly adjusted the model''s settings and re-checked the results against the test set until the score was high enough.
• To save time, the team wants to skip human review of the AI-generated code before Friday.', 'Verifying AI output', 'evaluate', '["IT-01","IT-02","IT-03","IT-05"]'::jsonb, '5.1 The AI assistant wrote the release-review statements below. Select ALL statements that are INCORRECT.', '{"question_no":5,"options":["Parameterised queries stop SQL injection by keeping user input separate from the SQL command.","Because the Flutter app already validates the price and quantity, the server does not need to validate them.","Repeatedly tuning the model against the test set still leaves the test score as an unbiased final estimate.","A salted, slow hashing algorithm such as Argon2id or bcrypt is appropriate for storing passwords."]}'::jsonb, '{"indices":[1,2]}'::jsonb, 'Statement 2 is wrong because attackers can bypass the app and call the API directly. Statement 3 is wrong because tuning on the test set uses it up as an honest estimate; tuning belongs on the validation set. Statements 1 and 4 are correct.', NULL, NULL, NULL, NULL, 4, 'auto', 25),
  ('extended_response', 'Section B · Scenario and case study', 'CampusConnect: the Friday release

The team plans to release a new checkout feature and an updated model on Friday. Their AI assistant wrote a release-review summary (see Question 5), and you have been asked to prepare a pre-release checklist (see Question 6).

• The AI assistant wrote the checkout endpoint. The maximum price and the quantity are checked only inside the Flutter form.
• To reach 90% accuracy, the team repeatedly adjusted the model''s settings and re-checked the results against the test set until the score was high enough.
• To save time, the team wants to skip human review of the AI-generated code before Friday.', 'Release readiness', 'create', '["IT-01","IT-02","IT-03","IT-04","IT-05"]'::jsonb, '6.1 Write a pre-release checklist of at least FIVE checks the team must complete before shipping the checkout feature and the updated model on Friday. Give a one-line reason for each check.', '{"question_no":6}'::jsonb, NULL, NULL, '[{"criterion":"Five distinct, valid checks (1 mark each, max 5). Examples: human review of AI-generated code, server-side validation and authorisation of price and quantity, parameterised queries, salted slow password hashing, tuning only on the validation set, using the test set once, checking the train-validation gap for overfitting, logging and monitoring, updating dependencies","marks":10},{"criterion":"Gives a correct one-line reason for at least three of the checks","marks":4},{"criterion":"Organised and clear, with at least one check covering the model and one covering the code","marks":2}]'::jsonb, '1. A human reviews all AI-generated code before release, because the assistant can produce insecure patterns. 2. Validate price and quantity on the server for every checkout request, because anyone can bypass the app. 3. Confirm that all database queries are parameterised, to stop injection. 4. Retune the model using the validation set only, because tuning on the test set uses it up. 5. Evaluate the final model once on a fresh test set, so the score is an honest estimate. 6. Compare training and validation scores to check for overfitting, so the model works on real listings. 7. Turn on logging and monitoring, so problems after release are noticed quickly.', NULL, NULL, 16, 'rubric', 26)
) AS v(type, section, scenario, competency, cognitive_level, source_refs, prompt, payload, correct, explanation, rubric, model_answer, code_lines, word_limit, marks, marking, sort_order)
WHERE c.code = 'cap-it';

INSERT INTO achievements (code, name, description) VALUES ('capstone-legal', 'Legal Capstone', 'Passed the Legal Capstone.')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

INSERT INTO lab_capstone_assessments
  (code, track_id, title, summary, scenario, instructions, total_marks, grade_bands,
   time_limit_seconds, pass_score, max_attempts, xp_reward, token_reward, achievement_code, sort_order)
VALUES ('cap-leg', (SELECT id FROM industry_tracks WHERE name = 'Legal'),
  'Legal Capstone', 'Three scenarios across six numbered questions: multiple-choice, short-answer, matching and one written answer.',
  '{"title":"Legal Capstone: three scenarios","background":"This paper uses three scenarios. Each Question tells you which scenario to use and repeats the figures you need.","facts":["Scenario 1: TutorLink: the data breach","Scenario 2: Greenlight Solar (Pty) Ltd","Case Study: TutorLink Study Rooms: a new collaboration feature"]}'::jsonb,
  '["Answer ALL questions. The paper is worth 75 marks and has six numbered questions, each worth the marks shown, and must be completed in 90 minutes.","Each question belongs to one of three scenarios; the relevant figures are repeated with every question.","Multiple-choice, matching and short-answer questions are marked automatically. The written question is marked against a marking guide - write in full sentences for a non-specialist reader."]'::jsonb,
  75, '[{"label":"Distinction","min_percent":75},{"label":"Merit","min_percent":60},{"label":"Competent","min_percent":50},{"label":"Not yet competent","min_percent":0}]'::jsonb, 5400, 60, 3, 70, 15, 'capstone-legal', 20)
ON CONFLICT (code) DO UPDATE SET
  track_id = EXCLUDED.track_id, title = EXCLUDED.title, summary = EXCLUDED.summary,
  scenario = EXCLUDED.scenario, instructions = EXCLUDED.instructions, total_marks = EXCLUDED.total_marks,
  grade_bands = EXCLUDED.grade_bands, time_limit_seconds = EXCLUDED.time_limit_seconds,
  pass_score = EXCLUDED.pass_score, max_attempts = EXCLUDED.max_attempts,
  xp_reward = EXCLUDED.xp_reward, token_reward = EXCLUDED.token_reward,
  achievement_code = EXCLUDED.achievement_code, sort_order = EXCLUDED.sort_order;

DELETE FROM lab_capstone_questions WHERE assessment_id = (SELECT id FROM lab_capstone_assessments WHERE code = 'cap-leg');
INSERT INTO lab_capstone_questions
  (assessment_id, type, section, scenario, competency, cognitive_level, source_refs, prompt, payload, correct,
   explanation, rubric, model_answer, code_lines, word_limit, marks, marking, sort_order)
SELECT c.id, v.type, v.section, v.scenario, v.competency, v.cognitive_level, v.source_refs::jsonb, v.prompt,
       v.payload::jsonb, v.correct::jsonb, v.explanation, v.rubric::jsonb, v.model_answer,
       v.code_lines::jsonb, v.word_limit::jsonb, v.marks, v.marking, v.sort_order
FROM lab_capstone_assessments c, (VALUES
  ('multiple_choice', 'Section A · Short answers', 'TutorLink: the data breach

Nomsa Dube founded TutorLink (Pty) Ltd, an app that connects university students with tutors. You are the company''s compliance adviser.

• TutorLink decides which personal information to collect from students (names, contact details, payment details) and why.
• It stores this data with a cloud provider, CloudStore, which handles it only on TutorLink''s instructions.
• On Monday, TutorLink discovered that an unauthorised person had accessed about 2,000 student records the previous Friday.', 'POPIA roles', 'apply', '["LEG-01"]'::jsonb, '1.1 TutorLink decides what personal information to collect from students and why. What is its role under POPIA?', '{"question_no":1,"options":["Responsible party","Data subject","Operator","Information Regulator"]}'::jsonb, '{"answer_index":0}'::jsonb, 'The responsible party determines the purpose and means of processing personal information.', NULL, NULL, NULL, NULL, 2, 'auto', 1),
  ('multiple_choice', 'Section A · Short answers', 'TutorLink: the data breach

Nomsa Dube founded TutorLink (Pty) Ltd, an app that connects university students with tutors. You are the company''s compliance adviser.

• TutorLink decides which personal information to collect from students (names, contact details, payment details) and why.
• It stores this data with a cloud provider, CloudStore, which handles it only on TutorLink''s instructions.
• On Monday, TutorLink discovered that an unauthorised person had accessed about 2,000 student records the previous Friday.', 'POPIA roles', 'apply', '["LEG-01"]'::jsonb, '1.2 CloudStore stores the student data but handles it only on TutorLink''s instructions. What is CloudStore''s role under POPIA?', '{"question_no":1,"options":["Responsible party","Operator","Data subject","Information Officer"]}'::jsonb, '{"answer_index":1}'::jsonb, 'An operator processes personal information on behalf of a responsible party under a contract.', NULL, NULL, NULL, NULL, 2, 'auto', 2),
  ('multiple_choice', 'Section A · Short answers', 'TutorLink: the data breach

Nomsa Dube founded TutorLink (Pty) Ltd, an app that connects university students with tutors. You are the company''s compliance adviser.

• TutorLink decides which personal information to collect from students (names, contact details, payment details) and why.
• It stores this data with a cloud provider, CloudStore, which handles it only on TutorLink''s instructions.
• On Monday, TutorLink discovered that an unauthorised person had accessed about 2,000 student records the previous Friday.', 'POPIA roles', 'understand', '["LEG-01"]'::jsonb, '1.3 In this scenario, who are the ''data subjects''?', '{"question_no":1,"options":["The tutors'' employers","The Information Regulator''s staff","The students whose personal information was accessed","CloudStore''s engineers"]}'::jsonb, '{"answer_index":2}'::jsonb, 'A data subject is the person to whom the personal information relates, here the students.', NULL, NULL, NULL, NULL, 2, 'auto', 3),
  ('multiple_choice', 'Section A · Short answers', 'TutorLink: the data breach

Nomsa Dube founded TutorLink (Pty) Ltd, an app that connects university students with tutors. You are the company''s compliance adviser.

• TutorLink decides which personal information to collect from students (names, contact details, payment details) and why.
• It stores this data with a cloud provider, CloudStore, which handles it only on TutorLink''s instructions.
• On Monday, TutorLink discovered that an unauthorised person had accessed about 2,000 student records the previous Friday.', 'POPIA conditions', 'remember', '["LEG-02"]'::jsonb, '1.4 Which of these is one of the eight conditions for lawful processing of personal information under POPIA?', '{"question_no":1,"options":["Profit maximisation","Brand loyalty","Market share","Security safeguards"]}'::jsonb, '{"answer_index":3}'::jsonb, 'The eight conditions are accountability, processing limitation, purpose specification, further processing limitation, information quality, openness, security safeguards and data subject participation.', NULL, NULL, NULL, NULL, 2, 'auto', 4),
  ('multiple_choice', 'Section A · Short answers', 'TutorLink: the data breach

Nomsa Dube founded TutorLink (Pty) Ltd, an app that connects university students with tutors. You are the company''s compliance adviser.

• TutorLink decides which personal information to collect from students (names, contact details, payment details) and why.
• It stores this data with a cloud provider, CloudStore, which handles it only on TutorLink''s instructions.
• On Monday, TutorLink discovered that an unauthorised person had accessed about 2,000 student records the previous Friday.', 'POPIA conditions', 'analyse', '["LEG-02","LEG-03"]'::jsonb, '1.5 Which condition does the unauthorised access to the student records MOST directly raise?', '{"question_no":1,"options":["Security safeguards","Information quality","Openness","Purpose specification"]}'::jsonb, '{"answer_index":0}'::jsonb, 'Protecting personal information from unauthorised access falls under the security safeguards condition.', NULL, NULL, NULL, NULL, 2, 'auto', 5),
  ('multiple_choice', 'Section A · Short answers', 'TutorLink: the data breach

Nomsa Dube founded TutorLink (Pty) Ltd, an app that connects university students with tutors. You are the company''s compliance adviser.

• TutorLink decides which personal information to collect from students (names, contact details, payment details) and why.
• It stores this data with a cloud provider, CloudStore, which handles it only on TutorLink''s instructions.
• On Monday, TutorLink discovered that an unauthorised person had accessed about 2,000 student records the previous Friday.', 'Breach notification', 'apply', '["LEG-03"]'::jsonb, '2.1 TutorLink has reasonable grounds to believe an unauthorised person accessed the student records. Who must it notify?', '{"question_no":2,"options":["Nobody, unless a court orders it","The Information Regulator and the affected students","Only the Information Regulator","Only the South African Police Service"]}'::jsonb, '{"answer_index":1}'::jsonb, 'Section 22 of POPIA requires notice to the Regulator and to the affected data subjects.', NULL, NULL, NULL, NULL, 2, 'auto', 6),
  ('multiple_choice', 'Section A · Short answers', 'TutorLink: the data breach

Nomsa Dube founded TutorLink (Pty) Ltd, an app that connects university students with tutors. You are the company''s compliance adviser.

• TutorLink decides which personal information to collect from students (names, contact details, payment details) and why.
• It stores this data with a cloud provider, CloudStore, which handles it only on TutorLink''s instructions.
• On Monday, TutorLink discovered that an unauthorised person had accessed about 2,000 student records the previous Friday.', 'Breach notification', 'remember', '["LEG-03"]'::jsonb, '2.2 When must TutorLink give this notice?', '{"question_no":2,"options":["Within five years","Only after a court orders it","As soon as reasonably possible after discovering the compromise","Only if more than 10,000 people are affected"]}'::jsonb, '{"answer_index":2}'::jsonb, 'Notification must happen as soon as reasonably possible after the compromise is discovered.', NULL, NULL, NULL, NULL, 2, 'auto', 7),
  ('multiple_choice', 'Section A · Short answers', 'TutorLink: the data breach

Nomsa Dube founded TutorLink (Pty) Ltd, an app that connects university students with tutors. You are the company''s compliance adviser.

• TutorLink decides which personal information to collect from students (names, contact details, payment details) and why.
• It stores this data with a cloud provider, CloudStore, which handles it only on TutorLink''s instructions.
• On Monday, TutorLink discovered that an unauthorised person had accessed about 2,000 student records the previous Friday.', 'POPIA roles', 'apply', '["LEG-01","LEG-02"]'::jsonb, '2.3 Although CloudStore stores the data, who remains accountable for protecting it?', '{"question_no":2,"options":["CloudStore alone, as the operator","The students, as data subjects","The Information Regulator","TutorLink, as the responsible party"]}'::jsonb, '{"answer_index":3}'::jsonb, 'The responsible party stays accountable for compliance, even when an operator processes the information for it.', NULL, NULL, NULL, NULL, 2, 'auto', 8),
  ('fill_blank', 'Section A · Short answers', 'TutorLink: the data breach

Nomsa Dube founded TutorLink (Pty) Ltd, an app that connects university students with tutors. You are the company''s compliance adviser.

• TutorLink decides which personal information to collect from students (names, contact details, payment details) and why.
• It stores this data with a cloud provider, CloudStore, which handles it only on TutorLink''s instructions.
• On Monday, TutorLink discovered that an unauthorised person had accessed about 2,000 student records the previous Friday.', 'Breach notification', 'remember', '["LEG-03"]'::jsonb, '2.4 The body TutorLink must notify about the breach, besides the students, is the Information ___.', '{"question_no":2}'::jsonb, '{"accepted":["regulator"]}'::jsonb, 'Section 22 of POPIA requires notifying the Information Regulator and the affected data subjects.', NULL, NULL, NULL, NULL, 2, 'auto', 9),
  ('fill_blank', 'Section A · Short answers', 'TutorLink: the data breach

Nomsa Dube founded TutorLink (Pty) Ltd, an app that connects university students with tutors. You are the company''s compliance adviser.

• TutorLink decides which personal information to collect from students (names, contact details, payment details) and why.
• It stores this data with a cloud provider, CloudStore, which handles it only on TutorLink''s instructions.
• On Monday, TutorLink discovered that an unauthorised person had accessed about 2,000 student records the previous Friday.', 'POPIA roles', 'remember', '["LEG-01"]'::jsonb, '2.5 The party that decides why and how personal information is processed is the ___ party.', '{"question_no":2}'::jsonb, '{"accepted":["responsible"]}'::jsonb, 'The responsible party decides the purpose and means and remains accountable.', NULL, NULL, NULL, NULL, 2, 'auto', 10),
  ('multiple_choice', 'Section B · Long answers', 'Greenlight Solar (Pty) Ltd

Anele Mthembu is the only shareholder and only director of Greenlight Solar (Pty) Ltd, which sells solar equipment to households.

• Four months ago, a customer, Zodwa, bought a solar inverter from Greenlight. It has stopped working because of a defect, and she wants her money back.
• A supplier, SunParts, is suing Greenlight for R350,000 in unpaid invoices.
• SunParts has told Anele it will claim the money from her personal assets.', 'Consumer rights', 'apply', '["LEG-04"]'::jsonb, '3.1 Zodwa bought an inverter four months ago and it is defective. Which consumer right is she relying on?', '{"question_no":3,"options":["The cooling-off right for direct marketing","The right to cancel a fixed-term contract","The implied warranty of quality","The right to receive a free upgrade"]}'::jsonb, '{"answer_index":2}'::jsonb, 'Section 56 of the Consumer Protection Act gives an implied warranty of quality, with a six-month return period.', NULL, NULL, NULL, NULL, 2, 'auto', 11),
  ('multiple_choice', 'Section B · Long answers', 'Greenlight Solar (Pty) Ltd

Anele Mthembu is the only shareholder and only director of Greenlight Solar (Pty) Ltd, which sells solar equipment to households.

• Four months ago, a customer, Zodwa, bought a solar inverter from Greenlight. It has stopped working because of a defect, and she wants her money back.
• A supplier, SunParts, is suing Greenlight for R350,000 in unpaid invoices.
• SunParts has told Anele it will claim the money from her personal assets.', 'Consumer rights', 'apply', '["LEG-04"]'::jsonb, '3.2 What may Zodwa do under that right?', '{"question_no":3,"options":["Nothing, because more than 30 days have passed","Return the inverter only within five business days","Return it, but Greenlight alone decides between repair, replacement and refund","Return the inverter within six months of delivery and choose repair, replacement or a refund"]}'::jsonb, '{"answer_index":3}'::jsonb, 'Within six months of delivery the consumer can return goods that fail the warranty and direct whether the supplier repairs, replaces or refunds. Five business days is the direct-marketing cooling-off period.', NULL, NULL, NULL, NULL, 2, 'auto', 12),
  ('multiple_choice', 'Section B · Long answers', 'Greenlight Solar (Pty) Ltd

Anele Mthembu is the only shareholder and only director of Greenlight Solar (Pty) Ltd, which sells solar equipment to households.

• Four months ago, a customer, Zodwa, bought a solar inverter from Greenlight. It has stopped working because of a defect, and she wants her money back.
• A supplier, SunParts, is suing Greenlight for R350,000 in unpaid invoices.
• SunParts has told Anele it will claim the money from her personal assets.', 'Consumer rights', 'analyse', '["LEG-04"]'::jsonb, '3.3 Greenlight''s till slip says "No refunds on electrical goods". What is the legal effect of this notice on Zodwa''s rights?', '{"question_no":3,"options":["It has no effect on her statutory rights under the Consumer Protection Act","It limits her to a repair only","It removes her right to a refund","It applies only if she signed the slip"]}'::jsonb, '{"answer_index":0}'::jsonb, 'A supplier cannot take away consumer rights that the Act gives, so a general ''no refunds'' notice does not override them.', NULL, NULL, NULL, NULL, 2, 'auto', 13),
  ('multiple_choice', 'Section B · Long answers', 'Greenlight Solar (Pty) Ltd

Anele Mthembu is the only shareholder and only director of Greenlight Solar (Pty) Ltd, which sells solar equipment to households.

• Four months ago, a customer, Zodwa, bought a solar inverter from Greenlight. It has stopped working because of a defect, and she wants her money back.
• A supplier, SunParts, is suing Greenlight for R350,000 in unpaid invoices.
• SunParts has told Anele it will claim the money from her personal assets.', 'Consumer rights', 'remember', '["LEG-04"]'::jsonb, '3.4 Who carries the cost and risk of returning the defective goods under this right?', '{"question_no":3,"options":["The consumer","The supplier","They share it equally","The courier"]}'::jsonb, '{"answer_index":1}'::jsonb, 'The goods are returned at the supplier''s risk and expense.', NULL, NULL, NULL, NULL, 2, 'auto', 14),
  ('multiple_choice', 'Section B · Long answers', 'Greenlight Solar (Pty) Ltd

Anele Mthembu is the only shareholder and only director of Greenlight Solar (Pty) Ltd, which sells solar equipment to households.

• Four months ago, a customer, Zodwa, bought a solar inverter from Greenlight. It has stopped working because of a defect, and she wants her money back.
• A supplier, SunParts, is suing Greenlight for R350,000 in unpaid invoices.
• SunParts has told Anele it will claim the money from her personal assets.', 'Consumer rights', 'apply', '["LEG-04"]'::jsonb, '3.5 Greenlight repairs the inverter, but it fails again two months later. What can Zodwa now demand?', '{"question_no":3,"options":["Only a second repair","Nothing, because the first repair used up her rights","A replacement or a refund","Only a partial refund"]}'::jsonb, '{"answer_index":2}'::jsonb, 'If a repaired item fails again within three months, the supplier must replace it or refund the price.', NULL, NULL, NULL, NULL, 2, 'auto', 15),
  ('multiple_choice', 'Section B · Long answers', 'Greenlight Solar (Pty) Ltd

Anele Mthembu is the only shareholder and only director of Greenlight Solar (Pty) Ltd, which sells solar equipment to households.

• Four months ago, a customer, Zodwa, bought a solar inverter from Greenlight. It has stopped working because of a defect, and she wants her money back.
• A supplier, SunParts, is suing Greenlight for R350,000 in unpaid invoices.
• SunParts has told Anele it will claim the money from her personal assets.', 'Company law', 'remember', '["LEG-05"]'::jsonb, '4.1 What is the legal status of Greenlight Solar (Pty) Ltd under the Companies Act?', '{"question_no":4,"options":["A partnership between Anele and her customers","An extension of Anele''s personal legal capacity","A trust with Anele as trustee","A juristic person with its own legal existence"]}'::jsonb, '{"answer_index":3}'::jsonb, 'A company is a juristic person, separate from its shareholders and directors.', NULL, NULL, NULL, NULL, 2, 'auto', 16),
  ('multiple_choice', 'Section B · Long answers', 'Greenlight Solar (Pty) Ltd

Anele Mthembu is the only shareholder and only director of Greenlight Solar (Pty) Ltd, which sells solar equipment to households.

• Four months ago, a customer, Zodwa, bought a solar inverter from Greenlight. It has stopped working because of a defect, and she wants her money back.
• A supplier, SunParts, is suing Greenlight for R350,000 in unpaid invoices.
• SunParts has told Anele it will claim the money from her personal assets.', 'Company law', 'apply', '["LEG-05"]'::jsonb, '4.2 SunParts is owed R350,000 by Greenlight. Can SunParts generally claim this from Anele''s personal assets?', '{"question_no":4,"options":["Generally no, because the debt belongs to the company","Yes, because she is the only shareholder","Yes, a director is automatically liable for company debts","Only if the debt is above R100,000"]}'::jsonb, '{"answer_index":0}'::jsonb, 'The company, not its owner, is liable for the company''s debts, even when one person owns and runs it.', NULL, NULL, NULL, NULL, 2, 'auto', 17),
  ('multiple_choice', 'Section B · Long answers', 'Greenlight Solar (Pty) Ltd

Anele Mthembu is the only shareholder and only director of Greenlight Solar (Pty) Ltd, which sells solar equipment to households.

• Four months ago, a customer, Zodwa, bought a solar inverter from Greenlight. It has stopped working because of a defect, and she wants her money back.
• A supplier, SunParts, is suing Greenlight for R350,000 in unpaid invoices.
• SunParts has told Anele it will claim the money from her personal assets.', 'Company law', 'analyse', '["LEG-05"]'::jsonb, '4.3 When may a court disregard a company''s separate legal personality?', '{"question_no":4,"options":["Whenever the company cannot pay its debts","Where the company''s juristic personality is used for unconscionable abuse","Whenever the company has one shareholder","Whenever the debt is large"]}'::jsonb, '{"answer_index":1}'::jsonb, 'Section 20(9) of the Companies Act allows a court to look past the company only in exceptional cases of unconscionable abuse.', NULL, NULL, NULL, NULL, 2, 'auto', 18),
  ('matching', 'Section B · Long answers', 'Greenlight Solar (Pty) Ltd

Anele Mthembu is the only shareholder and only director of Greenlight Solar (Pty) Ltd, which sells solar equipment to households.

• Four months ago, a customer, Zodwa, bought a solar inverter from Greenlight. It has stopped working because of a defect, and she wants her money back.
• A supplier, SunParts, is suing Greenlight for R350,000 in unpaid invoices.
• SunParts has told Anele it will claim the money from her personal assets.', 'Company law', 'apply', '["LEG-05"]'::jsonb, '4.4 Match each term to its meaning.', '{"question_no":4,"left":["Juristic person","Memorandum of Incorporation","Personal liability company (Inc)","CIPC"],"right":["Has legal existence separate from its owners","The company''s founding document that sets out its rules","Directors are jointly and severally liable for debts incurred during their term of office","The commission that registers companies"]}'::jsonb, '{"mapping":{"Juristic person":"Has legal existence separate from its owners","Memorandum of Incorporation":"The company''s founding document that sets out its rules","Personal liability company (Inc)":"Directors are jointly and severally liable for debts incurred during their term of office","CIPC":"The commission that registers companies"}}'::jsonb, 'A juristic person is separate from its owners. The Memorandum of Incorporation holds the company''s rules, CIPC registers companies, an Inc makes directors liable, and a suretyship is a personal guarantee.', NULL, NULL, NULL, NULL, 4, 'auto', 19),
  ('multiple_choice', 'Section C · Case study', 'TutorLink Study Rooms: a new collaboration feature

TutorLink is launching Study Rooms, where students learn together in shared online rooms. The product team''s plan is summarised below. Their AI assistant has produced a legal summary of the plan (see Question 5), and Nomsa has asked you for a written opinion (see Question 6).

• The team plans to keep all chat logs from the rooms indefinitely, in case they are useful for training future AI tools. Students will not be told about this.
• Every member of a room will see each other member''s full name and university email address by default.
• Chat data will be sent to an analytics company, but no written agreement with that company has been signed.
• The lessons in the rooms will quote sections of POPIA and the Consumer Protection Act word for word.', 'Verifying AI output', 'evaluate', '["LEG-02"]'::jsonb, '5.1 An AI assistant commented on keeping chat logs. Which ONE statement is INCORRECT?', '{"question_no":5,"options":["TutorLink may keep chat logs indefinitely ''just in case'', even if students were never told.","Information must be collected for a specific, lawful purpose.","Personal information should not be kept longer than needed for its purpose, unless a law or consent allows it.","Students should be told what their data will be used for."]}'::jsonb, '{"answer_index":0}'::jsonb, 'Keeping personal information indefinitely without a stated purpose conflicts with purpose specification and retention limits.', NULL, NULL, NULL, NULL, 2, 'auto', 20),
  ('multiple_choice', 'Section C · Case study', 'TutorLink Study Rooms: a new collaboration feature

TutorLink is launching Study Rooms, where students learn together in shared online rooms. The product team''s plan is summarised below. Their AI assistant has produced a legal summary of the plan (see Question 5), and Nomsa has asked you for a written opinion (see Question 6).

• The team plans to keep all chat logs from the rooms indefinitely, in case they are useful for training future AI tools. Students will not be told about this.
• Every member of a room will see each other member''s full name and university email address by default.
• Chat data will be sent to an analytics company, but no written agreement with that company has been signed.
• The lessons in the rooms will quote sections of POPIA and the Consumer Protection Act word for word.', 'Verifying AI output', 'evaluate', '["LEG-01","LEG-02"]'::jsonb, '5.2 An AI assistant commented on the analytics company. Which ONE statement is INCORRECT?', '{"question_no":5,"options":["An operator processes personal information on behalf of the responsible party.","An operator may process personal information without any written agreement if it is a reputable company.","The responsible party must have a written contract with an operator.","The contract must require the operator to keep the information secure."]}'::jsonb, '{"answer_index":1}'::jsonb, 'POPIA requires a written contract with an operator, whatever the operator''s reputation.', NULL, NULL, NULL, NULL, 2, 'auto', 21),
  ('multiple_choice', 'Section C · Case study', 'TutorLink Study Rooms: a new collaboration feature

TutorLink is launching Study Rooms, where students learn together in shared online rooms. The product team''s plan is summarised below. Their AI assistant has produced a legal summary of the plan (see Question 5), and Nomsa has asked you for a written opinion (see Question 6).

• The team plans to keep all chat logs from the rooms indefinitely, in case they are useful for training future AI tools. Students will not be told about this.
• Every member of a room will see each other member''s full name and university email address by default.
• Chat data will be sent to an analytics company, but no written agreement with that company has been signed.
• The lessons in the rooms will quote sections of POPIA and the Consumer Protection Act word for word.', 'Verifying AI output', 'evaluate', '["LEG-02"]'::jsonb, '5.3 An AI assistant commented on quoting legislation in lessons. Which ONE statement is INCORRECT?', '{"question_no":5,"options":["Section 12(8)(a) of the Copyright Act excludes official legislative texts from copyright.","TutorLink may reproduce the official text of POPIA in its lessons.","A law firm''s commentary on POPIA is also free to copy because it is about legislation.","Copyright in someone else''s commentary may still be protected even though the legislation it discusses is not."]}'::jsonb, '{"answer_index":2}'::jsonb, 'The exclusion covers the official text only. Commentary written by others can still be protected.', NULL, NULL, NULL, NULL, 2, 'auto', 22),
  ('multiple_choice', 'Section C · Case study', 'TutorLink Study Rooms: a new collaboration feature

TutorLink is launching Study Rooms, where students learn together in shared online rooms. The product team''s plan is summarised below. Their AI assistant has produced a legal summary of the plan (see Question 5), and Nomsa has asked you for a written opinion (see Question 6).

• The team plans to keep all chat logs from the rooms indefinitely, in case they are useful for training future AI tools. Students will not be told about this.
• Every member of a room will see each other member''s full name and university email address by default.
• Chat data will be sent to an analytics company, but no written agreement with that company has been signed.
• The lessons in the rooms will quote sections of POPIA and the Consumer Protection Act word for word.', 'Verifying AI output', 'evaluate', '["LEG-02"]'::jsonb, '5.4 An AI assistant commented on showing student details to other room members. Which ONE statement is INCORRECT?', '{"question_no":5,"options":["Personal information may be processed only if it is adequate, relevant and not excessive for the purpose.","Showing only a display name by default respects this requirement.","Students should be able to choose to share more about themselves.","Showing every student''s full name and email to the whole room is fine because they all attend the same university."]}'::jsonb, '{"answer_index":3}'::jsonb, 'Attending the same university does not make it necessary to expose full names and emails to everyone, so the default is excessive.', NULL, NULL, NULL, NULL, 2, 'auto', 23),
  ('multiple_choice', 'Section C · Case study', 'TutorLink Study Rooms: a new collaboration feature

TutorLink is launching Study Rooms, where students learn together in shared online rooms. The product team''s plan is summarised below. Their AI assistant has produced a legal summary of the plan (see Question 5), and Nomsa has asked you for a written opinion (see Question 6).

• The team plans to keep all chat logs from the rooms indefinitely, in case they are useful for training future AI tools. Students will not be told about this.
• Every member of a room will see each other member''s full name and university email address by default.
• Chat data will be sent to an analytics company, but no written agreement with that company has been signed.
• The lessons in the rooms will quote sections of POPIA and the Consumer Protection Act word for word.', 'Verifying AI output', 'evaluate', '["LEG-01","LEG-03"]'::jsonb, '5.5 An AI assistant commented on the Information Regulator. Which ONE statement is INCORRECT?', '{"question_no":5,"options":["Only the Information Officer may ever contact the Regulator; students cannot.","A data subject may complain to the Information Regulator.","The Information Regulator monitors and enforces compliance with POPIA.","A responsible party must notify the Regulator of a security compromise."]}'::jsonb, '{"answer_index":0}'::jsonb, 'Data subjects may complain to the Regulator, and responsible parties must report compromises to it.', NULL, NULL, NULL, NULL, 2, 'auto', 24),
  ('multi_select', 'Section C · Case study', 'TutorLink Study Rooms: a new collaboration feature

TutorLink is launching Study Rooms, where students learn together in shared online rooms. The product team''s plan is summarised below. Their AI assistant has produced a legal summary of the plan (see Question 5), and Nomsa has asked you for a written opinion (see Question 6).

• The team plans to keep all chat logs from the rooms indefinitely, in case they are useful for training future AI tools. Students will not be told about this.
• Every member of a room will see each other member''s full name and university email address by default.
• Chat data will be sent to an analytics company, but no written agreement with that company has been signed.
• The lessons in the rooms will quote sections of POPIA and the Consumer Protection Act word for word.', 'Verifying AI output', 'evaluate', '["LEG-01","LEG-02","LEG-03"]'::jsonb, '5.6 TutorLink''s AI assistant produced the statements below about the Study Rooms plan. Select ALL statements that are INCORRECT.', '{"question_no":5,"options":["The eight conditions for lawful processing include accountability and security safeguards.","TutorLink may keep student chat logs indefinitely for possible future AI training, even if students were never told.","An operator may process personal information for TutorLink without any written agreement.","Legislation can be quoted word for word in lessons without a copyright problem, because section 12(8)(a) of the Copyright Act excludes official legal texts from copyright."]}'::jsonb, '{"indices":[1,2]}'::jsonb, 'Statement 2 is wrong: personal information must be collected for a specific purpose and not kept longer than needed. Statement 3 is wrong: POPIA requires a written contract between the responsible party and the operator. Statements 1 and 4 are correct.', NULL, NULL, NULL, NULL, 4, 'auto', 25),
  ('extended_response', 'Section C · Case study', 'TutorLink Study Rooms: a new collaboration feature

TutorLink is launching Study Rooms, where students learn together in shared online rooms. The product team''s plan is summarised below. Their AI assistant has produced a legal summary of the plan (see Question 5), and Nomsa has asked you for a written opinion (see Question 6).

• The team plans to keep all chat logs from the rooms indefinitely, in case they are useful for training future AI tools. Students will not be told about this.
• Every member of a room will see each other member''s full name and university email address by default.
• Chat data will be sent to an analytics company, but no written agreement with that company has been signed.
• The lessons in the rooms will quote sections of POPIA and the Consumer Protection Act word for word.', 'Legal opinion', 'create', '["LEG-01","LEG-02","LEG-03"]'::jsonb, '6.1 Write a short advisory note (150 to 250 words) to Nomsa on the Study Rooms plan. Identify TWO POPIA problems in the plan and say how to fix each. Then say whether quoting the statutes in the lessons creates a copyright problem.', '{"question_no":6,"word_limit":{"min":150,"max":250}}'::jsonb, NULL, NULL, '[{"criterion":"First POPIA problem correctly identified, with a sensible fix (e.g. indefinite retention without a stated purpose: tell students the purpose, keep logs only as long as necessary, ask consent for new uses)","marks":5},{"criterion":"Second POPIA problem correctly identified, with a sensible fix (e.g. showing full names and emails by default: share only what is needed; or no written agreement with the analytics company: sign a contract requiring security)","marks":5},{"criterion":"Concludes that quoting the official statute text is not a copyright problem","marks":3},{"criterion":"Gives the reason (section 12(8)(a) excludes official legislative and legal texts) and notes that other people''s commentary may still be protected","marks":3},{"criterion":"Clear structure and professional wording for a non-lawyer","marks":5}]'::jsonb, 'Nomsa, I have three comments on the Study Rooms plan. First, keeping chat logs indefinitely for possible future AI training is a problem, because personal information should be collected for a specific purpose and not kept longer than needed. We should tell students what the logs are used for, keep them only as long as necessary, and ask for consent before any new use. Second, showing every student''s full name and university email to the whole room by default shares more than the service needs. We should show only a display name by default and let students choose to share more. A third gap is sending chat data to the analytics company without a written agreement, so we should sign a contract that requires it to protect the data. On the lessons, quoting POPIA and the Consumer Protection Act is not a copyright problem, because section 12(8)(a) of the Copyright Act excludes official legislative texts from copyright. This covers the official text only, so commentary written by others may still be protected.', NULL, '{"min":150,"max":250}'::jsonb, 21, 'rubric', 26)
) AS v(type, section, scenario, competency, cognitive_level, source_refs, prompt, payload, correct, explanation, rubric, model_answer, code_lines, word_limit, marks, marking, sort_order)
WHERE c.code = 'cap-leg';

INSERT INTO achievements (code, name, description) VALUES ('capstone-business', 'Business Consulting Capstone', 'Passed the Business Consulting Capstone.')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

INSERT INTO lab_capstone_assessments
  (code, track_id, title, summary, scenario, instructions, total_marks, grade_bands,
   time_limit_seconds, pass_score, max_attempts, xp_reward, token_reward, achievement_code, sort_order)
VALUES ('cap-bus', (SELECT id FROM industry_tracks WHERE name = 'Business Consulting'),
  'Business Consulting Capstone', 'Three scenarios across six numbered questions: multiple-choice, short-answer, matching and one written answer.',
  '{"title":"Business Consulting Capstone: three scenarios","background":"This paper uses three scenarios. Each Question tells you which scenario to use and repeats the figures you need.","facts":["Scenario 1: Bheki''s Bakehouse","Scenario 2: Lerato''s Fitness Studio","Case Study: Khula Cleaning Services (Pty) Ltd"]}'::jsonb,
  '["Answer ALL questions. The paper is worth 75 marks and has six numbered questions, each worth the marks shown, and must be completed in 90 minutes.","Each question belongs to one of three scenarios; the relevant figures are repeated with every question.","Multiple-choice, matching and short-answer questions are marked automatically. The written question is marked against a marking guide - write in full sentences for a non-specialist reader."]'::jsonb,
  75, '[{"label":"Distinction","min_percent":75},{"label":"Merit","min_percent":60},{"label":"Competent","min_percent":50},{"label":"Not yet competent","min_percent":0}]'::jsonb, 5400, 60, 3, 70, 15, 'capstone-business', 40)
ON CONFLICT (code) DO UPDATE SET
  track_id = EXCLUDED.track_id, title = EXCLUDED.title, summary = EXCLUDED.summary,
  scenario = EXCLUDED.scenario, instructions = EXCLUDED.instructions, total_marks = EXCLUDED.total_marks,
  grade_bands = EXCLUDED.grade_bands, time_limit_seconds = EXCLUDED.time_limit_seconds,
  pass_score = EXCLUDED.pass_score, max_attempts = EXCLUDED.max_attempts,
  xp_reward = EXCLUDED.xp_reward, token_reward = EXCLUDED.token_reward,
  achievement_code = EXCLUDED.achievement_code, sort_order = EXCLUDED.sort_order;

DELETE FROM lab_capstone_questions WHERE assessment_id = (SELECT id FROM lab_capstone_assessments WHERE code = 'cap-bus');
INSERT INTO lab_capstone_questions
  (assessment_id, type, section, scenario, competency, cognitive_level, source_refs, prompt, payload, correct,
   explanation, rubric, model_answer, code_lines, word_limit, marks, marking, sort_order)
SELECT c.id, v.type, v.section, v.scenario, v.competency, v.cognitive_level, v.source_refs::jsonb, v.prompt,
       v.payload::jsonb, v.correct::jsonb, v.explanation, v.rubric::jsonb, v.model_answer,
       v.code_lines::jsonb, v.word_limit::jsonb, v.marks, v.marking, v.sort_order
FROM lab_capstone_assessments c, (VALUES
  ('multiple_choice', 'Section A · Application', 'Bheki''s Bakehouse

Bheki Nkosi owns three bakery branches in Ekurhuleni. You are the consultant he has hired to help him decide where to focus over the next three years.

• Sales have been flat for a year, and staff turnover is 40% a year across the three branches.
• A discount bakery chain recently opened nearby.
• The bakery has a strong local reputation and loyal customers.
• Orders are still taken on paper, and the system is slow and error-prone.
• Demand for corporate catering orders in the area is growing.', 'SWOT analysis', 'apply', '["BUS-02"]'::jsonb, '1.1 A strong local reputation and loyal customers belong in which part of a SWOT analysis?', '{"question_no":1,"options":["Opportunity (external)","Strength (internal)","Weakness (internal)","Threat (external)"]}'::jsonb, '{"answer_index":1}'::jsonb, 'A strong reputation is something the bakery already has, so it is an internal strength.', NULL, NULL, NULL, NULL, 2, 'auto', 1),
  ('multiple_choice', 'Section A · Application', 'Bheki''s Bakehouse

Bheki Nkosi owns three bakery branches in Ekurhuleni. You are the consultant he has hired to help him decide where to focus over the next three years.

• Sales have been flat for a year, and staff turnover is 40% a year across the three branches.
• A discount bakery chain recently opened nearby.
• The bakery has a strong local reputation and loyal customers.
• Orders are still taken on paper, and the system is slow and error-prone.
• Demand for corporate catering orders in the area is growing.', 'SWOT analysis', 'apply', '["BUS-02"]'::jsonb, '1.2 A discount bakery chain opening nearby belongs in which part of a SWOT analysis?', '{"question_no":1,"options":["Strength (internal)","Weakness (internal)","Threat (external)","Opportunity (external)"]}'::jsonb, '{"answer_index":2}'::jsonb, 'A new competitor comes from outside the bakery, so it is an external threat.', NULL, NULL, NULL, NULL, 2, 'auto', 2),
  ('multiple_choice', 'Section A · Application', 'Bheki''s Bakehouse

Bheki Nkosi owns three bakery branches in Ekurhuleni. You are the consultant he has hired to help him decide where to focus over the next three years.

• Sales have been flat for a year, and staff turnover is 40% a year across the three branches.
• A discount bakery chain recently opened nearby.
• The bakery has a strong local reputation and loyal customers.
• Orders are still taken on paper, and the system is slow and error-prone.
• Demand for corporate catering orders in the area is growing.', 'SWOT analysis', 'apply', '["BUS-02"]'::jsonb, '1.3 Staff turnover of 40% a year belongs in which part of a SWOT analysis?', '{"question_no":1,"options":["Opportunity (external)","Threat (external)","Strength (internal)","Weakness (internal)"]}'::jsonb, '{"answer_index":3}'::jsonb, 'High turnover is a problem inside the bakery, so it is an internal weakness.', NULL, NULL, NULL, NULL, 2, 'auto', 3),
  ('multiple_choice', 'Section A · Application', 'Bheki''s Bakehouse

Bheki Nkosi owns three bakery branches in Ekurhuleni. You are the consultant he has hired to help him decide where to focus over the next three years.

• Sales have been flat for a year, and staff turnover is 40% a year across the three branches.
• A discount bakery chain recently opened nearby.
• The bakery has a strong local reputation and loyal customers.
• Orders are still taken on paper, and the system is slow and error-prone.
• Demand for corporate catering orders in the area is growing.', 'SWOT analysis', 'apply', '["BUS-02"]'::jsonb, '1.4 Growing demand for corporate catering orders belongs in which part of a SWOT analysis?', '{"question_no":1,"options":["Opportunity (external)","Weakness (internal)","Threat (external)","Strength (internal)"]}'::jsonb, '{"answer_index":0}'::jsonb, 'Growing demand is an external condition the bakery could benefit from, so it is an opportunity.', NULL, NULL, NULL, NULL, 2, 'auto', 4),
  ('multiple_choice', 'Section A · Application', 'Bheki''s Bakehouse

Bheki Nkosi owns three bakery branches in Ekurhuleni. You are the consultant he has hired to help him decide where to focus over the next three years.

• Sales have been flat for a year, and staff turnover is 40% a year across the three branches.
• A discount bakery chain recently opened nearby.
• The bakery has a strong local reputation and loyal customers.
• Orders are still taken on paper, and the system is slow and error-prone.
• Demand for corporate catering orders in the area is growing.', 'SWOT analysis', 'remember', '["BUS-02"]'::jsonb, '1.5 Which statement about a SWOT analysis is CORRECT?', '{"question_no":1,"options":["Strengths and opportunities are internal; weaknesses and threats are external","Strengths and weaknesses are internal; opportunities and threats are external","All four parts describe the organisation''s internal factors","All four parts describe the external environment"]}'::jsonb, '{"answer_index":1}'::jsonb, 'Strengths and weaknesses come from inside the organisation. Opportunities and threats come from outside it.', NULL, NULL, NULL, NULL, 2, 'auto', 5),
  ('multiple_choice', 'Section A · Application', 'Bheki''s Bakehouse

Bheki Nkosi owns three bakery branches in Ekurhuleni. You are the consultant he has hired to help him decide where to focus over the next three years.

• Sales have been flat for a year, and staff turnover is 40% a year across the three branches.
• A discount bakery chain recently opened nearby.
• The bakery has a strong local reputation and loyal customers.
• Orders are still taken on paper, and the system is slow and error-prone.
• Demand for corporate catering orders in the area is growing.', 'Levels of planning', 'apply', '["BUS-03"]'::jsonb, '2.1 Deciding whether to open a fourth branch within three years is which level of planning?', '{"question_no":2,"options":["Operational","Tactical","Strategic","Contingency"]}'::jsonb, '{"answer_index":2}'::jsonb, 'Long-term, organisation-wide decisions made by top managers are strategic.', NULL, NULL, NULL, NULL, 2, 'auto', 6),
  ('multiple_choice', 'Section A · Application', 'Bheki''s Bakehouse

Bheki Nkosi owns three bakery branches in Ekurhuleni. You are the consultant he has hired to help him decide where to focus over the next three years.

• Sales have been flat for a year, and staff turnover is 40% a year across the three branches.
• A discount bakery chain recently opened nearby.
• The bakery has a strong local reputation and loyal customers.
• Orders are still taken on paper, and the system is slow and error-prone.
• Demand for corporate catering orders in the area is growing.', 'Levels of planning', 'apply', '["BUS-03"]'::jsonb, '2.2 Dividing the marketing budget between the three branches is which level of planning?', '{"question_no":2,"options":["Corporate","Strategic","Operational","Tactical"]}'::jsonb, '{"answer_index":3}'::jsonb, 'Turning strategy into medium-term plans for departments or branches is tactical planning, usually by middle managers.', NULL, NULL, NULL, NULL, 2, 'auto', 7),
  ('multiple_choice', 'Section A · Application', 'Bheki''s Bakehouse

Bheki Nkosi owns three bakery branches in Ekurhuleni. You are the consultant he has hired to help him decide where to focus over the next three years.

• Sales have been flat for a year, and staff turnover is 40% a year across the three branches.
• A discount bakery chain recently opened nearby.
• The bakery has a strong local reputation and loyal customers.
• Orders are still taken on paper, and the system is slow and error-prone.
• Demand for corporate catering orders in the area is growing.', 'Levels of planning', 'apply', '["BUS-03"]'::jsonb, '2.3 Scheduling this week''s baking shifts is which level of planning?', '{"question_no":2,"options":["Operational","Tactical","Corporate","Strategic"]}'::jsonb, '{"answer_index":0}'::jsonb, 'Short-term, day-to-day plans made by first-line managers are operational.', NULL, NULL, NULL, NULL, 2, 'auto', 8),
  ('fill_blank', 'Section A · Application', 'Bheki''s Bakehouse

Bheki Nkosi owns three bakery branches in Ekurhuleni. You are the consultant he has hired to help him decide where to focus over the next three years.

• Sales have been flat for a year, and staff turnover is 40% a year across the three branches.
• A discount bakery chain recently opened nearby.
• The bakery has a strong local reputation and loyal customers.
• Orders are still taken on paper, and the system is slow and error-prone.
• Demand for corporate catering orders in the area is growing.', 'Goal setting', 'remember', '["BUS-04"]'::jsonb, '2.4 A goal that is Specific, Measurable, Achievable, Relevant and Time-bound is called a ___ goal.', '{"question_no":2}'::jsonb, '{"accepted":["smart"]}'::jsonb, 'SMART goals are specific, measurable, achievable, relevant and time-bound.', NULL, NULL, NULL, NULL, 2, 'auto', 9),
  ('fill_blank', 'Section A · Application', 'Bheki''s Bakehouse

Bheki Nkosi owns three bakery branches in Ekurhuleni. You are the consultant he has hired to help him decide where to focus over the next three years.

• Sales have been flat for a year, and staff turnover is 40% a year across the three branches.
• A discount bakery chain recently opened nearby.
• The bakery has a strong local reputation and loyal customers.
• Orders are still taken on paper, and the system is slow and error-prone.
• Demand for corporate catering orders in the area is growing.', 'Controlling', 'remember', '["BUS-05"]'::jsonb, '2.5 Strengths and weaknesses in a SWOT analysis are internal; opportunities and threats are ___.', '{"question_no":2}'::jsonb, '{"accepted":["external"]}'::jsonb, 'Opportunities and threats come from outside the organisation.', NULL, NULL, NULL, NULL, 2, 'auto', 10),
  ('multiple_choice', 'Section B · Scenario', 'Lerato''s Fitness Studio

Lerato Zulu owns a fitness studio in Pretoria. She has asked you to help her tackle two problems.

• Each month, about 12% of members cancel their membership, and she wants this to fall.
• Her standard for class occupancy is 80% of available spaces.
• Last month''s measured occupancy was 65%.', 'Goal setting', 'apply', '["BUS-04"]'::jsonb, '3.1 Which ONE of these is the best SMART goal for Lerato''s cancellation problem?', '{"question_no":3,"options":["Get more members and keep them happy","Be the most popular studio in Pretoria","Lower cancellations as much as possible soon","Reduce monthly member cancellations from 12% to 8% by 31 March 2027, measured each month"]}'::jsonb, '{"answer_index":3}'::jsonb, 'It is specific, measurable (12% to 8%), plausible, relevant to the problem and has a deadline.', NULL, NULL, NULL, NULL, 2, 'auto', 11),
  ('multiple_choice', 'Section B · Scenario', 'Lerato''s Fitness Studio

Lerato Zulu owns a fitness studio in Pretoria. She has asked you to help her tackle two problems.

• Each month, about 12% of members cancel their membership, and she wants this to fall.
• Her standard for class occupancy is 80% of available spaces.
• Last month''s measured occupancy was 65%.', 'Goal setting', 'analyse', '["BUS-04"]'::jsonb, '3.2 Lerato writes: "Reduce monthly cancellations from 12% to 8%." Which SMART element is MISSING?', '{"question_no":3,"options":["A deadline","A measure","Relevance to the problem","A specific target"]}'::jsonb, '{"answer_index":0}'::jsonb, 'The goal has a target and a measure but no date by which it should be achieved.', NULL, NULL, NULL, NULL, 2, 'auto', 12),
  ('multiple_choice', 'Section B · Scenario', 'Lerato''s Fitness Studio

Lerato Zulu owns a fitness studio in Pretoria. She has asked you to help her tackle two problems.

• Each month, about 12% of members cancel their membership, and she wants this to fall.
• Her standard for class occupancy is 80% of available spaces.
• Last month''s measured occupancy was 65%.', 'Goal setting', 'analyse', '["BUS-04"]'::jsonb, '3.3 Lerato writes: "Reduce cancellations to 0% by next week." Which SMART element does this goal fail?', '{"question_no":3,"options":["Specific","Achievable","Measurable","Time-bound"]}'::jsonb, '{"answer_index":1}'::jsonb, 'Removing every cancellation in a week is not realistic.', NULL, NULL, NULL, NULL, 2, 'auto', 13),
  ('multiple_choice', 'Section B · Scenario', 'Lerato''s Fitness Studio

Lerato Zulu owns a fitness studio in Pretoria. She has asked you to help her tackle two problems.

• Each month, about 12% of members cancel their membership, and she wants this to fall.
• Her standard for class occupancy is 80% of available spaces.
• Last month''s measured occupancy was 65%.', 'Goal setting', 'analyse', '["BUS-04"]'::jsonb, '3.4 Lerato writes: "Repaint the reception area in a calming colour by 30 June." It is specific, measurable and time-bound. Why is it still a poor goal for her cancellation problem?', '{"question_no":3,"options":["It has no deadline","It is too specific","It does not address the cancellation problem","It is impossible to measure"]}'::jsonb, '{"answer_index":2}'::jsonb, 'A goal should be relevant to the problem it is meant to solve.', NULL, NULL, NULL, NULL, 2, 'auto', 14),
  ('multiple_choice', 'Section B · Scenario', 'Lerato''s Fitness Studio

Lerato Zulu owns a fitness studio in Pretoria. She has asked you to help her tackle two problems.

• Each month, about 12% of members cancel their membership, and she wants this to fall.
• Her standard for class occupancy is 80% of available spaces.
• Last month''s measured occupancy was 65%.', 'Goal setting', 'understand', '["BUS-04"]'::jsonb, '3.5 Why should Lerato set SMART goals?', '{"question_no":3,"options":["So that staff do not need to know the goals","So that she never has to review results","So that goals become easier to change daily","So that progress can be measured and everyone knows what success looks like"]}'::jsonb, '{"answer_index":3}'::jsonb, 'Clear, measurable goals with deadlines make progress visible and actions focused.', NULL, NULL, NULL, NULL, 2, 'auto', 15),
  ('multiple_choice', 'Section B · Scenario', 'Lerato''s Fitness Studio

Lerato Zulu owns a fitness studio in Pretoria. She has asked you to help her tackle two problems.

• Each month, about 12% of members cancel their membership, and she wants this to fall.
• Her standard for class occupancy is 80% of available spaces.
• Last month''s measured occupancy was 65%.', 'Controlling', 'remember', '["BUS-05"]'::jsonb, '4.1 What is the FIRST step in the control process?', '{"question_no":4,"options":["Set performance standards","Compare results with the standard","Take corrective action","Measure actual performance"]}'::jsonb, '{"answer_index":0}'::jsonb, 'You cannot judge results until you know what ''good'' looks like.', NULL, NULL, NULL, NULL, 2, 'auto', 16),
  ('multiple_choice', 'Section B · Scenario', 'Lerato''s Fitness Studio

Lerato Zulu owns a fitness studio in Pretoria. She has asked you to help her tackle two problems.

• Each month, about 12% of members cancel their membership, and she wants this to fall.
• Her standard for class occupancy is 80% of available spaces.
• Last month''s measured occupancy was 65%.', 'Controlling', 'apply', '["BUS-05"]'::jsonb, '4.2 Lerato''s standard for class occupancy is 80%, and last month''s measured occupancy was 65%. What is the deviation?', '{"question_no":4,"options":["15 percentage points below the standard","15 percentage points above the standard","65 percentage points below the standard","There is no deviation"]}'::jsonb, '{"answer_index":0}'::jsonb, '80% minus 65% is a gap of 15 percentage points below the standard.', NULL, NULL, NULL, NULL, 2, 'auto', 17),
  ('multiple_choice', 'Section B · Scenario', 'Lerato''s Fitness Studio

Lerato Zulu owns a fitness studio in Pretoria. She has asked you to help her tackle two problems.

• Each month, about 12% of members cancel their membership, and she wants this to fall.
• Her standard for class occupancy is 80% of available spaces.
• Last month''s measured occupancy was 65%.', 'Controlling', 'apply', '["BUS-05"]'::jsonb, '4.3 What is the most appropriate NEXT step after finding this gap?', '{"question_no":4,"options":["Lower the standard to 65%","Identify the cause of the gap and take corrective action","Ignore the gap until next quarter","Dismiss the instructors"]}'::jsonb, '{"answer_index":1}'::jsonb, 'After comparing results with the standard, the manager finds the cause and acts on it.', NULL, NULL, NULL, NULL, 2, 'auto', 18),
  ('matching', 'Section B · Scenario', 'Lerato''s Fitness Studio

Lerato Zulu owns a fitness studio in Pretoria. She has asked you to help her tackle two problems.

• Each month, about 12% of members cancel their membership, and she wants this to fall.
• Her standard for class occupancy is 80% of available spaces.
• Last month''s measured occupancy was 65%.', 'Controlling', 'apply', '["BUS-05"]'::jsonb, '4.4 Match each control-process term to Lerato''s situation.', '{"question_no":4,"left":["Standard","Measuring actual performance","Actual performance","Deviation"],"right":["80% class occupancy","Counting attendance at every class and averaging it","65% class occupancy last month","15 percentage points below the standard"]}'::jsonb, '{"mapping":{"Standard":"80% class occupancy","Measuring actual performance":"Counting attendance at every class and averaging it","Actual performance":"65% class occupancy last month","Deviation":"15 percentage points below the standard"}}'::jsonb, 'The standard is the target, actual performance is what was measured, the deviation is the gap between them, and corrective action fixes the cause.', NULL, NULL, NULL, NULL, 4, 'auto', 19),
  ('multiple_choice', 'Section C · Case study', 'Khula Cleaning Services (Pty) Ltd

Thandi Khumalo owns Khula Cleaning Services, which cleans office buildings in Pretoria. She asked an AI assistant to summarise her situation (see Question 5) and has hired you to recommend a direction (see Question 6).

• Khula has 35 trained and reliable staff and a very low absentee rate.
• Bookings and invoicing are done manually, using spreadsheets and paper.
• Corporate clients increasingly ask for eco-friendly ("green") cleaning, and demand is growing.
• Several new low-cost cleaning companies have entered the Pretoria market.
• About 70% of Khula''s revenue comes from two clients.', 'Verifying AI output', 'evaluate', '["BUS-02"]'::jsonb, '5.1 An AI assistant classified Khula''s situation. Which ONE statement is INCORRECT?', '{"question_no":5,"options":["The new low-cost competitors are an internal weakness.","Growing demand for green cleaning is an external opportunity.","Trained and reliable staff are an internal strength.","The manual booking and invoicing process is an internal weakness."]}'::jsonb, '{"answer_index":0}'::jsonb, 'Competitors are outside Khula, so they are an external threat.', NULL, NULL, NULL, NULL, 2, 'auto', 20),
  ('multiple_choice', 'Section C · Case study', 'Khula Cleaning Services (Pty) Ltd

Thandi Khumalo owns Khula Cleaning Services, which cleans office buildings in Pretoria. She asked an AI assistant to summarise her situation (see Question 5) and has hired you to recommend a direction (see Question 6).

• Khula has 35 trained and reliable staff and a very low absentee rate.
• Bookings and invoicing are done manually, using spreadsheets and paper.
• Corporate clients increasingly ask for eco-friendly ("green") cleaning, and demand is growing.
• Several new low-cost cleaning companies have entered the Pretoria market.
• About 70% of Khula''s revenue comes from two clients.', 'Verifying AI output', 'evaluate', '["BUS-04"]'::jsonb, '5.2 An AI assistant commented on goals. Which ONE statement is INCORRECT?', '{"question_no":5,"options":["Winning six new green-cleaning contracts by 30 June 2027 is specific, measurable and time-bound.","\"Win more clients\" is a SMART goal because it is positive.","A SMART goal has a deadline.","Measurable means progress can be tracked with a number."]}'::jsonb, '{"answer_index":1}'::jsonb, '"Win more clients" has no measure, no specifics and no deadline.', NULL, NULL, NULL, NULL, 2, 'auto', 21),
  ('multiple_choice', 'Section C · Case study', 'Khula Cleaning Services (Pty) Ltd

Thandi Khumalo owns Khula Cleaning Services, which cleans office buildings in Pretoria. She asked an AI assistant to summarise her situation (see Question 5) and has hired you to recommend a direction (see Question 6).

• Khula has 35 trained and reliable staff and a very low absentee rate.
• Bookings and invoicing are done manually, using spreadsheets and paper.
• Corporate clients increasingly ask for eco-friendly ("green") cleaning, and demand is growing.
• Several new low-cost cleaning companies have entered the Pretoria market.
• About 70% of Khula''s revenue comes from two clients.', 'Verifying AI output', 'evaluate', '["BUS-01"]'::jsonb, '5.3 An AI assistant described the functions of management. Which ONE statement is INCORRECT?', '{"question_no":5,"options":["Planning, organising, leading and controlling are the four functions of management.","Controlling involves comparing results with standards.","Planning means assigning people and resources to tasks, while organising means setting goals.","Leading involves motivating and guiding people."]}'::jsonb, '{"answer_index":2}'::jsonb, 'The definitions are swapped: planning sets goals and organising arranges people and resources.', NULL, NULL, NULL, NULL, 2, 'auto', 22),
  ('multiple_choice', 'Section C · Case study', 'Khula Cleaning Services (Pty) Ltd

Thandi Khumalo owns Khula Cleaning Services, which cleans office buildings in Pretoria. She asked an AI assistant to summarise her situation (see Question 5) and has hired you to recommend a direction (see Question 6).

• Khula has 35 trained and reliable staff and a very low absentee rate.
• Bookings and invoicing are done manually, using spreadsheets and paper.
• Corporate clients increasingly ask for eco-friendly ("green") cleaning, and demand is growing.
• Several new low-cost cleaning companies have entered the Pretoria market.
• About 70% of Khula''s revenue comes from two clients.', 'Verifying AI output', 'evaluate', '["BUS-03"]'::jsonb, '5.4 An AI assistant described levels of management. Which ONE statement is INCORRECT?', '{"question_no":5,"options":["Operational plans are short-term.","Top managers set long-term strategy.","Middle managers turn strategy into tactical plans.","First-line managers set the company''s five-year strategy."]}'::jsonb, '{"answer_index":3}'::jsonb, 'First-line managers handle day-to-day operational plans. Top managers set strategy.', NULL, NULL, NULL, NULL, 2, 'auto', 23),
  ('multiple_choice', 'Section C · Case study', 'Khula Cleaning Services (Pty) Ltd

Thandi Khumalo owns Khula Cleaning Services, which cleans office buildings in Pretoria. She asked an AI assistant to summarise her situation (see Question 5) and has hired you to recommend a direction (see Question 6).

• Khula has 35 trained and reliable staff and a very low absentee rate.
• Bookings and invoicing are done manually, using spreadsheets and paper.
• Corporate clients increasingly ask for eco-friendly ("green") cleaning, and demand is growing.
• Several new low-cost cleaning companies have entered the Pretoria market.
• About 70% of Khula''s revenue comes from two clients.', 'Verifying AI output', 'evaluate', '["BUS-05"]'::jsonb, '5.5 An AI assistant described control. Which ONE statement is INCORRECT?', '{"question_no":5,"options":["If Khula misses its monthly target, the best response is to lower the target without investigating.","If results fall below standard, the cause should be found and addressed.","Measuring actual results is a step in the control process.","Control involves setting standards, measuring results, comparing them, and acting on gaps."]}'::jsonb, '{"answer_index":0}'::jsonb, 'Lowering the target without investigating ignores the cause of the gap.', NULL, NULL, NULL, NULL, 2, 'auto', 24),
  ('multi_select', 'Section C · Case study', 'Khula Cleaning Services (Pty) Ltd

Thandi Khumalo owns Khula Cleaning Services, which cleans office buildings in Pretoria. She asked an AI assistant to summarise her situation (see Question 5) and has hired you to recommend a direction (see Question 6).

• Khula has 35 trained and reliable staff and a very low absentee rate.
• Bookings and invoicing are done manually, using spreadsheets and paper.
• Corporate clients increasingly ask for eco-friendly ("green") cleaning, and demand is growing.
• Several new low-cost cleaning companies have entered the Pretoria market.
• About 70% of Khula''s revenue comes from two clients.', 'Verifying AI output', 'evaluate', '["BUS-01","BUS-02","BUS-03","BUS-04"]'::jsonb, '5.6 Thandi''s AI assistant drafted the statements below about Khula. Select ALL statements that are INCORRECT.', '{"question_no":5,"options":["The manual booking and invoicing process is an internal weakness.","The new low-cost competitors are an internal weakness because they affect Khula''s profits.","\"Win more clients\" is a SMART goal because it is positive and easy to understand.","As the owner, Thandi is a top manager and is typically responsible for setting Khula''s long-term strategy."]}'::jsonb, '{"indices":[1,2]}'::jsonb, 'Statement 2 is wrong: competitors are an external threat. Statement 3 is wrong: the goal has no measure, specifics or deadline. Statements 1 and 4 are correct.', NULL, NULL, NULL, NULL, 4, 'auto', 25),
  ('extended_response', 'Section C · Case study', 'Khula Cleaning Services (Pty) Ltd

Thandi Khumalo owns Khula Cleaning Services, which cleans office buildings in Pretoria. She asked an AI assistant to summarise her situation (see Question 5) and has hired you to recommend a direction (see Question 6).

• Khula has 35 trained and reliable staff and a very low absentee rate.
• Bookings and invoicing are done manually, using spreadsheets and paper.
• Corporate clients increasingly ask for eco-friendly ("green") cleaning, and demand is growing.
• Several new low-cost cleaning companies have entered the Pretoria market.
• About 70% of Khula''s revenue comes from two clients.', 'Consulting recommendation', 'create', '["BUS-02","BUS-04","BUS-05"]'::jsonb, '6.1 Write a recommendation (150 to 250 words) to Thandi. Name ONE strategic priority justified by a SWOT analysis of Khula, state a SMART goal for it, and describe how she will control progress towards the goal.', '{"question_no":6,"word_limit":{"min":150,"max":250}}'::jsonb, NULL, NULL, '[{"criterion":"Names one strategic priority and links it clearly to items in the SWOT analysis","marks":5},{"criterion":"States a goal that is specific and measurable","marks":3},{"criterion":"The goal is achievable and relevant to the priority","marks":3},{"criterion":"The goal has a deadline","marks":3},{"criterion":"Describes the control process: a standard, measuring actual results, comparing, and corrective action","marks":5},{"criterion":"Clear, professional wording a non-specialist can follow","marks":2}]'::jsonb, 'Thandi, I recommend that your priority is to grow your eco-friendly cleaning service for corporate clients. Your trained, reliable staff are a strength, and growing demand for green cleaning is an opportunity. It also reduces your risk from the new low-cost competitors, because you would compete on quality rather than price, and it would help you win more clients so you depend less on your two big ones. Your manual booking is a weakness, so we should set up a simple digital booking system first. My goal is that green cleaning contracts with at least six new corporate clients will be signed by 30 June 2027. To control progress, set monthly targets as your standard, measure the actual number of contracts won each month, and compare them with the target. If you fall behind, find the cause, for example slow quotes or too little marketing, and take action. Review results with your team every month.', NULL, '{"min":150,"max":250}'::jsonb, 21, 'rubric', 26)
) AS v(type, section, scenario, competency, cognitive_level, source_refs, prompt, payload, correct, explanation, rubric, model_answer, code_lines, word_limit, marks, marking, sort_order)
WHERE c.code = 'cap-bus';

