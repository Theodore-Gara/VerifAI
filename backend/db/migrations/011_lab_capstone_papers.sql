-- VerifAI AI Lab — richer capstone papers
--
-- Adds scenario stems, per-question marks, auto vs rubric marking, numeric and
-- multi-select questions, and a marking workflow for rubric questions.

-- Assessment-level metadata.
ALTER TABLE lab_capstone_assessments ADD COLUMN IF NOT EXISTS scenario JSONB;
ALTER TABLE lab_capstone_assessments ADD COLUMN IF NOT EXISTS instructions JSONB;
ALTER TABLE lab_capstone_assessments ADD COLUMN IF NOT EXISTS total_marks INTEGER NOT NULL DEFAULT 0;
ALTER TABLE lab_capstone_assessments ADD COLUMN IF NOT EXISTS grade_bands JSONB;

-- Question-level metadata.
ALTER TABLE lab_capstone_questions ALTER COLUMN correct DROP NOT NULL;
ALTER TABLE lab_capstone_questions ALTER COLUMN explanation DROP NOT NULL;
ALTER TABLE lab_capstone_questions ADD COLUMN IF NOT EXISTS marks INTEGER NOT NULL DEFAULT 1 CHECK (marks > 0);
ALTER TABLE lab_capstone_questions ADD COLUMN IF NOT EXISTS marking VARCHAR(10) NOT NULL DEFAULT 'auto';
ALTER TABLE lab_capstone_questions ADD COLUMN IF NOT EXISTS rubric JSONB;
ALTER TABLE lab_capstone_questions ADD COLUMN IF NOT EXISTS model_answer TEXT;
ALTER TABLE lab_capstone_questions ADD COLUMN IF NOT EXISTS code_lines JSONB;
ALTER TABLE lab_capstone_questions ADD COLUMN IF NOT EXISTS word_limit JSONB;
ALTER TABLE lab_capstone_questions ADD COLUMN IF NOT EXISTS competency VARCHAR(40);
ALTER TABLE lab_capstone_questions ADD COLUMN IF NOT EXISTS cognitive_level VARCHAR(40);
ALTER TABLE lab_capstone_questions ADD COLUMN IF NOT EXISTS source_refs JSONB;

ALTER TABLE lab_capstone_questions DROP CONSTRAINT IF EXISTS lab_capstone_questions_type_check;
ALTER TABLE lab_capstone_questions
  ADD CONSTRAINT lab_capstone_questions_type_check
  CHECK (type IN ('multiple_choice', 'true_false', 'matching', 'fill_blank', 'ordering', 'numeric', 'multi_select', 'extended_response'));

ALTER TABLE lab_capstone_questions DROP CONSTRAINT IF EXISTS lab_capstone_questions_marking_check;
ALTER TABLE lab_capstone_questions
  ADD CONSTRAINT lab_capstone_questions_marking_check
  CHECK (marking IN ('auto', 'rubric'));

-- Attempt-level marking state.
ALTER TABLE lab_capstone_attempts ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'marked';
ALTER TABLE lab_capstone_attempts ADD COLUMN IF NOT EXISTS auto_marks INTEGER;
ALTER TABLE lab_capstone_attempts ADD COLUMN IF NOT EXISTS marks_awarded INTEGER;
ALTER TABLE lab_capstone_attempts ADD COLUMN IF NOT EXISTS marking JSONB;
ALTER TABLE lab_capstone_attempts ADD COLUMN IF NOT EXISTS marked_by TEXT;
ALTER TABLE lab_capstone_attempts ADD COLUMN IF NOT EXISTS marked_at TIMESTAMPTZ;

ALTER TABLE lab_capstone_attempts DROP CONSTRAINT IF EXISTS lab_capstone_attempts_status_check;
ALTER TABLE lab_capstone_attempts
  ADD CONSTRAINT lab_capstone_attempts_status_check
  CHECK (status IN ('pending_marking', 'marked'));
