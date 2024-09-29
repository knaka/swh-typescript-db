-- name: GetUser :one
SELECT *
FROM users
WHERE
  CASE WHEN CAST(sqlc.narg(nullable_id) AS number) IS NOT NULL THEN id = sqlc.narg(nullable_id) ELSE false END OR
  id = sqlc.arg(id)
LIMIT 1
;

-- name: GetTheUser :many
SELECT *
FROM users
WHERE
  id = sqlc.arg(id)
;

-- name: AddUser :exec
INSERT INTO users (username) VALUES (sqlc.arg(username));

