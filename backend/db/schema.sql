-- VerifAI Database Schema

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  firebase_uid VARCHAR(128) UNIQUE NOT NULL,
  email VARCHAR(255) NOT NULL,
  display_name VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE industry_tracks (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT
);

CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  track_id INTEGER REFERENCES industry_tracks(id),
  title VARCHAR(255) NOT NULL,
  scenario TEXT NOT NULL,
  correct_answer TEXT,
  dimension VARCHAR(50) NOT NULL,
  difficulty VARCHAR(20) DEFAULT 'medium',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE scores (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  dimension VARCHAR(50) NOT NULL,
  score INTEGER DEFAULT 0,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE task_submissions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  task_id INTEGER REFERENCES tasks(id),
  answer TEXT NOT NULL,
  explanation TEXT,
  score INTEGER,
  submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
