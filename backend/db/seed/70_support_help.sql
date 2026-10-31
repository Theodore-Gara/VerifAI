-- 70_support_help.sql — help articles and the About page.
--
-- Content-driven support (BB-1). Idempotent: upserts on slug. A row is only
-- overwritten when its updated_at is not newer than this file's content date,
-- so an edit made through the admin support console is never reverted by a
-- re-seed. To ship revised wording, change the text AND raise the date below.
--
-- Markdown only (headings, lists, bold); no raw HTML, so the app renders it
-- with its standard markdown widget.

INSERT INTO help_articles (slug, title, summary, body_md, category, audience, sort_order, published, updated_at)
VALUES ('what-is-verifai', 'What VerifAI is', 'VerifAI builds your AI workplace readiness through realistic work, not theory.',
$md$## The short version

VerifAI helps you get ready to work with AI at work. Instead of teaching prompt tricks, it gives you realistic workplace scenarios that contain a flawed AI answer or a judgement call. You find the problem, fix it, and explain your decision.

## The loop

1. **Learn** the concept in the AI Lab.
2. **Practise** a scenario in your industry.
3. **Get assessed** in a timed capstone.
4. **See your evidence** on Progress and your readiness path.
5. **Keep the habit** with a daily streak.

## Who it is for

Final-year students, graduates and early-career professionals in four South African industries: Finance, Legal, IT / Software and Business Consulting.

## What the score means

Every graded attempt feeds a readiness score from 0 to 100. It rewards coverage: acing one area and skipping the rest will not get you a high score. See "Progress, XP, streaks, achievements and tokens" for the detail.

## Where to go next

- New here? Take the welcome tour from Help.
- Not sure where things are? Read "Getting around the app".
- Want to know what the home screen cards mean? Read "Dashboard cards explained".$md$,
'start', 'all', 10, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, summary = EXCLUDED.summary, body_md = EXCLUDED.body_md,
  category = EXCLUDED.category, audience = EXCLUDED.audience,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE help_articles.updated_at <= EXCLUDED.updated_at;

INSERT INTO help_articles (slug, title, summary, body_md, category, audience, sort_order, published, updated_at)
VALUES ('getting-around-the-app', 'Getting around the app', 'The five areas, the menu, and how to get back to Home from anywhere.',
$md$## The five areas

The bar at the bottom always shows the same five areas:

- **Home**: your next recommended task, your readiness and your streak.
- **Learn**: the AI Lab with lessons, practice activities and capstone assessments.
- **Practice**: scenario tasks and Verification Studio.
- **Progress**: your readiness, skill scores and your readiness path.
- **Profile**: your details, achievements and account actions.

## The menu

The menu button in the top bar opens a full list of everything in the app, including Help, About and Contact. It is a second way to get around, not a replacement for the bottom bar.

## Going back

- The back arrow on a screen returns you to the screen you came from.
- Tapping **Home** in the bottom bar always takes you back to your home screen.

## Finding help

Use **Get help** in the menu, the "Need help?" link on Home, or the help link on a verification error. Help works even when you are offline, because the guides are stored on your phone.$md$,
'navigation', 'all', 20, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, summary = EXCLUDED.summary, body_md = EXCLUDED.body_md,
  category = EXCLUDED.category, audience = EXCLUDED.audience,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE help_articles.updated_at <= EXCLUDED.updated_at;

INSERT INTO help_articles (slug, title, summary, body_md, category, audience, sort_order, published, updated_at)
VALUES ('choosing-and-changing-your-industry', 'Choosing and changing your industry', 'Pick the pathway that fits your career, and switch later without losing your XP.',
$md$## Choosing an industry

When you first sign up you choose one of four pathways: Finance, Legal, IT / Software or Business Consulting. Each card has a **Learn more** link that opens a guide to the pathway before you commit. Tapping Learn more does not select the industry.

## What your industry controls

- The tasks, cases and lessons you see.
- Your readiness score and skill scores.
- Your readiness path and its milestones.
- The introduction tour you are offered.

## Changing your industry

You can change at any time:

1. Tap the industry label on Home, or choose **Change** in the menu, or open **Your industry** on Profile.
2. Read the short explanation on the screen.
3. Pick the new industry and confirm.

## What is kept and what is separate

- **Kept:** your XP, level, streak and tokens. They belong to you, not to one industry.
- **Separate per industry:** readiness, skill scores and roadmap progress. A new industry starts at Novice.
- **Saved:** your earlier industry's progress is stored. If you switch back, it is restored.

## After you switch

You will be offered a short introduction for the new industry. You can skip it and replay it later from Help.$md$,
'industry', 'all', 30, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, summary = EXCLUDED.summary, body_md = EXCLUDED.body_md,
  category = EXCLUDED.category, audience = EXCLUDED.audience,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE help_articles.updated_at <= EXCLUDED.updated_at;

INSERT INTO help_articles (slug, title, summary, body_md, category, audience, sort_order, published, updated_at)
VALUES ('dashboard-cards-explained', 'Dashboard cards explained', 'What each card on Home measures and where it takes you.',
$md$## Your next task

One recommended task, with its skill area and difficulty. VerifAI prefers tasks you have not seen. When you have seen them all, it brings back the one you attempted longest ago and labels it **Practise again**.

## Readiness

A score from 0 to 100 with a tier: Novice, Developing, Proficient or Advanced. It is built from how much of your industry's content you have passed, so it grows as you cover more ground. Open Progress to see what is driving it.

## XP and level

XP is earned from graded attempts, in proportion to your score and the task's difficulty. XP never gets spent, and it fills your level bar.

## Streak

The number of days in a row you have done something that counts. Days are counted in South African time.

## Tasks completed

How many different tasks you have passed in your industry.

## Quick-access tiles

Shortcuts to the main areas, such as Verification Studio, the AI Lab and Vera. Each tile has an info button that explains it.

## Getting started card

If you skipped the welcome tour, a Getting started card offers it again. You can dismiss it and still replay the tour from Help.$md$,
'features', 'all', 40, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, summary = EXCLUDED.summary, body_md = EXCLUDED.body_md,
  category = EXCLUDED.category, audience = EXCLUDED.audience,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE help_articles.updated_at <= EXCLUDED.updated_at;

INSERT INTO help_articles (slug, title, summary, body_md, category, audience, sort_order, published, updated_at)
VALUES ('learn-ai-lab', 'Learn: the AI Lab', 'Short lessons, recall practice and capstone assessments.',
$md$## What Learn is for

Learn builds the concepts you need before and alongside practice: how AI models produce answers, why they sound sure when they are wrong, and how to check them in your industry.

## What is inside

- **Lessons** built from chapters and topics, with a source library behind them.
- **Practice activities**: quick read-and-recall questions such as multiple choice, true or false, matching and ordering.
- **Capstone assessments**: a timed assessment for your industry that is marked and feeds your readiness.
- **Industry cases**: short real-world stories of what went wrong and how it was fixed.

## How it connects to the rest

Your best capstone result counts towards your readiness. Recall activities and cases are part of your readiness path, so the work you do here shows up as milestones.

## A good way to use it

Read one lesson, do its recall activities straight away, then try a Practice scenario on the same idea.$md$,
'features', 'all', 50, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, summary = EXCLUDED.summary, body_md = EXCLUDED.body_md,
  category = EXCLUDED.category, audience = EXCLUDED.audience,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE help_articles.updated_at <= EXCLUDED.updated_at;

INSERT INTO help_articles (slug, title, summary, body_md, category, audience, sort_order, published, updated_at)
VALUES ('practice-and-skill-scenarios', 'Practice and skill scenarios', 'Scenario tasks for Verification, AI Judgement and Risk & Governance.',
$md$## What Practice is for

Practice puts you in a workplace situation with an AI output or a decision to make. You are scored, you get feedback, and your skill scores move.

## The skill areas

- **Verification**: find the flawed line in an AI output, say how to fix it and why. Some tasks ask you to pick the problem line and write the fix.
- **AI Judgement**: decide whether AI should be used in a situation and justify the decision.
- **Risk & Governance**: spot privacy, security and compliance risks and decide what to do.
- **Prompt Design**: shown on your dashboard, but its tasks are still being added.

## How scoring works

The server marks your answer. You do not see the answer key beforehand. For some Verification tasks you need a good score and a correct flaw and fix, so a convincing explanation alone will not pass.

## Practise again

When you retry a task you have already attempted, it is labelled as practice. Practice passes help your skill coverage a little but do not count the same as a first attempt.

## Tips

- Read the whole scenario before you answer.
- Write your reasoning in your own words; it is part of the marking.
- Read the feedback, even when you pass.$md$,
'features', 'all', 60, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, summary = EXCLUDED.summary, body_md = EXCLUDED.body_md,
  category = EXCLUDED.category, audience = EXCLUDED.audience,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE help_articles.updated_at <= EXCLUDED.updated_at;

INSERT INTO help_articles (slug, title, summary, body_md, category, audience, sort_order, published, updated_at)
VALUES ('verification-studio', 'Verification Studio', 'Check any AI answer, document, link or citation and get a structured report.',
$md$## What it does

Verification Studio is for your own real material. Give it something and it returns a report that says what needs a human to check.

## What you can give it

- A pasted AI answer or any text.
- A PDF or Word document. There is a size limit, shown in the app, and only text-based files can be read.
- A web link.
- A citation, such as a section of an Act. VerifAI searches the web to find sources.

## What the report contains

- An overall status: the material looks sound, needs human review, or could not be checked.
- The claims it checked and the verdict on each.
- Items that need review, with a short reason.
- The sources it found.

## What to remember

- The report is an aid, not a guarantee. If a check could not run, the report says so instead of claiming certainty.
- Your submitted material is not stored. Only the report is kept.
- Do not paste confidential client information unless you are allowed to share it with an online tool.

## If something goes wrong

See "Troubleshooting" and the FAQ "Why can verification fail?".$md$,
'features', 'all', 70, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, summary = EXCLUDED.summary, body_md = EXCLUDED.body_md,
  category = EXCLUDED.category, audience = EXCLUDED.audience,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE help_articles.updated_at <= EXCLUDED.updated_at;

INSERT INTO help_articles (slug, title, summary, body_md, category, audience, sort_order, published, updated_at)
VALUES ('vera-the-assistant', 'Vera, your assistant', 'Ask Vera for coaching, explanations and tips without being handed answers.',
$md$## Who Vera is

Vera is the AI coach built into VerifAI. You can open her from the app and chat about your progress, a concept you are stuck on, or how to approach a kind of task.

## What Vera can do

- Explain a concept in plain language.
- Help you think through a scenario step by step.
- Suggest what to practise next.
- Verify a claim when you ask her to, using live web sources where available.

## Memory you control

Vera can remember a few things about you so her help fits. You can see what she remembers, add notes and delete any item.

## Inside a task

While you work on a task, an assistant can help you reason. It is designed to guide you, not to give you the answer.

## Limits

- Vera can be wrong, like any AI. Check anything important.
- There is a short limit on how many messages you can send per minute. If you hit it, wait a moment and try again.
- Do not share passwords or confidential client data in a chat.$md$,
'features', 'all', 80, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, summary = EXCLUDED.summary, body_md = EXCLUDED.body_md,
  category = EXCLUDED.category, audience = EXCLUDED.audience,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE help_articles.updated_at <= EXCLUDED.updated_at;

INSERT INTO help_articles (slug, title, summary, body_md, category, audience, sort_order, published, updated_at)
VALUES ('progress-xp-streaks-achievements-tokens', 'Progress, XP, streaks, achievements and tokens', 'What each number means and how rewards are earned.',
$md$## Readiness

Your readiness score runs from 0 to 100 and maps to a tier:

- Novice: 0 to 49
- Developing: 50 to 69
- Proficient: 70 to 84
- Advanced: 85 to 100

It combines Verification, AI Judgement, Risk & Governance, Prompt Design, Interview practice and Learning (capstone results), each with its own weight. Only the parts your industry offers count. Coverage matters, so one strong area cannot carry the whole score. The score can go down as well as up, for example if a capstone retake scores lower.

## XP and level

XP comes from graded attempts, in proportion to your score and the difficulty. It is never spent. Your level rises as XP grows.

## Streak

Do something that counts each day to keep your streak. The day boundary is South African time.

## Achievements

Badges for milestones such as your first task, a number of tasks, or a strong skill score. They are optional and can be earned in any order.

## Tokens

Tokens are spendable. You earn them when you gain a level and when you earn an achievement. Spend them in Rewards. Each grant happens once, so a retry cannot double-credit you.

## Your readiness path

The path on Progress is a separate, ordered journey of five stages. It is based on real work you have done and never on XP, streaks or badges.$md$,
'progress', 'all', 90, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, summary = EXCLUDED.summary, body_md = EXCLUDED.body_md,
  category = EXCLUDED.category, audience = EXCLUDED.audience,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE help_articles.updated_at <= EXCLUDED.updated_at;

INSERT INTO help_articles (slug, title, summary, body_md, category, audience, sort_order, published, updated_at)
VALUES ('troubleshooting', 'Troubleshooting', 'Fixes for login problems, content that will not load, verification errors and being offline.',
$md$## I cannot log in

- Check your email and password, or use Reset password.
- If you signed up with Google, use Google sign-in.
- If the app says your account is suspended or banned, use Contact us.
- If you see a maintenance message, the service is briefly offline. Try again shortly.

## Content will not load

1. Check your connection.
2. Pull down on the screen to refresh.
3. Close and reopen the app.
4. If it keeps failing, use Contact us and choose the category Bug.

## Verification failed

- Is the file within the size limit, and a text-based PDF, Word file or plain text? Scanned images cannot be read.
- Is the link public and reachable?
- Paste the text instead if a file keeps failing.
- Try again in a minute. The AI service can be briefly unavailable.

## I am offline

Help, FAQ and the guides are stored on your phone and work offline. Tasks, lessons, Vera and Verification Studio need an internet connection.

## I picked the wrong industry

You can change it at any time. See "Choosing and changing your industry".

## Still stuck?

Use Contact us. Include what you were doing and what you saw. Do not include passwords.$md$,
'troubleshooting', 'all', 100, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, summary = EXCLUDED.summary, body_md = EXCLUDED.body_md,
  category = EXCLUDED.category, audience = EXCLUDED.audience,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE help_articles.updated_at <= EXCLUDED.updated_at;

-- About page: mission, vision, South Africa context, how VerifAI helps.
-- Contact details and the app version are added by the API at read time.
INSERT INTO support_pages (slug, title, data, updated_at)
VALUES ('about', 'About VerifAI',
$j${"mission_md":"VerifAI helps students, graduates and early-career professionals in South Africa work with AI with confidence: to check what it produces, judge when to use it, and manage the risks.","vision_md":"A workforce that uses AI well, where people can show evidence that they can verify, question and take responsibility for AI-assisted work.","south_africa_md":"AI tools are arriving in South African workplaces faster than most people are taught to check them. For graduates, showing real skill with AI is becoming part of being employable. VerifAI practises that skill in realistic local contexts, including awareness of POPIA when personal information meets AI tools.","how_it_helps_md":"VerifAI helps you **learn** the concepts, **practise** with realistic scenarios in your industry, **verify** your own material in Verification Studio, and **build evidence** of your readiness.","who_for_md":"Final-year students, graduates and early-career professionals in Finance, Legal, IT / Software and Business Consulting.","how_it_works":[{"step":1,"title":"Choose your industry","body_md":"Pick the pathway that fits your career. You can change it later."},{"step":2,"title":"Learn","body_md":"Build understanding in the AI Lab."},{"step":3,"title":"Practise with feedback","body_md":"Work through realistic scenarios and get clear feedback."},{"step":4,"title":"Build evidence of readiness","body_md":"Track your readiness and follow your readiness path."}]}$j$::jsonb,
'2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, data = EXCLUDED.data, updated_at = EXCLUDED.updated_at
WHERE support_pages.updated_at <= EXCLUDED.updated_at;
