-- AI Judgement — IT / Software (5 tasks)
-- Source: VerifAI_IT_Software_AI_Judgement_Tasks.pdf.

SELECT seed_choice_task(
  'judgement', 'judgement-it-01', 'IT / Software',
  $$The Code Comments$$,
  $$You are a junior developer. You wrote a small internal helper function that formats dates for your team's reports. It works and has tests. Your lead asks for a docstring and clear comments before the next code review. You would paste in only this function, with no credentials and no customer data.$$,
  $$Good use of AI. The task is low risk and the output is easy to check. Still read the comments, because AI can describe what code is meant to do rather than what it actually does.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":50},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":0},
    {"kind":"reason","label":"A. The code is yours, it works and is tested, nothing sensitive is shared, and you can read the comments and check they match the code.","score":50},
    {"kind":"reason","label":"B. AI-written comments are always accurate, so there is no need to read them.","score":0},
    {"kind":"reason","label":"C. Developers must write all documentation themselves, so AI should never be used for comments.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-it-02', 'IT / Software',
  $$The Payments Merge$$,
  $$Your team lead asks if a pull request is ready to merge. An AI reviewer says all tests pass and the code is ready. The change touches how payment amounts are calculated, and none of the existing tests cover the new logic.$$,
  $$AI confidence is not the same as correctness. Use the AI review to catch obvious issues, then have the person who owns the payments code check the new logic, add tests for it, and only then merge.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI is a useful first pass, but 'tests pass' says nothing about logic that no test covers, and payment errors cost real money, so the module owner must review the change.","score":50},
    {"kind":"reason","label":"B. If the automated tests pass, the code is safe, so human review only slows the team down.","score":0},
    {"kind":"reason","label":"C. AI reviewers are unreliable, so their output should be ignored completely.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-it-03', 'IT / Software',
  $$The Midnight Outage$$,
  $$A production system fails at midnight. An AI tool suggests restarting several servers and changing some configuration settings. You are the on-call engineer and the system is down for customers.$$,
  $$AI is handy for spotting patterns in logs and suggesting options quickly. The engineer stays in control: understand each change, apply the least risky one first, and make sure it can be undone. Pressure and speed are exactly when blind trust causes bigger problems.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI can help read logs and suggest causes, but an engineer should decide and apply each change, because a wrong configuration change can make the outage worse.","score":50},
    {"kind":"reason","label":"B. The AI should apply every suggested change straight away to restore service as fast as possible.","score":0},
    {"kind":"reason","label":"C. AI must not be used during incidents because it cannot read logs.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-it-04', 'IT / Software',
  $$The Automatic Cleanup$$,
  $$The production database is running low on storage. An AI agent with write access proposes deleting old records and offers to run the command itself, right now. Nobody would approve it first, and no recent backup has been confirmed.$$,
  $$AI can suggest the query and explain the risks, but an irreversible action on production needs an accountable person. Check the exact records, take and test a backup, try it on a test copy first, then run it yourself.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. Deleting data from a live system is hard to undo, so a person must check exactly what will be deleted, confirm a backup and run it, and the AI should not run it on its own.","score":50},
    {"kind":"reason","label":"B. AI is too slow to run database commands.","score":0},
    {"kind":"reason","label":"C. Old records are never useful, so deleting them is always safe.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-it-05', 'IT / Software',
  $$The Automatic Rejection$$,
  $$Your company builds a platform where customers apply for a service. A data scientist proposes using a prediction model to automatically reject applicants who score below a cut-off, with nobody reviewing the rejections.$$,
  $$A model can rank or flag applications, but the final decision should stay with a person. POPIA limits decisions based only on automated processing that significantly affect someone, and a model that is right on average can still be unfair to particular groups.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. A decision that significantly affects people needs an accountable human and a way for the person to challenge it, so the model can support the decision but should not make the final call.","score":50},
    {"kind":"reason","label":"B. Automatic rejection is fine as long as the model is accurate on average.","score":0},
    {"kind":"reason","label":"C. A rejection has little effect on users, so no review is needed.","score":0}
  ]$j$::jsonb
);
