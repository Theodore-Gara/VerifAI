-- 73_roadmap_helpers.sql — shared helper for the roadmap seeds (74-77).
--
-- seed_roadmap(track_name, stages) takes the track's five stages as JSONB and
-- upserts them by (track_id, code) and (stage_id, code). The file is
-- authoritative for its track: stages and milestones that are no longer listed
-- are removed. That is safe because roadmap status is derived from learner
-- evidence and no per-user roadmap rows exist.
--
-- stages: [{ code, title, outcome, description?, credential_title?,
--            credential_description?,
--            milestones: [{ code, title, description, type, target, filter?,
--                           action_label?, action_label_done?, route? }] }]
-- Stage and milestone order is the array order.

CREATE OR REPLACE FUNCTION seed_roadmap(p_track TEXT, p_stages JSONB) RETURNS void AS $$
DECLARE
  v_track_id INTEGER;
  v_stage JSONB;
  v_ms JSONB;
  v_stage_id INTEGER;
  v_i INTEGER := 0;
  v_j INTEGER;
  v_stage_codes TEXT[] := ARRAY[]::TEXT[];
  v_ms_codes TEXT[];
BEGIN
  SELECT id INTO v_track_id FROM industry_tracks WHERE name = p_track;
  IF v_track_id IS NULL THEN
    RAISE EXCEPTION 'seed_roadmap: unknown track %', p_track;
  END IF;

  FOR v_stage IN SELECT value FROM jsonb_array_elements(p_stages) LOOP
    v_i := v_i + 1;

    INSERT INTO roadmap_stages
      (track_id, code, title, outcome, description, sort_order, credential_title, credential_description)
    VALUES
      (v_track_id, v_stage->>'code', v_stage->>'title', v_stage->>'outcome',
       v_stage->>'description', v_i, v_stage->>'credential_title', v_stage->>'credential_description')
    ON CONFLICT (track_id, code) DO UPDATE SET
      title = EXCLUDED.title, outcome = EXCLUDED.outcome, description = EXCLUDED.description,
      sort_order = EXCLUDED.sort_order, credential_title = EXCLUDED.credential_title,
      credential_description = EXCLUDED.credential_description
    RETURNING id INTO v_stage_id;

    v_stage_codes := v_stage_codes || (v_stage->>'code');
    v_ms_codes := ARRAY[]::TEXT[];
    v_j := 0;

    FOR v_ms IN SELECT value FROM jsonb_array_elements(v_stage->'milestones') LOOP
      v_j := v_j + 1;

      INSERT INTO roadmap_milestones
        (stage_id, code, title, description, requirement_type, requirement_target,
         requirement_filter, action_label, action_label_done, action_route, sort_order)
      VALUES
        (v_stage_id, v_ms->>'code', v_ms->>'title', v_ms->>'description', v_ms->>'type',
         (v_ms->>'target')::INTEGER, v_ms->'filter', v_ms->>'action_label',
         v_ms->>'action_label_done', v_ms->>'route', v_j)
      ON CONFLICT (stage_id, code) DO UPDATE SET
        title = EXCLUDED.title, description = EXCLUDED.description,
        requirement_type = EXCLUDED.requirement_type, requirement_target = EXCLUDED.requirement_target,
        requirement_filter = EXCLUDED.requirement_filter, action_label = EXCLUDED.action_label,
        action_label_done = EXCLUDED.action_label_done, action_route = EXCLUDED.action_route,
        sort_order = EXCLUDED.sort_order;

      v_ms_codes := v_ms_codes || (v_ms->>'code');
    END LOOP;

    DELETE FROM roadmap_milestones WHERE stage_id = v_stage_id AND NOT (code = ANY(v_ms_codes));
  END LOOP;

  DELETE FROM roadmap_stages WHERE track_id = v_track_id AND NOT (code = ANY(v_stage_codes));
END;
$$ LANGUAGE plpgsql;
