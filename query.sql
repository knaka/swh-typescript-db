-- name: GetUser :one
SELECT *
FROM users
WHERE
  CASE WHEN CAST(sqlc.narg(nullable_id) AS integer) IS NOT NULL THEN id = sqlc.narg(nullable_id) ELSE false END OR
  CASE WHEN CAST(sqlc.narg(nullable_username) AS string) IS NOT NULL THEN username = sqlc.narg(nullable_username) ELSE false END
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
