-- Wellness refinements: an optional note with a mood check-in, and a soft
-- delete for journal entries so the learner can undo an accidental delete.

ALTER TABLE wellness_mood_checkins
  ADD COLUMN IF NOT EXISTS note TEXT CHECK (note IS NULL OR char_length(note) <= 200);

ALTER TABLE wellness_journal_entries
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_wellness_journal_live
  ON wellness_journal_entries(user_id, entry_date DESC)
  WHERE deleted_at IS NULL;
