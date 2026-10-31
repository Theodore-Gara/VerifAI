const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { test, beforeEach } = require('node:test');

const { contentCache } = require('../utils/ttlCache');
const {
  buildRoadmap, getRoadmap, measure, resetSchemaDetection, REQUIREMENT_TYPES,
} = require('../services/roadmapService');

const SEED_DIR = path.join(__dirname, '..', 'db', 'seed');
const TRACK_FILES = {
  Finance: '74_finance_roadmap.sql',
  Legal: '75_legal_roadmap.sql',
  'IT / Software': '76_it_roadmap.sql',
  'Business Consulting': '77_business_consulting_roadmap.sql',
};

function seededStages(track) {
  const sql = fs.readFileSync(path.join(SEED_DIR, TRACK_FILES[track]), 'utf8');
  const match = /\$j\$([\s\S]*?)\$j\$/.exec(sql);
  assert.ok(match, `${track}: JSON payload found`);
  return JSON.parse(match[1]);
}

// Same shape loadDefinition() produces from the database rows.
function definitionFor(track) {
  return seededStages(track).map((s) => ({
    code: s.code, title: s.title, outcome: s.outcome, description: s.description,
    credential_title: s.credential_title || null, credential_description: s.credential_description || null,
    milestones: s.milestones.map((m) => ({
      code: m.code, title: m.title, description: m.description, type: m.type, target: m.target,
      filter: m.filter || {}, action_label: m.action_label || null,
      action_label_done: m.action_label_done || null, action_route: m.route || null,
    })),
  }));
}

const EMPTY = {
  tasks: [], capstoneBest: 0, casesRead: 0, activitiesPassed: 0, tutorials: [],
  readinessBest: 0, readiness: { score: 0, tier: 'Novice' },
};
const withEvidence = (extra) => ({ ...EMPTY, ...extra, readiness: { ...EMPTY.readiness, ...(extra.readiness || {}) } });
const build = (evidence, track = 'Finance') => buildRoadmap({
  track: { id: 1, name: track }, stages: definitionFor(track), evidence,
});

// ---------------------------------------------------------------------------
// Seed content
// ---------------------------------------------------------------------------
test('every track seeds five stages and ten milestones with identical codes, types and targets', () => {
  const shape = (track) => seededStages(track).map((s) => ({
    code: s.code,
    milestones: s.milestones.map((m) => [m.code, m.type, m.target, JSON.stringify(m.filter || null)]),
  }));
  const reference = shape('Finance');
  assert.equal(reference.length, 5);
  assert.equal(reference.reduce((n, s) => n + s.milestones.length, 0), 10);
  for (const track of Object.keys(TRACK_FILES)) {
    assert.deepEqual(shape(track), reference, `${track} matches the shared structure`);
  }
});

test('seeded milestones use valid requirement types and one-sentence copy without XP wording', () => {
  for (const track of Object.keys(TRACK_FILES)) {
    for (const stage of seededStages(track)) {
      for (const m of stage.milestones) {
        assert.ok(REQUIREMENT_TYPES.includes(m.type), `${track}/${m.code} type`);
        assert.ok(Number.isInteger(m.target) && m.target > 0);
        assert.ok(m.title.length <= 160 && m.description.length > 0);
        const copy = `${m.title} ${m.description}`;
        assert.doesNotMatch(copy, /\b(xp|streak|badge|token|certificate|job)\b/i, `${track}/${m.code}`);
        assert.doesNotMatch(m.description.replace(/\.$/, ''), /\. /, `${track}/${m.code} is one sentence`);
      }
    }
  }
});

