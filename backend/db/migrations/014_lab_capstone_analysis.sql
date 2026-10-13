-- VerifAI AI Lab — cache Vera's post-capstone performance report on the attempt.
ALTER TABLE lab_capstone_attempts ADD COLUMN IF NOT EXISTS analysis JSONB;
ALTER TABLE lab_capstone_attempts ADD COLUMN IF NOT EXISTS analyzed_at TIMESTAMPTZ;
