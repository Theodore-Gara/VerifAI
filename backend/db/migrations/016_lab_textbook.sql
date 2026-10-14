-- Digital textbook: lab_lesson_sections nest to model
--   book (lab_lessons) > chapter (parent_id NULL) > topic > subtopic.
-- The topic reader renders all of a topic's subtopics together, and lesson
-- progress counts topics read (sections whose parent is a chapter).

ALTER TABLE lab_lesson_sections
  ADD COLUMN IF NOT EXISTS parent_id INTEGER REFERENCES lab_lesson_sections(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_lab_lesson_sections_parent
  ON lab_lesson_sections(parent_id);
