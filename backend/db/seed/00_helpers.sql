-- Seed helper functions.
-- Each feature seed file calls these so content stays declarative and idempotent.
-- Idempotency: the anchor `tasks` is upserted by its stable `code`; the content
-- row is upserted by `task_id`; options are replaced wholesale.

-- Verification task + 'answer' options.
CREATE OR REPLACE FUNCTION seed_verification(
  p_code TEXT,
  p_track TEXT,
  p_title TEXT,
  p_scenario TEXT,
  p_flaw TEXT,
  p_answer TEXT,
  p_feedback TEXT,
  p_difficulty TEXT,
  p_options JSONB
) RETURNS void AS $$
DECLARE
  v_task_id INTEGER;
  v_opt JSONB;
  v_i INTEGER := 0;
BEGIN
  INSERT INTO tasks (code, feature, track_id)
  VALUES (p_code, 'verification', (SELECT id FROM industry_tracks WHERE name = p_track))
  ON CONFLICT (code) DO UPDATE SET feature = EXCLUDED.feature, track_id = EXCLUDED.track_id
  RETURNING id INTO v_task_id;

  INSERT INTO verification_tasks (task_id, format, title, scenario, embedded_flaw, expected_answer, feedback, difficulty)
  VALUES (v_task_id, 'choice', p_title, p_scenario, p_flaw, p_answer, p_feedback, p_difficulty)
  ON CONFLICT (task_id) DO UPDATE SET
    format = EXCLUDED.format,
    title = EXCLUDED.title,
    scenario = EXCLUDED.scenario,
    embedded_flaw = EXCLUDED.embedded_flaw,
    expected_answer = EXCLUDED.expected_answer,
    feedback = EXCLUDED.feedback,
    difficulty = EXCLUDED.difficulty;

  DELETE FROM task_options WHERE task_id = v_task_id;
  FOR v_opt IN SELECT value FROM jsonb_array_elements(p_options) LOOP
    INSERT INTO task_options (task_id, kind, label, score, sort_order)
    VALUES (v_task_id, 'answer', v_opt->>'label', (v_opt->>'score')::int, v_i);
    v_i := v_i + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Verification task in the 'line_text' format: numbered AI output, the flawed
-- line(s), a typed fix and a typed reason, each checked against keyword criteria.
CREATE OR REPLACE FUNCTION seed_verification_text(
  p_code TEXT,
  p_track TEXT,
  p_title TEXT,
  p_scenario TEXT,
  p_difficulty TEXT,
  p_lines TEXT[],
  p_flaw_lines INTEGER[],
  p_flaw TEXT,
  p_answer TEXT,
  p_feedback TEXT,
  p_fix_keywords TEXT[],
  p_reason_keywords TEXT[]
) RETURNS void AS $$
DECLARE
  v_task_id INTEGER;
BEGIN
  INSERT INTO tasks (code, feature, track_id)
  VALUES (p_code, 'verification', (SELECT id FROM industry_tracks WHERE name = p_track))
  ON CONFLICT (code) DO UPDATE SET feature = EXCLUDED.feature, track_id = EXCLUDED.track_id
  RETURNING id INTO v_task_id;

  INSERT INTO verification_tasks
    (task_id, format, title, scenario, embedded_flaw, expected_answer, feedback, difficulty,
     ai_output_lines, flaw_lines, fix_keywords, reason_keywords)
  VALUES
    (v_task_id, 'line_text', p_title, p_scenario, p_flaw, p_answer, p_feedback, p_difficulty,
     p_lines, p_flaw_lines, p_fix_keywords, p_reason_keywords)
  ON CONFLICT (task_id) DO UPDATE SET
    format = EXCLUDED.format,
    title = EXCLUDED.title,
    scenario = EXCLUDED.scenario,
    embedded_flaw = EXCLUDED.embedded_flaw,
    expected_answer = EXCLUDED.expected_answer,
    feedback = EXCLUDED.feedback,
    difficulty = EXCLUDED.difficulty,
    ai_output_lines = EXCLUDED.ai_output_lines,
    flaw_lines = EXCLUDED.flaw_lines,
    fix_keywords = EXCLUDED.fix_keywords,
    reason_keywords = EXCLUDED.reason_keywords;
END;
$$ LANGUAGE plpgsql;

-- AI Judgement / Risk & Governance task + 'decision'/'reason' options.
CREATE OR REPLACE FUNCTION seed_choice_task(
  p_feature TEXT,
  p_code TEXT,
  p_track TEXT,
  p_title TEXT,
  p_scenario TEXT,
  p_feedback TEXT,
  p_options JSONB
) RETURNS void AS $$
DECLARE
  v_task_id INTEGER;
  v_opt JSONB;
  v_i INTEGER := 0;
BEGIN
  INSERT INTO tasks (code, feature, track_id)
  VALUES (p_code, p_feature, (SELECT id FROM industry_tracks WHERE name = p_track))
  ON CONFLICT (code) DO UPDATE SET feature = EXCLUDED.feature, track_id = EXCLUDED.track_id
  RETURNING id INTO v_task_id;

  IF p_feature = 'judgement' THEN
    INSERT INTO judgement_tasks (task_id, title, scenario, feedback)
    VALUES (v_task_id, p_title, p_scenario, p_feedback)
    ON CONFLICT (task_id) DO UPDATE SET
      title = EXCLUDED.title, scenario = EXCLUDED.scenario, feedback = EXCLUDED.feedback;
  ELSIF p_feature = 'risk_governance' THEN
    INSERT INTO risk_governance_tasks (task_id, title, scenario, feedback)
    VALUES (v_task_id, p_title, p_scenario, p_feedback)
    ON CONFLICT (task_id) DO UPDATE SET
      title = EXCLUDED.title, scenario = EXCLUDED.scenario, feedback = EXCLUDED.feedback;
  ELSE
    RAISE EXCEPTION 'seed_choice_task: unsupported feature %', p_feature;
  END IF;

  DELETE FROM task_options WHERE task_id = v_task_id;
  FOR v_opt IN SELECT value FROM jsonb_array_elements(p_options) LOOP
    INSERT INTO task_options (task_id, kind, label, score, sort_order)
    VALUES (v_task_id, v_opt->>'kind', v_opt->>'label', (v_opt->>'score')::int, v_i);
    v_i := v_i + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Interview Practice question (ungraded).
CREATE OR REPLACE FUNCTION seed_interview(
  p_track TEXT,
  p_question TEXT,
  p_sample TEXT,
  p_employers TEXT,
  p_order INTEGER
) RETURNS void AS $$
DECLARE
  v_track INTEGER;
  v_id INTEGER;
BEGIN
  SELECT id INTO v_track FROM industry_tracks WHERE name = p_track;
  SELECT id INTO v_id FROM interview_questions WHERE track_id = v_track AND question = p_question;
  IF v_id IS NULL THEN
    INSERT INTO interview_questions (track_id, question, sample_answer, what_employers_test, sort_order)
    VALUES (v_track, p_question, p_sample, p_employers, p_order);
  ELSE
    UPDATE interview_questions
    SET sample_answer = p_sample, what_employers_test = p_employers, sort_order = p_order
    WHERE id = v_id;
  END IF;
END;
$$ LANGUAGE plpgsql;
