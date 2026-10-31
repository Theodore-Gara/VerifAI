// Milestone tracker engine.
//
// A roadmap is five ordered stages per industry track, each holding
// evidence-based milestones. Status is DERIVED on every read from work the
// learner has already done; nothing per-user is stored, so it cannot drift and a
// learner who did the work before opening the screen sees it as complete.
//
// Evidence only ever grows (distinct passed rows and best-ever scores), so no
// progress can be taken back: a failed retake never removes an earlier pass, and
// a later capstone retake that lowers the live readiness never un-reaches 70.
//
// The roadmap reads no XP, streaks, tokens or achievements, and achievements
// never gate a stage. The two lists must not share data.
//
// The module has two halves: loadEvidence() runs a fixed number of batched
// queries (never one per milestone), and buildRoadmap() is a pure function from
// definitions + evidence to the API response, which is what the tests exercise
// in depth.
const pool = require('../db/pool');
const { contentCache } = require('../utils/ttlCache');
const { tierForScore } = require('./tiers');

const REQUIREMENT_TYPES = [
  'tutorial_completed', 'tasks_passed', 'capstone_score',
  'industry_cases_read', 'activities_passed', 'readiness_score',
];

// Short noun for the UI ("2 / 3 tasks").
const UNIT_BY_TYPE = {
  tutorial_completed: 'tour',
  tasks_passed: 'task',
  capstone_score: 'score',
  industry_cases_read: 'case',
  activities_passed: 'activity',
  readiness_score: 'score',
};

// Score requirements report the best-ever value and may exceed their target;
// counters are capped at the target so the UI never shows "5 / 3".
const SCORE_TYPES = new Set(['capstone_score', 'readiness_score']);

// ---------------------------------------------------------------------------
// Definitions (cached: they change only when the seeds are re-applied)
// ---------------------------------------------------------------------------
async function loadDefinition(trackId, executor = pool) {
  return contentCache.wrap(`roadmap:definition:${trackId}`, async () => {
    const result = await executor.query(
      `SELECT t.id AS track_id, t.name AS track_name,
              s.id AS stage_id, s.code AS stage_code, s.title AS stage_title,
              s.outcome, s.description AS stage_description,
              s.credential_title, s.credential_description,
              m.code AS milestone_code, m.title AS milestone_title,
              m.description AS milestone_description,
              m.requirement_type, m.requirement_target, m.requirement_filter,
              m.action_label, m.action_label_done, m.action_route
         FROM industry_tracks t
         LEFT JOIN roadmap_stages s ON s.track_id = t.id
         LEFT JOIN roadmap_milestones m ON m.stage_id = s.id
        WHERE t.id = $1
        ORDER BY s.sort_order, s.id, m.sort_order, m.id`,
      [trackId],
    );
    if (!result.rows.length) return null;

    const track = { id: result.rows[0].track_id, name: result.rows[0].track_name };
    const stages = [];
    const byId = new Map();
    for (const row of result.rows) {
      if (row.stage_id === null || row.stage_id === undefined) continue;
      let stage = byId.get(row.stage_id);
      if (!stage) {
        stage = {
          code: row.stage_code,
          title: row.stage_title,
          outcome: row.outcome,
          description: row.stage_description,
          credential_title: row.credential_title,
          credential_description: row.credential_description,
          milestones: [],
        };
        byId.set(row.stage_id, stage);
        stages.push(stage);
      }
      if (row.milestone_code) {
        stage.milestones.push({
          code: row.milestone_code,
          title: row.milestone_title,
          description: row.milestone_description,
          type: row.requirement_type,
          target: Number(row.requirement_target),
          filter: row.requirement_filter || {},
          action_label: row.action_label,
          action_label_done: row.action_label_done,
          action_route: row.action_route,
        });
      }
    }
    return { track, stages };
  });
}

// ---------------------------------------------------------------------------
// Optional tables. user_track_progress (track-scoped readiness, BF-6) and
// user_tutorials (tour state, BF-7) ship from the other backend workstream.
// Until they exist the roadmap still works: the tour milestone cannot be
// completed and readiness falls back to the single mirrored value in
// user_progress. Remove this shim once both migrations are applied everywhere.
// A positive answer is final; a negative one is re-checked after a minute.
// ---------------------------------------------------------------------------
let schemaFeatures = { trackProgress: false, tutorials: false, checkedAt: 0 };
const SCHEMA_RECHECK_MS = 60 * 1000;

async function detectSchema(executor = pool) {
  if (schemaFeatures.trackProgress && schemaFeatures.tutorials) return schemaFeatures;
  if (Date.now() - schemaFeatures.checkedAt < SCHEMA_RECHECK_MS) return schemaFeatures;
  try {
    const result = await executor.query(
      `SELECT to_regclass('public.user_track_progress') IS NOT NULL AS track_progress,
              to_regclass('public.user_tutorials') IS NOT NULL AS tutorials`,
    );
    const row = result.rows[0] || {};
    schemaFeatures = {
      trackProgress: row.track_progress === true,
      tutorials: row.tutorials === true,
      checkedAt: Date.now(),
    };
  } catch {
    schemaFeatures = { ...schemaFeatures, checkedAt: Date.now() };
  }
  return schemaFeatures;
}

