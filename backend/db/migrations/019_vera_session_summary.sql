-- Vera session compaction. A long conversation is condensed into a running
-- summary so the model context stays bounded and users can keep chatting.
-- `summary_upto_message_id` marks how far the summary covers: messages with a
-- greater id are still sent verbatim.

ALTER TABLE vera_sessions
  ADD COLUMN IF NOT EXISTS summary TEXT;

ALTER TABLE vera_sessions
  ADD COLUMN IF NOT EXISTS summary_upto_message_id INTEGER;
