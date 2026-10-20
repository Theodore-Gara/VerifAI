-- 023 — Task approval workflow + per-department answer tracking.
--
-- `tasks.approval`: 'pending' (awaiting moderator), 'approved' (may be
-- published), 'rejected'. Only approved tasks can ever be published; rejected
-- ones stay editable for rework. Seed/admin-imported tasks default to pending
-- so a moderator always signs off before learners see them.
-- Also records who approved/rejected and why.
--
-- `answer_logs`: one row per graded answer, denormalised with the user's
-- department (industry track) and the task's feature, so per-department
-- analytics never need to join through task_attempts at query time.

ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS approval VARCHAR(20) NOT NULL DEFAULT 'pending'
    CHECK (approval IN ('pending', 'approved', 'rejected')),
  ADD COLUMN IF NOT EXISTS approved_by VARCHAR(255),
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS approval_note TEXT;

-- On migration, seeded tasks that are already live count as approved.
UPDATE tasks SET approval = 'approved', approved_by = 'seed migration', approved_at = CURRENT_TIMESTAMP WHERE published;

CREATE TABLE IF NOT EXISTS answer_logs (
  id SERIAL PRIMARY KEY,
  attempt_id INTEGER REFERENCES task_attempts(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  department_id INTEGER REFERENCES industry_tracks(id) ON DELETE SET NULL,
  feature VARCHAR(30) NOT NULL,
  score INTEGER NOT NULL CHECK (score BETWEEN 0 AND 100),
  passed BOOLEAN NOT NULL,
  practice BOOLEAN NOT NULL DEFAULT FALSE,
  answer_summary TEXT,
  submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_answer_logs_dept ON answer_logs (department_id, submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_answer_logs_feature ON answer_logs (feature, submitted_at DESC);
