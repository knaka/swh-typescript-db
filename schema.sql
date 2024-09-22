CREATE TABLE users (
  id integer PRIMARY KEY,
  username text NOT NULL,
  updated_at datetime NOT NULL DEFAULT current_timestamp,
  created_at datetime NOT NULL DEFAULT current_timestamp
);
