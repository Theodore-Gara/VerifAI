-- Wellness: daily mood check-ins, a private journal, and a self-care activity
-- log. One mood check-in and one journal entry per learner per day (the app's
-- wellness screen shows a single entry per day, re-saving updates it).

CREATE TABLE IF NOT EXISTS wellness_mood_checkins (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  check_in_date DATE NOT NULL,
  mood VARCHAR(20) NOT NULL CHECK (mood IN ('Great', 'Calm', 'Okay', 'Stressed', 'Tired', 'Low')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, check_in_date)
);

CREATE TABLE IF NOT EXISTS wellness_journal_entries (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  entry_date DATE NOT NULL,
  content TEXT NOT NULL CHECK (char_length(content) BETWEEN 1 AND 1200),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, entry_date)
);

CREATE TABLE IF NOT EXISTS wellness_activities (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity VARCHAR(20) NOT NULL CHECK (activity IN ('breathing', 'journal', 'step_outside')),
  completed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_wellness_mood_user ON wellness_mood_checkins(user_id, check_in_date DESC);
CREATE INDEX IF NOT EXISTS idx_wellness_journal_user ON wellness_journal_entries(user_id, entry_date DESC);
CREATE INDEX IF NOT EXISTS idx_wellness_activities_user ON wellness_activities(user_id, completed_at DESC);

DROP TRIGGER IF EXISTS trg_wellness_mood_checkins_updated_at ON wellness_mood_checkins;
CREATE TRIGGER trg_wellness_mood_checkins_updated_at
BEFORE UPDATE ON wellness_mood_checkins
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_wellness_journal_entries_updated_at ON wellness_journal_entries;
CREATE TRIGGER trg_wellness_journal_entries_updated_at
BEFORE UPDATE ON wellness_journal_entries
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
