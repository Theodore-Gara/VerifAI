const assert = require('node:assert/strict');
const { test } = require('node:test');
const { switchIndustry, tutorialState } = require('../services/industrySwitch');

const TRACKS = {
  1: { id: 1, name: 'Finance', description: 'Money', icon_key: 'finance', perk: 'Numerical Auditing' },
  2: { id: 2, name: 'Legal', description: 'Law', icon_key: 'legal', perk: 'Clause Citation' },
};

function fakeClient({ currentTrack = 1, tutorial = null } = {}) {
  const state = { currentTrack, audits: [], updates: [], readinessWrites: [], tutorial };
  const client = {
    state,
    async query(sql, values = []) {
      const s = sql.replace(/\s+/g, ' ').trim();
      if (s.includes('FOR UPDATE OF u')) {
        return { rows: [{ id: 7, industry_track_id: state.currentTrack, industry_track_name: TRACKS[state.currentTrack]?.name || null }] };
      }
      if (s.includes('FROM industry_tracks WHERE id = $1')) {
        return { rows: TRACKS[values[0]] ? [TRACKS[values[0]]] : [] };
      }
      if (s.startsWith('UPDATE users')) {
        state.updates.push(values);
        state.currentTrack = values[1];
        return { rows: [] };
      }
      if (s.startsWith('INSERT INTO user_track_changes')) {
        state.audits.push(values);
        return { rows: [] };
      }
      if (s.includes('readiness_inputs')) {
        return {
          rows: [{
            scores: [{ dimension: 'Verification', score: 100 }],
            available: [{ feature: 'verification' }],
            capstone_offered: 0,
            capstone_average: 0,
            interview_practised: 0,
            tasks_completed: 0,
            current_readiness: null,
            current_best: null,
            last_activity_date: null,
            active_track_id: state.currentTrack,
          }],
        };
      }
      if (s.includes('FROM interview_questions')) return { rows: [{ total: 0 }] };
      if (s.includes('INSERT INTO user_track_progress')) {
        state.readinessWrites.push(values);
        return { rows: [] };
      }
      if (s.includes('FROM user_track_progress')) return { rows: [{ readiness_score: 100, tier: 'Advanced' }] };
      if (s.includes('FROM skill_scores')) return { rows: [{ dimension: 'Verification', score: 100, attempts_count: 1 }] };
      if (s.includes('FROM user_progress')) {
        return { rows: [{ xp: 420, level: 4, streak: 6, tokens: 25 }] };
      }
      if (s.includes('FROM user_tutorials')) {
        return { rows: state.tutorial ? [state.tutorial] : [] };
      }
      return { rows: [] };
    },
  };
  return client;
}

test('switching to the current track is a 409 and writes nothing', async () => {
  const client = fakeClient({ currentTrack: 1 });
  await assert.rejects(
    () => switchIndustry(client, 7, 1),
    (err) => err.status === 409 && err.apiCode === 'same_track',
  );
  assert.equal(client.state.updates.length, 0);
  assert.equal(client.state.audits.length, 0);
});

test('an unknown track is rejected before anything is written', async () => {
  const client = fakeClient({ currentTrack: 1 });
  await assert.rejects(
    () => switchIndustry(client, 7, 9),
    (err) => err.status === 400 && err.apiCode === 'unknown_track',
  );
  assert.equal(client.state.updates.length, 0);
  assert.equal(client.state.audits.length, 0);
});

test('a successful switch writes exactly one audit row and recomputes readiness', async () => {
  const client = fakeClient({ currentTrack: 1 });
  const result = await switchIndustry(client, 7, 2, { displayName: 'Theo' });

  assert.equal(client.state.updates.length, 1);
  assert.deepEqual(client.state.audits, [[7, 1, 2]], 'from Finance to Legal, once');
  assert.equal(client.state.readinessWrites.length, 1, 'readiness recomputed for the new track');

  assert.deepEqual(result.user, { id: 7, industry_track_id: 2, industry_track_name: 'Legal' });
  assert.deepEqual(result.track, {
    id: 2,
    name: 'Legal',
    description: 'Law',
    icon_key: 'legal',
    perk: 'Clause Citation',
  });
  assert.equal(result.progress.readiness_score, 100);
  assert.equal(result.progress.tier, 'Advanced');
  assert.deepEqual(result.kept, ['xp', 'level', 'streak', 'tokens']);
  assert.deepEqual(result.kept_values, { xp: 420, level: 4, streak: 6, tokens: 25 });
  assert.equal(result.tour.should_offer, true, 'a new track offers the tour');
  assert.equal(result.tour.status, null);
});

test('a double switch is rejected on the second call (row is locked and reread)', async () => {
  const client = fakeClient({ currentTrack: 1 });
  await switchIndustry(client, 7, 2);
  await assert.rejects(
    () => switchIndustry(client, 7, 2),
    (err) => err.status === 409 && err.apiCode === 'same_track',
  );
  assert.equal(client.state.audits.length, 1);
});

test('a skipped tour is only re-offered when explicitly asked', async () => {
  const client = fakeClient({ tutorial: { status: 'skipped', updated_at: 'yesterday' } });
  const no = await tutorialState(client, 7, 1, { reoffer: false });
  assert.equal(no.should_offer, false);
  const yes = await tutorialState(client, 7, 1, { reoffer: true });
  assert.equal(yes.should_offer, true);
});