test('every seeded milestone is reachable with the content that is actually seeded', () => {
  const read = (f) => fs.readFileSync(path.join(SEED_DIR, f), 'utf8');
  const verification = { Finance: '10_verification_finance.sql', Legal: '11_verification_legal.sql', 'IT / Software': '12_verification_it.sql', 'Business Consulting': '13_verification_business_consulting.sql' };
  const judgement = { Finance: '20_judgement_finance.sql', Legal: '21_judgement_legal.sql', 'IT / Software': '22_judgement_it.sql', 'Business Consulting': '23_judgement_business_consulting.sql' };
  const risk = { Finance: '30_risk_governance_finance.sql', Legal: '31_risk_governance_legal.sql', 'IT / Software': '32_risk_governance_it.sql', 'Business Consulting': '33_risk_governance_business_consulting.sql' };
  const cases = read('56_industry_cases.sql');
  const capstones = read('55_lab_capstone_assessments.sql');

  for (const track of Object.keys(TRACK_FILES)) {
    const targets = Object.fromEntries(seededStages(track).flatMap((s) => s.milestones).map((m) => [m.code, m.target]));
    const v = read(verification[track]);
    assert.ok((v.match(/seed_verification(_text)?\(/g) || []).length >= targets['verify-three'], `${track} verification tasks`);
    assert.match(v, /'(medium|hard)'/, `${track} has a medium or hard verification task`);
    assert.ok((read(judgement[track]).match(/seed_choice_task\(/g) || []).length >= targets['judge-two'], `${track} judgement`);
    assert.ok((read(risk[track]).match(/seed_choice_task\(/g) || []).length >= targets['govern-two'], `${track} risk`);
    const caseCount = (cases.match(new RegExp(`^  \\('${track.replace('/', '\\/')}'`, 'mg')) || []).length;
    assert.ok(caseCount >= targets['cases-three'], `${track} has ${caseCount} cases`);
    assert.match(capstones, new RegExp(`name = '${track}'`), `${track} has a capstone`);
  }
  // Recall activities: track-scoped books plus the global AI-literacy set.
  const activityRows = (read('65_lab_practice_activities.sql').match(/^  \('(multiple_choice|true_false|fill_blank|matching|ordering)'/mg) || []).length;
  assert.ok(activityRows >= 5 * 4);
});

// ---------------------------------------------------------------------------
// Gating, counters and the next action
// ---------------------------------------------------------------------------
test('a new learner sees Stage 1 active, 0/10 milestones and "Take the tour" next', () => {
  const r = build(EMPTY);
  assert.equal(r.summary.current_stage, 1);
  assert.equal(r.summary.milestones_completed, 0);
  assert.equal(r.summary.milestones_total, 10);
  assert.equal(r.summary.percent, 0);
  assert.deepEqual(r.stages.map((s) => s.status), ['active', 'locked', 'locked', 'locked', 'locked']);
  assert.deepEqual(r.stages[0].milestones.map((m) => m.status), ['current', 'up_next']);
  assert.ok(r.stages[1].milestones.every((m) => m.status === 'locked'));
  assert.deepEqual(r.next_action, { stage: 'orient', milestone: 'tour', label: 'Take the tour', route: '/welcome-tour' });
  assert.equal(r.credential.unlocked, false);
  assert.equal(r.credential.title, 'AI Readiness Passport');
});

test('completing Stage 1 unlocks Stage 2 and moves the next action to a verification task', () => {
  const r = build(withEvidence({ tutorials: ['industry'], tasks: [{ feature: 'verification', difficulty: 'easy', n: 1 }] }));
  assert.deepEqual(r.stages.map((s) => s.status), ['complete', 'active', 'locked', 'locked', 'locked']);
  assert.equal(r.summary.current_stage, 2);
  assert.equal(r.summary.stages_completed, 1);
  assert.equal(r.next_action.milestone, 'verify-three');
  assert.equal(r.next_action.route, '/verification');
  const tour = r.stages[0].milestones[0];
  assert.equal(tour.status, 'complete');
  assert.equal(tour.action.label, 'Replay tour');
});

test('a locked stage cannot become active out of order, but earned milestones still show as complete', () => {
  // Capstone passed and cases read before Stage 1 is finished (returning learner).
  const r = build(withEvidence({ capstoneBest: 80, casesRead: 3 }));
  assert.equal(r.stages[3].status, 'locked');
  assert.deepEqual(r.stages[3].milestones.map((m) => m.status), ['complete', 'complete']);
  assert.equal(r.summary.milestones_completed, 2);
  assert.equal(r.stages[0].status, 'active');
  assert.equal(r.next_action.stage, 'orient');
  assert.equal(r.summary.stages_completed, 0);
});

test('counters are capped at the target and count only the matching feature and difficulty', () => {
  const evidence = withEvidence({
    tasks: [
      { feature: 'verification', difficulty: 'easy', n: 5 },
      { feature: 'verification', difficulty: 'hard', n: 1 },
      { feature: 'judgement', difficulty: null, n: 1 },
    ],
  });
  const find = (code) => build(evidence).stages.flatMap((s) => s.milestones).find((m) => m.code === code);
  assert.equal(find('verify-three').current, 3);
  assert.equal(find('verify-three').status, 'complete');
  assert.equal(find('verify-hard').current, 1);
  assert.equal(find('judge-two').current, 1);
  assert.equal(find('judge-two').status === 'complete', false);
  // A difficulty filter never matches a task without a difficulty.
  assert.equal(measure({ type: 'tasks_passed', target: 1, filter: { feature: 'judgement', difficulty: ['medium', 'hard'] } }, evidence), 0);
});

test('readiness uses the best-ever value so a later drop never un-reaches the milestone', () => {
  const r = build(withEvidence({ readinessBest: 74, readiness: { score: 64, tier: 'Developing' } }));
  const m = r.stages[4].milestones.find((x) => x.code === 'readiness-70');
  assert.equal(m.status, 'complete');
  assert.equal(m.current, 74);
  assert.equal(r.summary.readiness_score, 64);
  assert.equal(r.summary.tier, 'Developing');
});

test('finishing everything completes all stages, unlocks the credential and clears the next action', () => {
  const all = withEvidence({
    tutorials: ['industry'],
    tasks: [
      { feature: 'verification', difficulty: 'medium', n: 3 }, { feature: 'judgement', difficulty: null, n: 2 },
      { feature: 'risk_governance', difficulty: null, n: 2 },
    ],
    casesRead: 3, capstoneBest: 71, readinessBest: 72, activitiesPassed: 5,
    readiness: { score: 72, tier: 'Proficient' },
  });
  const r = build(all);
  assert.ok(r.stages.every((s) => s.status === 'complete'));
  assert.equal(r.summary.percent, 100);
  assert.equal(r.summary.current_stage, 5);
  assert.equal(r.next_action, null);
  assert.equal(r.credential.unlocked, true);
});

test('a failed capstone alone never completes the milestone (evidence is passed attempts only)', () => {
  // The service query filters passed = TRUE; with no passed attempt the best is 0.
  assert.equal(measure({ type: 'capstone_score', target: 70, filter: {} }, EMPTY), 0);
  assert.equal(measure({ type: 'capstone_score', target: 70, filter: {} }, withEvidence({ capstoneBest: 69 })) >= 70, false);
});

test('empty states: a track with no stages yields an empty, valid roadmap', () => {
  const r = buildRoadmap({ track: { id: 9, name: 'Empty' }, stages: [], evidence: EMPTY });
  assert.deepEqual(r.stages, []);
  assert.equal(r.summary.milestones_total, 0);
  assert.equal(r.summary.percent, 0);
  assert.equal(r.next_action, null);
  assert.equal(r.credential, null);
});

test('the roadmap never reads XP, streaks or achievements', () => {
  const src = fs.readFileSync(path.join(__dirname, '..', 'services', 'roadmapService.js'), 'utf8');
  const code = src.split('\n').filter((l) => !l.trim().startsWith('//')).join('\n');
  assert.doesNotMatch(code, /user_achievements|achievements|\bxp\b|streak|tokens/i);
});

// ---------------------------------------------------------------------------
// Queries: fixed count, evidence from real rows, track isolation
// ---------------------------------------------------------------------------
function fakeExecutor({ tracks, evidenceByTrack = {}, legacyProgress = null, schema = { track_progress: false, tutorials: false } }) {
  const calls = [];
  return {
    calls,
    async query(sql, values = []) {
      const s = sql.replace(/\s+/g, ' ').trim();
      calls.push({ s, values });
      if (s.includes('FROM industry_tracks t LEFT JOIN roadmap_stages')) {
        const t = tracks[values[0]];
        if (!t) return { rows: [] };
        return { rows: t.rows };
      }
      if (s.includes("to_regclass('public.user_track_progress')")) return { rows: [schema] };
      const ev = evidenceByTrack[values[1]] || {};
      if (s.includes('FROM task_attempts ta')) return { rows: ev.tasks || [] };
      if (s.includes('FROM lab_capstone_attempts')) return { rows: [{ best: ev.capstone ?? null }] };
      if (s.includes('FROM industry_case_reads')) return { rows: [{ n: ev.cases || 0 }] };
      if (s.includes('FROM lab_activity_attempts')) return { rows: [{ n: ev.activities || 0 }] };
      if (s.includes('FROM user_track_progress')) return { rows: ev.progress ? [ev.progress] : [] };
      if (s.includes('FROM user_progress')) return { rows: legacyProgress ? [legacyProgress] : [] };
      if (s.includes('FROM user_tutorials')) return { rows: ev.tutorials || [] };
      throw new Error(`unexpected query: ${s}`);
    },
  };
}

function definitionRows(trackId, name, track) {
  const rows = [];
  let stageId = trackId * 100;
  for (const s of seededStages(track)) {
    stageId += 1;
    for (const m of s.milestones) {
      rows.push({
        track_id: trackId, track_name: name, stage_id: stageId, stage_code: s.code, stage_title: s.title,
        outcome: s.outcome, stage_description: s.description,
        credential_title: s.credential_title || null, credential_description: s.credential_description || null,
        milestone_code: m.code, milestone_title: m.title, milestone_description: m.description,
        requirement_type: m.type, requirement_target: m.target, requirement_filter: m.filter || null,
        action_label: m.action_label || null, action_label_done: m.action_label_done || null, action_route: m.route || null,
      });
    }
  }
  return { rows };
}

beforeEach(() => { contentCache.clear(); resetSchemaDetection(); });

test('getRoadmap issues a fixed number of queries regardless of milestone count (no N+1)', async () => {
  const exec = fakeExecutor({ tracks: { 1: definitionRows(1, 'Finance', 'Finance') } });
  const roadmap = await getRoadmap({ userId: 7, trackId: 1, activeTrackId: 1 }, exec);
  assert.equal(roadmap.summary.milestones_total, 10);
  // definition + schema check + tasks, capstone, cases, activities, readiness (+ tutorials skipped without the table)
  assert.ok(exec.calls.length <= 8, `${exec.calls.length} queries`);
  const before = exec.calls.length;
  await getRoadmap({ userId: 7, trackId: 1, activeTrackId: 1 }, exec);
  // Second read: the definition is cached, so only the evidence queries repeat.
  assert.ok(exec.calls.length - before <= 6);
});

test('evidence comes from rows and is scoped to the requested track', async () => {
  const exec = fakeExecutor({
    tracks: { 1: definitionRows(1, 'Finance', 'Finance'), 2: definitionRows(2, 'Legal', 'Legal') },
    evidenceByTrack: {
      1: { tasks: [{ feature: 'verification', difficulty: 'easy', n: 3 }], cases: 3 },
    },
    schema: { track_progress: true, tutorials: true },
  });
  const finance = await getRoadmap({ userId: 7, trackId: 1, activeTrackId: 1 }, exec);
  const legal = await getRoadmap({ userId: 7, trackId: 2, activeTrackId: 1 }, exec);
  assert.equal(finance.track.name, 'Finance');
  assert.equal(legal.track.name, 'Legal');
  assert.ok(finance.summary.milestones_completed >= 3);
  assert.equal(legal.summary.milestones_completed, 0, 'no Finance evidence carries over to Legal');
  assert.ok(legal.stages[0].milestones[0].title.includes('Legal'));
  for (const call of exec.calls.filter((c) => /FROM (task_attempts|industry_case_reads)/.test(c.s))) {
    assert.ok(call.values.length === 2 && [1, 2].includes(call.values[1]));
  }
});

test('without the track-progress table readiness falls back to the active track only', async () => {
  const exec = fakeExecutor({
    tracks: { 1: definitionRows(1, 'Finance', 'Finance'), 2: definitionRows(2, 'Legal', 'Legal') },
    legacyProgress: { readiness_score: 72, tier: 'Proficient' },
  });
  const active = await getRoadmap({ userId: 7, trackId: 1, activeTrackId: 1 }, exec);
  const other = await getRoadmap({ userId: 7, trackId: 2, activeTrackId: 1 }, exec);
  assert.equal(active.summary.readiness_score, 72);
  assert.equal(other.summary.readiness_score, 0);
});

test('an unknown track returns null', async () => {
  const exec = fakeExecutor({ tracks: {} });
  assert.equal(await getRoadmap({ userId: 7, trackId: 99, activeTrackId: 1 }, exec), null);
});
