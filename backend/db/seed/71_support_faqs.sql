-- 71_support_faqs.sql — the ten beginner FAQs from the QA list.
-- Idempotent: upserts on slug; admin edits (newer updated_at) are preserved.

INSERT INTO faqs (slug, question, answer_md, topic, sort_order, published, updated_at)
VALUES ('what-is-verifai-and-how-does-it-work', 'What is VerifAI and how does it work?',
$md$VerifAI measures and builds your **AI workplace readiness**. You work through realistic scenarios in your industry, find and fix flawed AI output, and explain your decisions. Each graded attempt updates a readiness score from 0 to 100.

The loop is: learn a concept, practise a scenario, take an assessment, see your evidence, keep the habit going.$md$,
'basics', 10, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  question = EXCLUDED.question, answer_md = EXCLUDED.answer_md, topic = EXCLUDED.topic,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE faqs.updated_at <= EXCLUDED.updated_at;

INSERT INTO faqs (slug, question, answer_md, topic, sort_order, published, updated_at)
VALUES ('how-do-i-change-my-industry', 'How do I change my industry?',
$md$Tap the industry label on Home, choose **Change** in the menu, or open **Your industry** on Profile. Read the short explanation, pick the new industry and confirm.

Your XP, level, streak and tokens are kept. Readiness and skill scores are separate for each industry, so a new industry starts at Novice. Your earlier progress is saved and comes back if you switch back.$md$,
'industry', 20, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  question = EXCLUDED.question, answer_md = EXCLUDED.answer_md, topic = EXCLUDED.topic,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE faqs.updated_at <= EXCLUDED.updated_at;

INSERT INTO faqs (slug, question, answer_md, topic, sort_order, published, updated_at)
VALUES ('what-happens-if-i-skip-the-tutorial', 'What happens if I skip the tutorial?',
$md$Nothing is lost. You can use the whole app straight away.

You can replay the welcome tour any time from Help or Profile. If you skipped it, Home shows a Getting started card until you dismiss it. Each industry also has its own short introduction.$md$,
'onboarding', 30, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  question = EXCLUDED.question, answer_md = EXCLUDED.answer_md, topic = EXCLUDED.topic,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE faqs.updated_at <= EXCLUDED.updated_at;

INSERT INTO faqs (slug, question, answer_md, topic, sort_order, published, updated_at)
VALUES ('what-are-learn-and-practice-for', 'What are Learn and Practice for?',
$md$**Learn** is where you build understanding: lessons, recall activities and capstone assessments in the AI Lab.

**Practice** is where you apply it: scenario tasks for Verification, AI Judgement and Risk & Governance, plus Verification Studio for your own material.

Use them together: read a lesson, then try a scenario on the same idea.$md$,
'learning', 40, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  question = EXCLUDED.question, answer_md = EXCLUDED.answer_md, topic = EXCLUDED.topic,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE faqs.updated_at <= EXCLUDED.updated_at;

INSERT INTO faqs (slug, question, answer_md, topic, sort_order, published, updated_at)
VALUES ('what-is-verification-studio', 'What is Verification Studio?',
$md$Verification Studio checks your own material. Paste an AI answer, upload a PDF or Word document, add a link, or give a citation. You get a report with the claims it checked, the sources it found and the items a person should review.

It is a helper, not a guarantee. Your submitted material is not stored; only the report is.$md$,
'verification', 50, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  question = EXCLUDED.question, answer_md = EXCLUDED.answer_md, topic = EXCLUDED.topic,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE faqs.updated_at <= EXCLUDED.updated_at;

INSERT INTO faqs (slug, question, answer_md, topic, sort_order, published, updated_at)
VALUES ('how-do-i-use-vera', 'How do I use Vera?',
$md$Open Vera from the app and type your question. She can explain concepts, help you think through a scenario, suggest what to practise and check a claim when you ask.

You can see, add and delete what she remembers about you. She can be wrong, so check anything important, and do not share passwords or confidential client data.$md$,
'vera', 60, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  question = EXCLUDED.question, answer_md = EXCLUDED.answer_md, topic = EXCLUDED.topic,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE faqs.updated_at <= EXCLUDED.updated_at;

INSERT INTO faqs (slug, question, answer_md, topic, sort_order, published, updated_at)
VALUES ('what-does-the-readiness-score-mean', 'What does the readiness score mean?',
$md$It is a score from 0 to 100 that shows how much of your industry's AI-readiness work you have covered and passed. Tiers are Novice (0 to 49), Developing (50 to 69), Proficient (70 to 84) and Advanced (85 to 100).

Coverage counts, so covering every area beats excelling in one. The score can move down as well as up.$md$,
'progress', 70, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  question = EXCLUDED.question, answer_md = EXCLUDED.answer_md, topic = EXCLUDED.topic,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE faqs.updated_at <= EXCLUDED.updated_at;

INSERT INTO faqs (slug, question, answer_md, topic, sort_order, published, updated_at)
VALUES ('how-do-xp-streaks-achievements-and-tokens-work', 'How do XP, streaks, achievements and tokens work?',
$md$- **XP** comes from graded attempts and is never spent. It raises your level.
- **Streak** counts consecutive days with activity, in South African time.
- **Achievements** are optional badges for milestones.
- **Tokens** are spendable. You earn them when you gain a level and when you earn an achievement, and you spend them in Rewards.$md$,
'progress', 80, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  question = EXCLUDED.question, answer_md = EXCLUDED.answer_md, topic = EXCLUDED.topic,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE faqs.updated_at <= EXCLUDED.updated_at;

INSERT INTO faqs (slug, question, answer_md, topic, sort_order, published, updated_at)
VALUES ('why-can-verification-fail', 'Why can verification fail?',
$md$Common reasons:

- The file is over the size limit, or it is a scanned image with no readable text.
- The link is private, blocked or unreachable.
- There is no internet connection.
- The AI service is briefly unavailable.
- There was too little text to check.

Try pasting the text, use a text-based file, or try again in a minute. If the report says a check could not run, treat the result as unchecked, not as correct.$md$,
'verification', 90, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  question = EXCLUDED.question, answer_md = EXCLUDED.answer_md, topic = EXCLUDED.topic,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE faqs.updated_at <= EXCLUDED.updated_at;

INSERT INTO faqs (slug, question, answer_md, topic, sort_order, published, updated_at)
VALUES ('how-do-i-log-out-and-manage-my-account', 'How do I log out and manage my account?',
$md$Choose **Log out** in the menu. You return to the login screen.

Manage your details from **Profile**. If you delete your account, your profile and learner data are removed, along with any support messages you sent while signed in.$md$,
'account', 100, TRUE, '2026-10-22T00:00:00Z')
ON CONFLICT (slug) DO UPDATE SET
  question = EXCLUDED.question, answer_md = EXCLUDED.answer_md, topic = EXCLUDED.topic,
  sort_order = EXCLUDED.sort_order, published = EXCLUDED.published,
  updated_at = EXCLUDED.updated_at
WHERE faqs.updated_at <= EXCLUDED.updated_at;

