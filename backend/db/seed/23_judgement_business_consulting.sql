-- AI Judgement — Business Consulting (5 tasks)
-- Source: VerifAI_Business_Consulting_AI_Judgement_Tasks.pdf.

SELECT seed_choice_task(
  'judgement', 'judgement-bc-01', 'Business Consulting',
  $$The Workshop Questions$$,
  $$You are a junior consultant. Next week your team kicks off a project with a retail client to improve the in-store customer experience. Your manager asks for a first list of questions for the kick-off workshop. You would give the AI only the project topic the client has already announced publicly, with no figures and no client documents.$$,
  $$Good use of AI. It is low risk and easy to judge. Treat the output as a starting list: drop the generic questions and add the ones only your team knows to ask.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":50},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":0},
    {"kind":"reason","label":"A. Brainstorming from a public topic uses no sensitive information, and you and your manager will edit the list before it is used.","score":50},
    {"kind":"reason","label":"B. AI knows the client's business better than the team does, so its list can be used as it is.","score":0},
    {"kind":"reason","label":"C. Consultants should never use AI for brainstorming because ideas must be original.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-bc-02', 'Business Consulting',
  $$The Market Size$$,
  $$A client is deciding whether to enter the South African online grocery market. Your manager wants a one-slide market-size estimate for tomorrow. Your firm's approved AI tool gives a precise figure with a source line citing a '2024 industry report'. You cannot find that report.$$,
  $$A confident number with a neat source is not evidence. Use the AI estimate to get started, then find the real sources. If a number cannot be traced, replace it or label it clearly as an assumption.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI can pull together a first estimate quickly, but it can invent figures and sources, so you must trace each number to a source you have found yourself before it goes on a client slide.","score":50},
    {"kind":"reason","label":"B. A source line means the figure is real.","score":0},
    {"kind":"reason","label":"C. AI cannot estimate market sizes, so the figure should be thrown away and the slide left empty.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-bc-03', 'Business Consulting',
  $$The Interview Summary$$,
  $$You interviewed 12 managers at a client. Your firm's approved AI tool summarises your notes into one page for the steering committee and says 'managers broadly agree the main problem is the legacy system'. Re-reading your notes, only five of the twelve mentioned it and three disagreed.$$,
  $$The summary saves time, but it turned five out of twelve into 'broad agreement'. You are accountable for what the client reads, so check claims about consensus against your notes and correct them before the page goes anywhere.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI is good at condensing notes quickly, but it can overstate agreement, so you must check the summary against what people actually said before it goes to the client.","score":50},
    {"kind":"reason","label":"B. AI summaries are neutral, so they can be sent as they are.","score":0},
    {"kind":"reason","label":"C. Interview notes should never be summarised, only quoted in full.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-bc-04', 'Business Consulting',
  $$The Retrenchment List$$,
  $$A client wants to cut costs by reducing headcount. Your manager suggests loading the client's staff data into an AI tool and letting it decide which roles and which people to retrench, then presenting the list to the client.$$,
  $$AI can help model cost scenarios, but who is selected must be decided by people. Retrenchments for operational reasons require a fair consultation process, and staff records are personal information that must be handled carefully.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. Deciding who loses their job is a high-impact decision about people that needs accountable human judgement, fair consultation and legal compliance, so AI should not make the call.","score":50},
    {"kind":"reason","label":"B. AI is quicker, and the client only cares about cost savings, so the list can be used directly.","score":0},
    {"kind":"reason","label":"C. A retrenchment list is just data analysis, so human judgement adds nothing.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-bc-05', 'Business Consulting',
  $$The Merger Sign-Off$$,
  $$Your client plans to acquire a competitor. Your manager asks an AI tool whether the deal needs approval from the competition authorities. The AI says no approval is needed, and your manager wants to tell the client that and move on.$$,
  $$AI can help you prepare the questions to ask a specialist, but it should not be the source of a regulatory answer. If it is wrong, the client could face penalties and delays. The right step is to flag the question and bring in a competition lawyer.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. Whether a merger must be notified depends on legal thresholds and the specific facts, which is a question for a competition law specialist, so AI cannot be the final word.","score":50},
    {"kind":"reason","label":"B. AI has read the Competition Act, so its answer is reliable.","score":0},
    {"kind":"reason","label":"C. Consultants should never mention regulation to clients.","score":0}
  ]$j$::jsonb
);
