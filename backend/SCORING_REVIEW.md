# VerifAI — Scoring Algorithm Review

An evaluation of the scoring algorithm specified in *Deliverable 3, Tasks 6–7*
(architecture + data design), assessed against the product's requirements
(FR4 independent scoring, NFR1 performance, NFR9 auditability) and the current
backend implementation.

---

## 1. What the doc specifies

- **Per-skill verification methods (§8.2):**
  | Skill | Method |
  |---|---|
  | Verification | Exact / structured match against task answer criteria |
  | Judgement | Controlled-choice or predefined classification match |
  | Prompt Design | Checklist + keyword/pattern rules |
  | Risk & Governance | Required rule/keyword checks |
  | Human-AI Collaboration | Presence/absence of required improvement elements |
- **Scoring model (§8.4):** 9-element prompt checklist, each criterion
  present (1) / absent (0); N/A criteria removed from the denominator;
  `score = passed / applicable × 100`; bands Advanced 7–9, Developing 4–6,
  Needs Improvement 0–3; per-criterion `weight` (`ScoringCriterion.weight`).
- **Transparency (§8.5) + refinement (§9):** return which criteria passed and
  failed, deterministic feedback, optional template for missing elements, allow
  revision, re-score with the same criteria.
- **Review/correction logic (§10.1):** compare selected issue + corrected value
  (+ numeric tolerance) + explanation terms; one `VerificationResult` per
  criterion, then aggregate.
- **Infrastructure:** deterministic core (no model latency/variance);
  `Task.version` + `Submission.task_version` pin a submission to the criteria
  used when it was scored.

## 2. Strengths

- **Deterministic and auditable** — satisfies FR4 (independent scoring) and
  NFR1 (3s) cleanly; no LLM in the scoring path.
- **Criterion-level results** (`VerificationResult`) → specific feedback
  instead of a bare pass/fail.
- **Version pinning** of task + criteria → old submissions stay reproducible
  after content edits (strong for NFR9).
- **Weighting + N/A handling** → more flexible and fairer than flat keyword
  counting.
- **Interpretable bands** → good fit for the supportive, Duolingo-style UX.

## 3. Weaknesses / gaps (ranked)

1. **Keyword/pattern brittleness.** Only case/punctuation/spelling normalisation
   is mentioned — no **synonyms, paraphrase, or negation** handling. A
   semantically correct answer that misses the exact term is penalised; a
   keyword used negatively ("I will *not* anonymise") can falsely pass.
2. **Binary criteria, no intra-criterion partial credit.** Present/absent only —
   coarse for free-text reasoning.
3. **Gaming surface in the prompt checklist.** A minimal prompt that merely
   *lists* the 9 elements scores 9/9; presence ≠ quality. No anti-gaming guard.
4. **Aggregation under-specified.** The doc says criterion results "aggregate
   into skill and readiness scores" but gives **no formula** for the skill
   score, **no weighting across the five skills**, and **no attempt policy**
   (best / average / latest). The headline readiness score is effectively
   undefined.
5. **Weight normalisation undefined.** If `ScoringCriterion.weight` is not
   normalised, denominators drift and scores are not comparable across tasks.
6. **Business-Consulting-specific.** §8 is titled "Business Consulting
   Algorithm" and the 9-element checklist is consulting-shaped; other tracks
   need their own element sets.
7. **Exact-match rigidity for Verification** can reject legitimate alternative
   correct answers.
8. **English-only** keyword matching (relevant in the SA context).
9. **Revision loop semantics unspecified** — does a resubmit create a new
   `Submission`, and does the skill score recompute from scratch? Affects score
   inflation.

## 4. Fit with the new AI Judgement scoring

The **decision (50/25/0) + reason (50/0)** scheme is the strongest part of the
design: a pure controlled-choice match (§8.2 Judgement), fully deterministic,
and needing no keyword matching. It maps cleanly to **two weighted criteria**
(decision, reason; 0.5/0.5) or per-option `score` values.

Caveats:
- The **"neighbouring" 25** requires the three decisions to be an explicit
  **ordered scale** — encode the order, do not infer it from labels.
- D3 T6-7 predates this rule (it only says "controlled-choice match"); it should
  be updated to record the two-part structure and the 50/25/0 + 50/0 weights.

## 5. Gap vs the current implementation

The shipped code (`backend/services/scoringService.js`) is a **keyword-ratio
approximation** — `extractKeywords()` (expects a `Keywords:` prefix), match
ratio × 100, `passed ≥ 60` — with **no** `ScoringCriterion`, no
`VerificationResult`, no weights, no per-criterion feedback, and no prompt
checklist. It is a placeholder, not the D3 algorithm, and it currently scores
≈0 because live `correct_answer` values have no `Keywords:` prefix.

## 6. Recommendations

1. **Define the aggregation formula now** — skill score from criterion results,
   weights per skill, and an explicit attempt policy.
2. **Add synonym + negation handling** (accepted-answer sets / phrase matching
   with negation windows) before trusting free-text criterion scoring.
3. **Encode Judgement as ordered decisions + weighted reasons**
   (50/25/0 + 50/0) — low risk, do it first.
4. **Normalise and document weights**; default equal but authorable.
5. **Add an anti-gaming guard** to the prompt checklist (minimum content /
   element-count sanity).
6. **Generalise the checklist per track** — Legal / IT / Finance element sets.
7. **Keep LLM out of scoring** (FR4); if used at all, only to reword feedback.

## 7. Verdict

Architecturally sound and well-suited to the product's "auditable,
deterministic" positioning, and the new AI Judgement scheme is genuinely solid.
But as written it is **incomplete on the most important point — how criteria
roll up into skill and overall readiness scores** — and **too brittle for
free-text** without synonym/negation handling. Treat §8.4–§8.5 as a good
checklist engine, not a finished scoring algorithm.
