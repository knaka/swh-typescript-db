-- name: GetUser :one
SELECT *
FROM users
WHERE
  -- id = sqlc.arg(id)
  id = ?
LIMIT 1
;
