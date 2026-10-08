-- =============================================================================
-- 003: Interview Practice (Legal only for now)
-- =============================================================================
-- Read-only, ungraded question bank plus per-user coverage tracking. Coverage
-- feeds the readiness score (least weight). No scoring / XP.
--
-- The runner wraps this file in a transaction; do NOT put BEGIN/COMMIT here.
-- =============================================================================

CREATE TABLE IF NOT EXISTS interview_questions (
  id SERIAL PRIMARY KEY,
  track_id INTEGER NOT NULL REFERENCES industry_tracks(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  sample_answer TEXT NOT NULL,
  what_employers_test TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS interview_practice (
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  question_id INTEGER NOT NULL REFERENCES interview_questions(id) ON DELETE CASCADE,
  practiced_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, question_id)
);

CREATE INDEX IF NOT EXISTS idx_interview_questions_track ON interview_questions(track_id, sort_order);
