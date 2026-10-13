-- VerifAI — Vera: the friendly, professional AI assistant with memory
--
-- Stores chat sessions and messages, plus durable per-user memories extracted
-- from conversations and progress, so Vera can personalise coaching over time.

CREATE TABLE IF NOT EXISTS vera_sessions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  context VARCHAR(30) NOT NULL DEFAULT 'assistant',
  title VARCHAR(255),
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  message_count INTEGER NOT NULL DEFAULT 0 CHECK (message_count >= 0)
);

CREATE TABLE IF NOT EXISTS vera_messages (
  id SERIAL PRIMARY KEY,
  session_id INTEGER NOT NULL REFERENCES vera_sessions(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(10) NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Durable, de-duplicated memory. UNIQUE(user_id, kind, content) keeps Vera
-- from storing the same observation twice.
CREATE TABLE IF NOT EXISTS vera_memories (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind VARCHAR(20) NOT NULL CHECK (kind IN ('preference', 'struggle', 'strength', 'goal', 'fact')),
  content TEXT NOT NULL,
  source VARCHAR(30) NOT NULL DEFAULT 'chat',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, kind, content)
);

CREATE INDEX IF NOT EXISTS idx_vera_sessions_user ON vera_sessions(user_id, last_active_at DESC);
CREATE INDEX IF NOT EXISTS idx_vera_messages_session ON vera_messages(session_id, created_at);
CREATE INDEX IF NOT EXISTS idx_vera_memories_user ON vera_memories(user_id, kind);

DROP TRIGGER IF EXISTS trg_vera_memories_updated_at ON vera_memories;
CREATE TRIGGER trg_vera_memories_updated_at
BEFORE UPDATE ON vera_memories
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
