-- Summative capstone papers are split into sections (e.g. Section A
-- application, Section B scenario / long answers, Section C case study).
-- Each question carries its section label so the paper can group and order it.

ALTER TABLE lab_capstone_questions
  ADD COLUMN IF NOT EXISTS section VARCHAR(40);
