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

-- ===========================================================================
-- Set 2 (10 tasks) — VerifAI_IT_Software_AI_Judgement_Tasks_Set2.pdf
-- ===========================================================================

SELECT seed_choice_task(
  'judgement', 'judgement-it-06', 'IT / Software', $$The Phone Number Pattern$$,
  $$A sign-up form needs to accept South African mobile numbers written as 0821234567 or +27821234567. You ask AI for a regular expression and plan to test it with a list of valid and invalid numbers.$$,
  $$Good use of AI. Regular expressions are tedious to write and easy to test. Try numbers that should pass and ones that should fail, including edge cases such as spaces and the +27 prefix.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":50},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":0},
    {"kind":"reason","label":"A. It is a small, low-risk piece of code with no sensitive data, and you can test it with examples before using it.","score":50},
    {"kind":"reason","label":"B. Regular expressions from AI are correct for every format, so testing is unnecessary.","score":0},
    {"kind":"reason","label":"C. Validation code is security-critical, so any AI-generated pattern is banned.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-it-07', 'IT / Software', $$The Screen Skeleton$$,
  $$You need a starting layout for a new login screen in Flutter. You ask AI for a skeleton with a logo placeholder, two fields and a button, with no real keys or project secrets.$$,
  $$Boilerplate is where AI helps most. You still own the code: run it, tidy it to match the team's style, and remove anything you do not need.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":50},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":0},
    {"kind":"reason","label":"A. AI-generated layout code is production-ready, so it can be committed without running it.","score":0},
    {"kind":"reason","label":"B. It is boilerplate you will edit anyway, no secrets are shared, and you will run and review the code before it is committed.","score":50},
    {"kind":"reason","label":"C. UI code must always be typed by hand so that the team can claim authorship.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-it-08', 'IT / Software', $$The Stack Trace$$,
  $$Your local build crashes with a null pointer error. You paste the error message and the three relevant lines of code into AI. The snippet contains no passwords, keys or customer data.$$,
  $$A sensible use of AI. Before you paste anything, check it for secrets, tokens and personal data. Then test the suggestion yourself instead of assuming it is right.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":50},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":0},
    {"kind":"reason","label":"A. Any code you paste into AI is safe because the company that runs the tool is trusted.","score":0},
    {"kind":"reason","label":"B. Debugging must be done without assistance, because a developer who asks AI is not learning.","score":0},
    {"kind":"reason","label":"C. The snippet is small and harmless, AI is good at explaining errors, and you can check its explanation by running the fix locally.","score":50}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-it-09', 'IT / Software', $$The Schema Migration$$,
  $$AI writes an SQL migration that renames a column and adds an index on the production database of a live app. The change would run tonight.$$,
  $$Treat the script as a draft. Check what else uses the old column name, test on a staging copy, time how long the index takes to build, take a backup and know how to undo the change.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI can write the script, but it can miss dependencies and locks, so a developer must review it, test it on a copy of the data, and have a backup and a rollback plan.","score":50},
    {"kind":"reason","label":"B. A migration is just a few lines of SQL, so if the syntax is valid it is safe to run on production.","score":0},
    {"kind":"reason","label":"C. Database changes must never use AI because AI cannot read SQL.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-it-10', 'IT / Software', $$The Library Upgrade$$,
  $$A library your app depends on has a new major version. AI rewrites your code to use it and says 'this will work without changes elsewhere'.$$,
  $$Use AI to do the repetitive changes, then check the changelog for breaking changes, run all your tests, and try the main user flows before merging.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI has read the library's documentation, so its statement that nothing else changes can be trusted.","score":0},
    {"kind":"reason","label":"B. AI can speed up the rewrite, but major versions often change behaviour in ways it cannot see, so the team should read the release notes and run the full test suite before merging.","score":50},
    {"kind":"reason","label":"C. Major upgrades must never be attempted with AI, only by manually editing every file.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-it-11', 'IT / Software', $$The Unit Tests$$,
  $$AI writes 20 unit tests for a discount calculation function, and all of them pass on the first run. The team is pleased and wants to merge.$$,
  $$Passing tests only mean the code does what the tests expect. Read the tests against the real rules, such as when discounts stop and what happens at boundary values, and add the cases the AI missed.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. If all tests pass, the function is correct, so no one needs to look at what the tests check.","score":0},
    {"kind":"reason","label":"B. AI cannot write tests because it cannot run code, so the tests should be deleted.","score":0},
    {"kind":"reason","label":"C. AI can write tests quickly, but tests built from existing code may simply repeat its mistakes, so a developer should check that they assert what the business rules say.","score":50}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-it-12', 'IT / Software', $$The Pipeline File$$,
  $$AI generates a CI/CD configuration that builds the app and deploys it to Railway on every merge. It includes an environment variable block already filled with values.$$,
  $$Use the draft as a starting point. Move secrets to the platform's secret store, restrict who and what can deploy, and make sure unreviewed code cannot reach production.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":25},
    {"kind":"decision","label":"Use AI with human review","score":50},
    {"kind":"decision","label":"Don't use AI","score":25},
    {"kind":"reason","label":"A. AI can draft the pipeline, but a person must check permissions, remove any real secrets from the file and confirm that only reviewed code reaches production.","score":50},
    {"kind":"reason","label":"B. Pipeline files are only configuration, so they cannot cause security problems.","score":0},
    {"kind":"reason","label":"C. A deployment pipeline must be built by hand because AI is not allowed to touch deployment.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-it-13', 'IT / Software', $$The Pasted Config$$,
  $$The app cannot connect to the database. A teammate suggests pasting the whole production .env file, with the database URL and all API keys, into a public AI chat to get a quick answer.$$,
  $$Never share secrets with an outside tool. Describe the error, hide or replace the values, and change any key that has already been pasted. AI can still help diagnose the problem without them.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. AI tools are secure by default, so pasting the file is fine when the problem is urgent.","score":0},
    {"kind":"reason","label":"B. Secrets pasted into an outside tool are out of the company's control, so debug with the values removed and rotate any secret that has been shared.","score":50},
    {"kind":"reason","label":"C. AI can never help with connection errors, so the question should not be asked at all.","score":0}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-it-14', 'IT / Software', $$The Self-Approving Agent$$,
  $$To speed up releases, a team lead proposes letting an AI agent write code, approve its own pull requests and merge them to the main branch with no human involved.$$,
  $$AI can write and suggest changes, and can even act as an extra reviewer. But a person who understands the system must approve changes before they reach main, and be accountable for them.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. AI reviews are more thorough than human reviews, so a human adds only delay.","score":0},
    {"kind":"reason","label":"B. AI should not write any code for the main branch, even when a developer reviews it.","score":0},
    {"kind":"reason","label":"C. Code should be reviewed by someone independent of the author, and an AI approving its own work removes that check and leaves no accountable person.","score":50}
  ]$j$::jsonb
);

SELECT seed_choice_task(
  'judgement', 'judgement-it-15', 'IT / Software', $$The Home-Made Encryption$$,
  $$You need to protect customers' ID numbers in the database. A colleague asks AI to invent a new encryption method that is 'unique to our company so nobody can break it'.$$,
  $$Never invent your own cryptography. Use a standard, such as AES with a well-reviewed library, and manage keys properly. AI is fine for explaining how to use these tools, but a new algorithm would not have been tested by anyone.$$,
  $j$[
    {"kind":"decision","label":"Use AI","score":0},
    {"kind":"decision","label":"Use AI with human review","score":25},
    {"kind":"decision","label":"Don't use AI","score":50},
    {"kind":"reason","label":"A. Secure encryption comes from well-tested standards that experts have attacked for years, so use a proven library and let AI help you use it correctly, not invent a new one.","score":50},
    {"kind":"reason","label":"B. A secret method nobody has seen is harder to attack than a public standard.","score":0},
    {"kind":"reason","label":"C. Customer data does not need encryption if the database already requires a password.","score":0}
  ]$j$::jsonb
);