function resetSchemaDetection() {
  schemaFeatures = { trackProgress: false, tutorials: false, checkedAt: 0 };
}

// ---------------------------------------------------------------------------
// Evidence: one batched query per requirement type, in parallel.
// ---------------------------------------------------------------------------
async function loadEvidence({ userId, trackId, activeTrackId }, executor = pool) {
  const features = await detectSchema(executor);

  const tasks = executor.query(
    // Distinct tasks passed on a first-class (non-practice) attempt. Difficulty
    // lives on verification_tasks, not on tasks, hence the LEFT JOIN. One row
    // per (feature, difficulty) lets every task milestone of the track be
    // answered from this single result.
    `SELECT t.feature, vt.difficulty, COUNT(DISTINCT ta.task_id)::int AS n
       FROM task_attempts ta
       JOIN tasks t ON t.id = ta.task_id
       LEFT JOIN verification_tasks vt ON vt.task_id = t.id
      WHERE ta.user_id = $1 AND t.track_id = $2 AND ta.passed = TRUE AND ta.practice = FALSE
      GROUP BY t.feature, vt.difficulty`,
    [userId, trackId],
  );

  const capstone = executor.query(
    // Best-ever score across the track's capstones, passed attempts only, so a
    // failed attempt alone can never complete the milestone.
    `SELECT MAX(a.score)::int AS best
       FROM lab_capstone_attempts a
       JOIN lab_capstone_assessments c ON c.id = a.assessment_id
      WHERE a.user_id = $1 AND c.track_id = $2 AND a.passed = TRUE AND a.score IS NOT NULL`,
    [userId, trackId],
  );

  const cases = executor.query(
    // industry_case_reads has one row per (user, case): COUNT(*) cannot
    // double-count. Deactivated cases still count; progress is never taken back.
    `SELECT COUNT(*)::int AS n
       FROM industry_case_reads r
       JOIN industry_cases c ON c.id = r.case_id
      WHERE r.user_id = $1 AND c.track_id = $2`,
    [userId, trackId],
  );

  const activities = executor.query(
    // Practice lessons are track-scoped; the AI-literacy lessons are global
    // (track_id NULL), so both count.
    `SELECT COUNT(DISTINCT aa.activity_id)::int AS n
       FROM lab_activity_attempts aa
       JOIN lab_activities a ON a.id = aa.activity_id
       JOIN lab_lessons l ON l.id = a.lesson_id
      WHERE aa.user_id = $1 AND aa.passed = TRUE AND (l.track_id = $2 OR l.track_id IS NULL)`,
    [userId, trackId],
  );

  const readiness = features.trackProgress
    ? executor.query(
      `SELECT readiness_score, readiness_best, tier
         FROM user_track_progress
        WHERE user_id = $1 AND track_id = $2`,
      [userId, trackId],
    )
    : executor.query(
      // Fallback: user_progress mirrors the active track only.
      `SELECT readiness_score, tier FROM user_progress WHERE user_id = $1`,
      [userId],
    );

  const tutorials = features.tutorials
    ? executor.query(
      `SELECT tour_key FROM user_tutorials
        WHERE user_id = $1 AND track_id = $2 AND status = 'completed'`,
      [userId, trackId],
    )
    : Promise.resolve({ rows: [] });

  const [t, c, k, a, r, tu] = await Promise.all([tasks, capstone, cases, activities, readiness, tutorials]);

  let readinessScore = 0;
  let readinessBest = 0;
  let tier = null;
  const row = r.rows[0];
  if (row && (features.trackProgress || Number(trackId) === Number(activeTrackId))) {
    readinessScore = Number(row.readiness_score) || 0;
    // Without the high-water mark the live value is the best evidence available.
    readinessBest = features.trackProgress ? Number(row.readiness_best) || 0 : readinessScore;
    tier = row.tier || null;
  }
  readinessBest = Math.max(readinessBest, readinessScore);

  return {
    tasks: t.rows.map((x) => ({ feature: x.feature, difficulty: x.difficulty || null, n: Number(x.n) || 0 })),
    capstoneBest: Number(c.rows[0]?.best) || 0,
    casesRead: Number(k.rows[0]?.n) || 0,
    activitiesPassed: Number(a.rows[0]?.n) || 0,
    tutorials: tu.rows.map((x) => x.tour_key),
    readinessBest,
    readiness: { score: readinessScore, tier: tier || tierForScore(readinessScore) },
  };
}

