-- 018_assistant_sessions.sql
-- Add assistant_sessions and assistant_messages tables for task-scoped chat history
-- Run on live database to add persistence for the learning assistant.

-- ---------------------------------------------------------------------------
-- Learning Assistant — per-task chat history
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS assistant_sessions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  message_count INTEGER NOT NULL DEFAULT 0 CHECK (message_count >= 0),
  UNIQUE (user_id, task_id)
);

CREATE TABLE IF NOT EXISTS assistant_messages (
  id SERIAL PRIMARY KEY,
  session_id INTEGER NOT NULL REFERENCES assistant_sessions(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(10) NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_assistant_sessions_user ON assistant_sessions(user_id, last_active_at DESC);
CREATE INDEX IF NOT EXISTS idx_assistant_messages_session ON assistant_messages(session_id, created_at);