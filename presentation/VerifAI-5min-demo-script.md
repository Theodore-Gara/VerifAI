# VerifAI - 5 Minute Demo Script

**Format:** one speaker reads, one operator drives the app.
**Speaker:** reads the "SAY" lines only. **Operator:** follows the "DO" lines, nothing else.
**Total:** 5:00. Spoken text is ~720 words, which is a comfortable pace.

---

## Pre-flight (do this 5 minutes before)

1. Open `https://verif-ai-5a435.web.app` and sign in as the demo account. This warms the API, which sleeps on the free tier.
2. Check the demo account already has attempts, so Progress and History are not empty.
3. Phone on the podium, mirrored to the projector, app already signed in as a second backup.
4. Screen recording of the full loop open in a second tab. If the network dies, play it and keep reading.

---

## 0:00 - 0:30 | What VerifAI is

**SAY**
Good morning, we are Group SE16, and this is VerifAI.

Employers now hire graduates who use AI, but nobody can really tell whether they use it well. A CV cannot show judgement, and a quiz about tool names does not measure it either.

So we built an app that puts you inside realistic AI work: an answer with a flaw in it, or a decision that needs a call. You find the problem, fix it, and explain your reasoning. Every attempt feeds one number: your AI workplace readiness score, from zero to a hundred.

**DO**
Hold on the cover. No clicking yet.

---

## 0:30 - 1:00 | Sign in and Home

**DO**
Sign in, then stop on Home.

**SAY**
Signing in takes you straight to Home, and Home always opens on the next best action.

At the top is your readiness score and your tier. Below it, your streak, your XP and how many tasks you have completed. And here is one recommended task, chosen from a difficulty band that suits your level.

Notice what is not here: no wall of charts. The first thing you can do is start work.

---

## 1:00 - 2:10 | Verification, the core loop

**DO**
Practice hub, then Verification, then open a line-text task.

**SAY**
Practice is where the scored skills live. We have Verification, AI Judgement, and Risk and Governance, plus interview practice, a verification studio, industry cases and your task history.

Verification gives you a numbered AI output. Our learner taps the line that is wrong, writes the correction, then writes why. Three parts: the flaw, the fix, and the reason.

**DO**
Select one flawed line, skip the fix and reason, submit.

**SAY**
First, we answer badly on purpose, so you can see that the app is honest.

Picking the flawed line alone does not pass. The rule is a total of seventy or more, with a real score on both the flaw and the fix, because the fix is the skill being tested. The feedback says exactly what was missed and shows the correct answer.

**DO**
Retry, then give the correct lines, the fix, and the reason. Submit.

**SAY**
Now the real attempt. Thirty for the flaw, forty for the fix, thirty for the reason.

On submit, the server scores it, saves the attempt, updates skill coverage, readiness, XP, streak and achievements, all in one transaction. Then it offers the next task, full screen, with no friction.

---

## 2:10 - 2:45 | AI Judgement and Risk

**DO**
Back to Practice, open AI Judgement, choose a decision and a reason.

**SAY**
AI Judgement asks a different question: should AI be used here at all?

You choose between use it, use it with human review, or do not use it, and then pick the best reason. Getting the decision right is worth fifty, a neighbouring answer gets twenty five, the opposite gets nothing, and the reason is another fifty.

Risk and Governance uses the same engine, but the decision is proceed or do not proceed. Same interaction, different judgement.

---

## 2:45 - 3:20 | Learn

**DO**
Learn hub, open a lesson, scroll one chapter, then open a capstone.

**SAY**
Learn is the knowledge side of the product.

AI Lab gives you short lessons built from chapters and topics, with a source library behind them, recall practice, and a skill roadmap.

Capstones work like exams. They are timed, they have a pass mark and a limited number of attempts. Objective questions mark themselves, and longer written answers go to a moderator, with the AI suggesting rubric marks to speed that up.

---

## 3:20 - 3:55 | Progress

**DO**
Progress hub. Point at the readiness breakdown, then the activity chart, then the leaderboard, then open one history row.

**SAY**
Progress is the evidence.

Readiness is broken down by skill, so you can see exactly where you are strong and where you are not. Then XP and level, a thirty day activity chart, and a leaderboard for your track.

History keeps every attempt. And if I open one, it loads the real feedback again, because the result is stored, not kept in the screen.

---

## 3:55 - 4:25 | Wellness and Vera

**DO**
Profile, Wellness, tap a mood. Then open Vera and send one short message.

**SAY**
Profile holds the personal side.

The Wellness Centre gives a daily mood check-in, a private journal, guided breathing and a weekly summary. It is private to the learner.

And this is Vera, our AI coach. Her answers stream in as they are written, so there is no waiting, and she only keeps what you choose to let her remember.

---

## 4:25 - 4:45 | The platform

**DO**
Go back to Home. Keep the readiness number on screen.

**SAY**
Behind all of this is one Flutter app for Android, iOS and web, an Express API, and a PostgreSQL database.

It is fully deployed: a live web build, an installable APK, and a staff portal for content and moderation. Nothing you have seen is a mock-up.

---

## 4:45 - 5:00 | Close

**SAY**
So the loop is simple. Learn the concept, practise a realistic scenario, get assessed, see the evidence, and keep the habit going.

VerifAI does not test whether you know AI. It tests whether you can be trusted with it.

Thank you.

---

## If something breaks

- **API slow or asleep:** keep talking about the screen already on display, then refresh once.
- **Task fails to load:** go to Progress and talk through readiness instead, then return.
- **Total network loss:** switch to the recording, keep the same order of sections.
- **Never** open the admin portal or the Workshop in the five minutes. They are not part of this story.

## Two things not to say

- Do not promise Prompt Design; it has no content yet.
- Do not claim the Workshop is available to learners; only the API and admin side exist.
