-- 70_demo_activity.sql — demo activity for analytics verification.
--
-- Creates a coherent demo dataset: users across the four industry tracks
-- (departments), graded task attempts + answer_logs entries (the
-- per-department right/wrong tracking), user progress, workshop posts with
-- reports, and three pending draft tasks so the approval queue has content.
--
-- Idempotent: guarded by users-existence, so a populated database (real
-- signups) is left untouched and the file is safe to re-run.

DO $$
DECLARE
  v_user RECORD;
  v_task RECORD;
  v_num INT;
  v_score INT;
  v_passed BOOLEAN;
  v_opt_id INT;
  v_opt_label TEXT;
  v_attempt_id INT;
  v_date TIMESTAMP;
BEGIN
  IF (SELECT EXISTS (SELECT 1 FROM users)) THEN RETURN; END IF;

  -- -----------------------------------------------------------------------
  -- 1. Users: four demo accounts per department, signups spread over 12
  --    weeks (two weeks deliberately left empty so the 12-week signup chart
  --    shows gaps, not just bars).
  -- -----------------------------------------------------------------------
  INSERT INTO users (firebase_uid, email, display_name, industry_track_id, created_at)
  SELECT t.uid, t.email, t.name, t.track_id,
         CURRENT_TIMESTAMP - (t.weeks_ago * 7 + t.day_offset) * INTERVAL '1 day'
  FROM (VALUES
    ('fin-demo-1', 'fin.demo1@verifai.demo', 'Finn Fisher',    1, 11, 1),
    ('fin-demo-2', 'fin.demo2@verifai.demo', 'Freja Fisher',   1,  9, 4),
    ('fin-demo-3', 'fin.demo3@verifai.demo', 'Felix Fisher',   1,  6, 2),
    ('fin-demo-4', 'fin.demo4@verifai.demo', 'Frida Fisher',   1,  0, 3),
    ('leg-demo-1', 'leg.demo1@verifai.demo', 'Lars Legal',     2, 10, 2),
    ('leg-demo-2', 'leg.demo2@verifai.demo', 'Lisa Legal',     2,  8, 5),
    ('leg-demo-3', 'leg.demo3@verifai.demo', 'Lucas Legal',    2,  4, 1),
    ('leg-demo-4', 'leg.demo4@verifai.demo', 'Lotta Legal',    2,  0, 6),
    ('it-demo-1',  'it.demo1@verifai.demo',  'Ivan Iterator',  3,  9, 3),
    ('it-demo-2',  'it.demo2@verifai.demo',  'Iris Iterator',  3,  7, 1),
    ('it-demo-3',  'it.demo3@verifai.demo',  'Ivar Iterator',  3,  3, 4),
    ('it-demo-4',  'it.demo4@verifai.demo',  'Ida Iterator',   3,  0, 2),
    ('biz-demo-1', 'biz.demo1@verifai.demo', 'BoBiz Andersen', 4, 10, 5),
    ('biz-demo-2', 'biz.demo2@verifai.demo', 'Birte Andersen', 4,  6, 6),
    ('biz-demo-3', 'biz.demo3@verifai.demo', 'Bjorn Andersen', 4,  2, 2),
    ('biz-demo-4', 'biz.demo4@verifai.demo', 'Bente Andersen', 4,  0, 7)
  ) AS t(uid, email, name, track_id, weeks_ago, day_offset)
  ON CONFLICT (firebase_uid) DO NOTHING;

  -- -----------------------------------------------------------------------
  -- 2. Attempts + answer_logs: 3-6 graded attempts per user on their own
  --    department's live tasks, per-department pass rate (Finance 72%,
  --    Legal 65%, IT 70%, Business 60%), dates spread over ~40 days.
  -- -----------------------------------------------------------------------
  FOR v_user IN
    SELECT u.id, u.industry_track_id,
           CASE u.industry_track_id WHEN 1 THEN 72 WHEN 2 THEN 65 WHEN 3 THEN 70 ELSE 60 END AS pass_pct
    FROM users u WHERE u.email LIKE '%@verifai.demo'
  LOOP
    SELECT 3 + floor(random() * 4) INTO v_num;

    FOR v_task IN
      SELECT t.id, t.feature FROM tasks t
      WHERE t.track_id = v_user.industry_track_id AND t.published AND t.approval = 'approved'
      ORDER BY t.id LIMIT v_num
    LOOP
      IF floor(random() * 100) < v_user.pass_pct THEN
        v_score := 85 + floor(random() * 15); v_passed := TRUE;
      ELSE
        v_score := 10 + floor(random() * 55); v_passed := FALSE;
      END IF;

      -- Option pick: passes take the correct option, fails a wrong one.
      v_opt_id := NULL; v_opt_label := NULL;
      IF v_task.feature = 'verification' THEN
        SELECT o.id, o.label INTO v_opt_id, v_opt_label
        FROM task_options o WHERE o.task_id = v_task.id AND o.kind = 'answer'
        ORDER BY CASE WHEN v_passed THEN -o.score ELSE o.score END, o.sort_order
        LIMIT 1;
      ELSE
        SELECT o.id, o.label INTO v_opt_id, v_opt_label
        FROM task_options o WHERE o.task_id = v_task.id AND o.kind = 'decision'
        ORDER BY CASE WHEN v_passed THEN -o.score ELSE o.score END, o.sort_order
        LIMIT 1;
      END IF;
      IF v_opt_label IS NULL THEN
        v_opt_label := 'Fix: correct the flawed line and verify the claim.';
      END IF;

      v_date := CURRENT_TIMESTAMP - floor(random() * 40) * INTERVAL '1 day';
      INSERT INTO task_attempts
        (user_id, task_id, answer, rationale, answer_option_id, decision_option_id,
         reason_option_id, selected_lines, task_title, score, passed, practice, feedback, xp_earned,
         submitted_at)
      VALUES (v_user.id, v_task.id, v_opt_label, 'Demo rationale.', v_opt_id, NULL, NULL, NULL,
              'Demo task', v_score, v_passed, FALSE, 'Demo feedback.',
              CASE WHEN v_passed THEN 25 ELSE 0 END, v_date)
      RETURNING id INTO v_attempt_id;

      INSERT INTO answer_logs
        (attempt_id, user_id, task_id, department_id, feature, score, passed, practice, answer_summary,
         submitted_at)
      VALUES (v_attempt_id, v_user.id, v_task.id, v_user.industry_track_id, v_task.feature, v_score,
              v_passed, FALSE, v_opt_label, v_date);
    END LOOP;
  END LOOP;

  -- -----------------------------------------------------------------------
  -- 3. User progress rollup per demo user.
  -- -----------------------------------------------------------------------
  INSERT INTO user_progress (user_id, xp, level, streak, tokens, last_activity_date, readiness_score)
  SELECT a.user_id, SUM(a.xp_earned), 1 + (SUM(a.xp_earned) / 100),
             1 + floor(random() * 6), 0, MAX(a.submitted_at)::date,
             60 + floor(random() * 30)
  FROM task_attempts a WHERE a.practice = FALSE
  GROUP BY a.user_id;

  -- -----------------------------------------------------------------------
  -- 4. Workshop posts with reports (the moderation queue content).
  -- -----------------------------------------------------------------------
  INSERT INTO workshop_posts (track_id, author_id, body, created_at)
  SELECT p.track_id, u.id, p.body,
         CURRENT_TIMESTAMP - floor(random() * 30) * INTERVAL '1 day'
  FROM (VALUES
    (1, 'fin.demo1@verifai.demo', 'How do you verify a claim about interest rates before sending it to a client?'),
    (1, 'fin.demo2@verifai.demo', 'Found a great source on pension projections - sharing for feedback.'),
    (1, 'fin.demo3@verifai.demo', 'Anyone else getting conflicting AI summaries of the same report?'),
    (2, 'leg.demo1@verifai.demo', 'Drafting a clause about data retention. What should I double-check?'),
    (2, 'leg.demo2@verifai.demo', 'The AI misquoted case law twice today. Always verify.'),
    (3, 'it.demo1@verifai.demo', 'Best practice for verifying API performance claims from vendor docs?'),
    (3, 'it.demo2@verifai.demo', 'Hallucinated dependency names are the worst. Check the lockfile.'),
    (4, 'biz.demo1@verifai.demo', 'Market sizing numbers from chatbots: useful hypotheses, dangerous facts.'),
    (4, 'biz.demo2@verifai.demo', 'Client asked for sources. The AI invented two consultancies.')
  ) AS p(track_id, email, body)
  JOIN users u ON u.email = p.email
  WHERE NOT EXISTS (SELECT 1 FROM workshop_posts LIMIT 1);

  -- Five reports on the most recent posts (the moderation queue content).
  INSERT INTO workshop_reports (post_id, reporter_id, reason, created_at)
  SELECT p.id, u.id, 'spam', CURRENT_TIMESTAMP - INTERVAL '1 day'
  FROM (SELECT id, row_number() OVER (ORDER BY created_at DESC) AS rn FROM workshop_posts) p
  JOIN users u ON u.email = 'fin.demo1@verifai.demo'
  WHERE p.rn <= 5 AND NOT EXISTS (SELECT 1 FROM workshop_reports LIMIT 1);

  -- -----------------------------------------------------------------------
  -- 5. Three pending draft tasks so the approval queue has content.
  -- -----------------------------------------------------------------------
  INSERT INTO tasks (code, feature, track_id, published, approval)
  VALUES
    ('demo-approval-1', 'verification',    1, FALSE, 'pending'),
    ('demo-approval-2', 'judgement',       2, FALSE, 'pending'),
    ('demo-approval-3', 'risk_governance', 3, FALSE, 'pending')
  ON CONFLICT (code) DO NOTHING;

  INSERT INTO verification_tasks (task_id, format, title, scenario, embedded_flaw, expected_answer, feedback, difficulty)
  SELECT t.id, 'choice', 'Interest rate claim in a client letter',
         'Dear client, your savings account pays 8% interest tax-free from next month.',
         'Interest rates are not tax-free and the figure is unverified.',
         'Correct the rate and remove the tax-free claim, or verify both.',
         'Always verify financial terms against the bank''s own tariff list.', 'easy'
  FROM tasks t WHERE t.code = 'demo-approval-1'
  AND NOT EXISTS (SELECT 1 FROM verification_tasks WHERE task_id = (SELECT id FROM tasks WHERE code = 'demo-approval-1'));

  INSERT INTO task_options (task_id, kind, label, score, sort_order)
  SELECT t.id, o.kind, o.label, o.score, o.sort FROM tasks t,
    (VALUES ('answer', 'Ask the client to verify the rate with the bank.', 100, 0),
            ('answer', 'Send the letter as written - it sounds professional.', 10, 1),
            ('answer', 'Remove the tax-free claim but keep the 8% figure.', 40, 2),
            ('answer', 'Apologise for the delay without addressing the rate.', 0, 3)) AS o(kind, label, score, sort)
  WHERE t.code = 'demo-approval-1'
  AND NOT EXISTS (SELECT 1 FROM task_options WHERE task_id = (SELECT id FROM tasks WHERE code = 'demo-approval-1'));

  INSERT INTO judgement_tasks (task_id, title, scenario, feedback)
  SELECT t.id, 'Responding to a data-retention clause',
         'The AI drafted a clause that lets the vendor keep customer data indefinitely after the contract ends.',
         'Indefinite retention usually conflicts with data-minimisation principles; negotiate a defined period.'
  FROM tasks t WHERE t.code = 'demo-approval-2'
  AND NOT EXISTS (SELECT 1 FROM judgement_tasks WHERE task_id = (SELECT id FROM tasks WHERE code = 'demo-approval-2'));

  INSERT INTO task_options (task_id, kind, label, score, sort_order)
  SELECT t.id, o.kind, o.label, o.score, o.sort FROM tasks t,
    (VALUES ('decision', 'Push for a defined retention period with deletion rights.', 100, 0),
            ('decision', 'Accept the clause as drafted - the vendor knows best.', 15, 1)) AS o(kind, label, score, sort)
  WHERE t.code = 'demo-approval-2'
  AND NOT EXISTS (SELECT 1 FROM task_options WHERE task_id = (SELECT id FROM tasks WHERE code = 'demo-approval-2'));

  INSERT INTO risk_governance_tasks (task_id, title, scenario, feedback)
  SELECT t.id, 'Posting client metrics on social media',
         'A consultant wants to share a client''s improved sales chart on LinkedIn for visibility.',
         'Client confidentiality and consent rules take precedence over marketing value.'
  FROM tasks t WHERE t.code = 'demo-approval-3'
  AND NOT EXISTS (SELECT 1 FROM risk_governance_tasks WHERE task_id = (SELECT id FROM tasks WHERE code = 'demo-approval-3'));

  INSERT INTO task_options (task_id, kind, label, score, sort_order)
  SELECT t.id, o.kind, o.label, o.score, o.sort FROM tasks t,
    (VALUES ('decision', 'Ask the client for written consent before posting.', 100, 0),
            ('decision', 'Post it - anonymising the numbers is enough.', 20, 1)) AS o(kind, label, score, sort)
  WHERE t.code = 'demo-approval-3'
  AND NOT EXISTS (SELECT 1 FROM task_options WHERE task_id = (SELECT id FROM tasks WHERE code = 'demo-approval-3'));

END $$;