// ---------------------------------------------------------------------------
// Evaluation
// ---------------------------------------------------------------------------
function measure(milestone, evidence) {
  const filter = milestone.filter || {};
  switch (milestone.type) {
    case 'tutorial_completed': {
      const done = filter.tour_key
        ? evidence.tutorials.includes(filter.tour_key)
        : evidence.tutorials.length > 0;
      return done ? 1 : 0;
    }
    case 'tasks_passed': {
      const difficulties = Array.isArray(filter.difficulty) ? filter.difficulty : null;
      return evidence.tasks
        .filter((row) => (!filter.feature || row.feature === filter.feature)
          && (!difficulties || (row.difficulty && difficulties.includes(row.difficulty))))
        .reduce((sum, row) => sum + row.n, 0);
    }
    case 'capstone_score':
      return evidence.capstoneBest;
    case 'industry_cases_read':
      return evidence.casesRead;
    case 'activities_passed':
      return evidence.activitiesPassed;
    case 'readiness_score':
      return evidence.readinessBest;
    default:
      return 0;
  }
}

function buildRoadmap({ track, stages, evidence }) {
  // 1. Evidence per milestone.
  const evaluated = stages.map((stage) => ({
    stage,
    milestones: stage.milestones.map((m) => {
      const raw = measure(m, evidence);
      const complete = raw >= m.target;
      const current = SCORE_TYPES.has(m.type) ? raw : Math.min(raw, m.target);
      return { m, current, complete };
    }),
  }));

  // 2. Gating. A stage is complete when every milestone is complete AND every
  //    earlier stage is complete; the first incomplete stage is active; every
  //    later stage is locked. (A stage whose milestones are already satisfied
  //    out of order stays locked until the stages before it are done, but its
  //    earned milestones are still shown, and counted, as complete.)
  let previousComplete = true;
  let activeIndex = -1;
  const stageStatuses = evaluated.map((e, index) => {
    const own = e.milestones.length > 0 && e.milestones.every((x) => x.complete);
    let status;
    if (own && previousComplete) {
      status = 'complete';
    } else if (previousComplete) {
      status = 'active';
      if (activeIndex === -1) activeIndex = index;
    } else {
      status = 'locked';
    }
    previousComplete = previousComplete && own;
    return status;
  });

  // 3. Shape.
  let nextAction = null;
  const outStages = evaluated.map((e, index) => {
    const status = stageStatuses[index];
    let currentAssigned = false;
    const milestones = e.milestones.map(({ m, current, complete }) => {
      let mStatus;
      if (complete) mStatus = 'complete';
      else if (status === 'locked') mStatus = 'locked';
      else if (!currentAssigned) { mStatus = 'current'; currentAssigned = true; } else mStatus = 'up_next';

      const label = complete && m.action_label_done ? m.action_label_done : (m.action_label || m.title);
      const action = m.action_route || m.action_label ? { label, route: m.action_route || null } : null;

      if (mStatus === 'current' && status === 'active' && !nextAction) {
        nextAction = { stage: e.stage.code, milestone: m.code, label, route: m.action_route || null };
      }

      return {
        code: m.code,
        title: m.title,
        description: m.description,
        status: mStatus,
        current,
        target: m.target,
        unit: UNIT_BY_TYPE[m.type] || 'item',
        action,
      };
    });
    return {
      code: e.stage.code,
      title: e.stage.title,
      outcome: e.stage.outcome,
      order: index + 1,
      status,
      milestones,
    };
  });

  const total = outStages.reduce((n, s) => n + s.milestones.length, 0);
  const done = outStages.reduce((n, s) => n + s.milestones.filter((x) => x.status === 'complete').length, 0);
  const stagesCompleted = outStages.filter((s) => s.status === 'complete').length;
  const currentStage = activeIndex >= 0 ? activeIndex + 1 : outStages.length;

  // The credential belongs to the last stage that defines one. It is a display
  // state only; issuing a shareable passport is out of scope.
  let credential = null;
  for (let i = stages.length - 1; i >= 0; i -= 1) {
    if (stages[i].credential_title) {
      credential = {
        title: stages[i].credential_title,
        description: stages[i].credential_description || null,
        unlocked: stageStatuses[i] === 'complete',
      };
      break;
    }
  }

  return {
    track,
    summary: {
      current_stage: currentStage,
      stages_completed: stagesCompleted,
      milestones_completed: done,
      milestones_total: total,
      percent: total > 0 ? Math.round((100 * done) / total) : 0,
      readiness_score: evidence.readiness.score,
      tier: evidence.readiness.tier,
    },
    stages: outStages,
    next_action: nextAction,
    credential,
  };
}

// Entry point used by the controller. Returns null when the track is unknown.
async function getRoadmap({ userId, trackId, activeTrackId }, executor = pool) {
  const definition = await loadDefinition(trackId, executor);
  if (!definition) return null;
  const evidence = await loadEvidence({ userId, trackId, activeTrackId }, executor);
  return buildRoadmap({ track: definition.track, stages: definition.stages, evidence });
}

module.exports = {
  REQUIREMENT_TYPES,
  UNIT_BY_TYPE,
  loadDefinition,
  loadEvidence,
  measure,
  buildRoadmap,
  getRoadmap,
  resetSchemaDetection,
};
