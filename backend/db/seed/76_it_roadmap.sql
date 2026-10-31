-- 76_it_roadmap.sql — IT / Software roadmap: five stages, ten milestones.
--
-- The milestone codes, requirement types and targets are identical for every
-- track (the evaluator never special-cases one); only titles and descriptions
-- are domain-specific. Copy is one sentence, second person, with no XP or
-- streak wording and no promise of a job or certificate.
--
-- Idempotent through seed_roadmap() (73_roadmap_helpers.sql). Have the IT / Software
-- domain owner review the wording before launch.

SELECT seed_roadmap('IT / Software', $j$[
 {
  "code": "orient",
  "title": "Orientation",
  "outcome": "Know how VerifAI works and check your first AI output.",
  "description": "Start here: see where everything lives, then check your first piece of AI output.",
  "milestones": [
   {
    "code": "tour",
    "title": "Take the IT / Software tour",
    "description": "See where everything lives and what the four skills mean in IT / Software.",
    "type": "tutorial_completed",
    "target": 1,
    "action_label": "Take the tour",
    "route": "/welcome-tour",
    "filter": {
     "tour_key": "industry"
    },
    "action_label_done": "Replay tour"
   },
   {
    "code": "first-check",
    "title": "Review generated code for a confident bug",
    "description": "Pass one Verification task by finding the flaw in AI-generated code or output.",
    "type": "tasks_passed",
    "target": 1,
    "action_label": "Start your first verification task",
    "route": "/verification",
    "filter": {
     "feature": "verification"
    }
   }
  ]
 },
 {
  "code": "verify",
  "title": "Verify",
  "outcome": "Catch confident mistakes in AI output.",
  "description": "Build the habit of checking before you trust.",
  "milestones": [
   {
    "code": "verify-three",
    "title": "Catch three confident mistakes",
    "description": "Pass three Verification tasks in IT / Software.",
    "type": "tasks_passed",
    "target": 3,
    "action_label": "Pass your next verification task",
    "route": "/verification",
    "filter": {
     "feature": "verification"
    }
   },
   {
    "code": "verify-hard",
    "title": "Catch a subtle bug in generated code",
    "description": "Pass one medium or hard Verification task.",
    "type": "tasks_passed",
    "target": 1,
    "action_label": "Try a harder verification task",
    "route": "/verification",
    "filter": {
     "feature": "verification",
     "difficulty": [
      "medium",
      "hard"
     ]
    }
   }
  ]
 },
 {
  "code": "judge-govern",
  "title": "Judge & govern",
  "outcome": "Decide when AI should and should not be used.",
  "description": "Move from spotting errors to making and justifying decisions.",
  "milestones": [
   {
    "code": "judge-two",
    "title": "Decide when AI can ship code",
    "description": "Pass two AI Judgement tasks about when AI output can ship and when a person must review it.",
    "type": "tasks_passed",
    "target": 2,
    "action_label": "Start a judgement task",
    "route": "/judgement",
    "filter": {
     "feature": "judgement"
    }
   },
   {
    "code": "govern-two",
    "title": "Spot security, licensing and data risk",
    "description": "Pass two Risk & Governance tasks on security, licensing and data risk.",
    "type": "tasks_passed",
    "target": 2,
    "action_label": "Start a governance task",
    "route": "/risk-governance",
    "filter": {
     "feature": "risk_governance"
    }
   }
  ]
 },
 {
  "code": "apply",
  "title": "Apply",
  "outcome": "Use verification in your IT / Software context.",
  "description": "Connect what you have learned to real IT / Software situations.",
  "milestones": [
   {
    "code": "cases-three",
    "title": "Read three IT cases",
    "description": "Read three IT cases to see how AI and data mistakes play out.",
    "type": "industry_cases_read",
    "target": 3,
    "action_label": "Read a case",
    "route": "/industry-practice"
   },
   {
    "code": "capstone-pass",
    "title": "Pass the IT / Software capstone",
    "description": "Score 70 or more on the IT / Software capstone assessment.",
    "type": "capstone_score",
    "target": 70,
    "action_label": "Start the capstone",
    "route": "/ai-lab/assessments"
   }
  ]
 },
 {
  "code": "prove",
  "title": "Prove readiness",
  "outcome": "Show a level of readiness you can take to an employer.",
  "description": "Reach Proficient readiness and keep your recall sharp.",
  "credential_title": "AI Readiness Passport",
  "credential_description": "Complete all five stages and reach Proficient readiness.",
  "milestones": [
   {
    "code": "readiness-70",
    "title": "Reach Proficient readiness",
    "description": "Reach a readiness score of 70, the Proficient tier.",
    "type": "readiness_score",
    "target": 70,
    "action_label": "See your readiness",
    "route": "/progress"
   },
   {
    "code": "activities-five",
    "title": "Complete five IT recall drills",
    "description": "Pass five recall activities in the AI Lab.",
    "type": "activities_passed",
    "target": 5,
    "action_label": "Start a recall drill",
    "route": "/ai-lab/practice",
    "filter": {
     "scope": "track_or_global"
    }
   }
  ]
 }
]$j$::jsonb);
