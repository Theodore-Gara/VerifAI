-- Vera's rolling understanding of each learner, rewritten in the background
-- after conversations. Separate from vera_memories, which stores discrete
-- durable facts; this is the synthesised "who they are" profile.

CREATE TABLE IF NOT EXISTS vera_profiles (
  user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  profile TEXT NOT NULL DEFAULT '',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_vera_profiles_updated_at ON vera_profiles;
CREATE TRIGGER trg_vera_profiles_updated_at
BEFORE UPDATE ON vera_profiles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
