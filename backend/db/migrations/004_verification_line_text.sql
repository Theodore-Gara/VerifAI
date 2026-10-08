-- =============================================================================
-- 004: Verification 'line_text' format
-- =============================================================================
-- Adds the second Verification interaction (numbered AI output + tap the flawed
-- line(s) + typed fix + typed reason) alongside the existing 'choice' format.
--
-- The runner wraps this file in a transaction; do NOT put BEGIN/COMMIT here.
-- =============================================================================

ALTER TABLE verification_tasks
  ADD COLUMN IF NOT EXISTS format VARCHAR(20) NOT NULL DEFAULT 'choice'
    CHECK (format IN ('choice', 'line_text')),
  ADD COLUMN IF NOT EXISTS ai_output_lines TEXT[],
  ADD COLUMN IF NOT EXISTS flaw_lines INTEGER[],
  ADD COLUMN IF NOT EXISTS fix_keywords TEXT[],
  ADD COLUMN IF NOT EXISTS reason_keywords TEXT[];

ALTER TABLE verification_tasks DROP COLUMN IF EXISTS keywords;

ALTER TABLE task_attempts ADD COLUMN IF NOT EXISTS selected_lines INTEGER[];
