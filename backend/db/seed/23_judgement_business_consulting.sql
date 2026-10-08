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

-- ===========================================================================
-- Set 2 (10 tasks) — VerifAI_Business_Consulting_AI_Judgement_Tasks_Set2.pdf
-- ===========================================================================

SELECT seed_choice_task(
  'judgement', 'judgement-bc-06', 'Business Consulting', $$The Slide Titles$$,
  $$You wrote the content of a slide on store opening hours. The title is dull. You ask AI for ten alternative titles, sharing only the topic and no client data.$$,
  $$Fine and low risk. Pick a title that matches what the slide actually shows, because a catchy title that overstates the point is worse than a plain one.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":50},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":0},
    {"kind":"reason","label":"A. It is a wording task using your own content with no confidential data, and you choose the one that fits.","score":50},
    {"kind":"reason","label":"B. AI titles are always accurate summaries, so you can use the first one without reading the slide again.","score":0},
    {"kind":"reason","label":"C. Slide titles are part of the analysis and must always be written without help.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-bc-07', 'Business Consulting', $$The Framework Refresher$$,
  $$Before an interview, you ask AI to remind you how Porter's Five Forces and a SWOT analysis work, using a made-up example company.$$,
  $$A good use of AI as a study aid. For anything you present to a client, go back to a recognised source and apply the framework to the client's real situation.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":50},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":0},
    {"kind":"reason","label":"A. The explanation is the same as a textbook, so it can be quoted in client work without checking.","score":0},
    {"kind":"reason","label":"B. You are refreshing general knowledge with an invented example, no client or confidential data is involved, and you can verify the ideas against a textbook.","score":50},
    {"kind":"reason","label":"C. General business frameworks can only be learned in a classroom.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-bc-08', 'Business Consulting', $$The Action List$$,
  $$After your internal team stand-up you type your notes, with no client names or figures. You ask AI to turn them into an action list with an owner and a deadline for each item.$$,
  $$A good time-saver. Check that every action, owner and date matches what was agreed, and fill in any gaps yourself instead of letting AI guess.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":50},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":0},
    {"kind":"reason","label":"A. AI remembers what was said in the meeting, so it will fill in any owners you left out correctly.","score":0},
    {"kind":"reason","label":"B. Meeting notes must be kept exactly as typed, so reorganising them is not allowed.","score":0},
    {"kind":"reason","label":"C. The notes are internal and contain nothing confidential, the task is formatting, and you can compare the list to your own notes.","score":50}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-bc-09', 'Business Consulting', $$The Competitor Profile$$,
  $$AI writes a one-page profile of a competitor from public information, including its founding year, number of stores and latest results. The client meeting is tomorrow.$$,
  $$Use the draft to save time on structure. Check every figure and date against a source you can name, such as the company's annual report, and cut anything you cannot confirm.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI can pull the profile together fast, but it may state outdated or invented facts, so each number should be checked against a current, named source.","score":50},
    {"kind":"reason","label":"B. Public information cannot be wrong, so the profile can go into the client pack as it is.","score":0},
    {"kind":"reason","label":"C. Competitor profiles should never use AI because competitor information is confidential.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-bc-10', 'Business Consulting', $$The Survey Themes$$,
  $$You have 600 anonymised open-ended survey comments from customers. AI groups them into five themes and gives a quote for each. The client wants the themes at the next steering committee.$$,
  $$Treat AI as a first pass. Read a sample of comments under each theme, confirm that each quote exists word for word, and rename or split themes that mix different issues.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. Because the comments are anonymised, the AI's themes are neutral and can be presented as they are.","score":0},
    {"kind":"reason","label":"B. AI can cluster comments quickly, but it may merge distinct issues or invent quotes, so you should check the themes and quotes against the raw comments.","score":50},
    {"kind":"reason","label":"C. Open-ended comments are too subjective for AI, so they must be read and coded entirely by hand.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-bc-11', 'Business Consulting', $$The Model Check$$,
  $$Before a client presentation, you ask AI to scan your Excel financial model for formula errors. It lists three possible problems and says the rest 'looks fine'.$$,
  $$Use AI to point you to possible issues, then check each one. Do your own tests on the outputs that matter, such as totals, sign errors and a rough reasonableness check.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. If the AI says the rest looks fine, the model is error-free and can be shown to the client.","score":0},
    {"kind":"reason","label":"B. Models must only be checked by a second human because AI cannot read formulas.","score":0},
    {"kind":"reason","label":"C. AI is a useful second pair of eyes, but it can miss errors and flag false ones, so you must check its findings and test the key outputs yourself.","score":50}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-bc-12', 'Business Consulting', $$The Recommendation Slides$$,
  $$AI drafts the recommendation section of a deck from your analysis, with five recommendations in confident language. The partner reviews the deck next week.$$,
  $$The draft is a starting point. For each recommendation, trace it back to a finding, test whether the client could actually do it, and soften any claim the evidence does not support.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI can draft the story, but you must check that each recommendation follows from the evidence and fits the client's budget and constraints before it is shown to anyone.","score":50},
    {"kind":"reason","label":"B. The recommendations came from your analysis, so they are bound to follow from the evidence.","score":0},
    {"kind":"reason","label":"C. Recommendations are the consultant's core value and must be written without any AI support.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-bc-13', 'Business Consulting', $$The Public Chatbot Upload$$,
  $$Your client shared an unreleased strategy deck under a confidentiality agreement. To save time, a teammate proposes uploading it to a free public AI chatbot for a summary. The firm has no approved tool.$$,
  $$Do not put confidential client documents into public AI tools. Read the deck yourself, or ask your manager whether an approved tool or client consent is available.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. A summary does not reveal anything new, so uploading the deck cannot breach confidentiality.","score":0},
    {"kind":"reason","label":"B. Confidential client material would leave the firm's control and could breach the confidentiality agreement, so it should not go into a public tool without the client's permission.","score":50},
    {"kind":"reason","label":"C. AI summaries are inaccurate, so the only objection is that you would need to check the output.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-bc-14', 'Business Consulting', $$The Missing Benchmark$$,
  $$A slide needs an industry benchmark for staff turnover, but you cannot find one. The deadline is today, and a colleague suggests asking AI to 'give a realistic number' to put on the slide.$$,
  $$Never present an invented number as a fact. If no benchmark exists, say so, show a clearly labelled assumption, or explain what data would be needed.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. If the figure is realistic and close to the truth, it is acceptable to show it as a benchmark.","score":0},
    {"kind":"reason","label":"B. AI cannot suggest any numbers, so benchmarks must always be found in published reports.","score":0},
    {"kind":"reason","label":"C. A made-up number presented as a benchmark misleads the client, so either find a real source, label an estimate as your own assumption, or leave it out.","score":50}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-bc-15', 'Business Consulting', $$The Suspicious Numbers$$,
  $$While analysing a client's accounts, you notice that revenue seems to have been overstated near year-end. Your manager asks AI whether the team should raise it with the client's audit committee.$$,
  $$AI can help you check your analysis and summarise the facts. Deciding what to do about a possible misstatement needs a partner, the firm's policies and often legal input.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. Whether and how to raise a possible misstatement is a professional and ethical judgement, so it should go to the partner or the firm's ethics channel, not be decided by AI.","score":50},
    {"kind":"reason","label":"B. AI can decide the matter objectively, which removes the awkwardness of a human decision.","score":0},
    {"kind":"reason","label":"C. Any possible irregularity should immediately be reported to the audit committee without first discussing it with the partner.","score":0}
  ]$j$::jsonb
);
