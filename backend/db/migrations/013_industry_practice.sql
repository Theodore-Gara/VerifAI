-- VerifAI — Industry Practice: real-world workplace blunder case studies.
--
-- Informational (not question-based), like Interview Practice: each case shows
-- the scenario, what caused it, and the solution. Sourced from real reporting.

CREATE TABLE IF NOT EXISTS industry_cases (
  id SERIAL PRIMARY KEY,
  track_id INTEGER REFERENCES industry_tracks(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  scenario TEXT NOT NULL,
  cause TEXT NOT NULL,
  solution TEXT NOT NULL,
  source_title VARCHAR(255),
  source_url TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_industry_cases_title ON industry_cases(title);
CREATE INDEX IF NOT EXISTS idx_industry_cases_track ON industry_cases(track_id, sort_order);

CREATE TABLE IF NOT EXISTS industry_case_reads (
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  case_id INTEGER NOT NULL REFERENCES industry_cases(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, case_id)
);
