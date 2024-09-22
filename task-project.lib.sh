#!/bin/sh
set -o nounset -o errexit

db_path="$(dirname "$0")"/main.db
schema_path="$(dirname "$0")"/schema.sql

task_db__dump() {
  cd "$(dirname "$0")" || exit 1
  sh cmd-sqlite3.sh "$db_path" .dump
}

task_db__migrate() {
  cd "$(dirname "$0")" || exit 1
  cross_exec ./gobin run sqlite3def --file="${schema_path}" "${db_path}"
}

task_db__diff() {
  cd "$(dirname "$0")" || exit 1
  if ! test -f "${db_path}"
  then
    echo "-- initial --"
    cat "${schema_path}"
    exit 0
  fi
  # Copy only the schema from the current database to a temporary database.
  mkdir -p build
  sh cmd-sqlite3.sh "$db_path" .dump > build/current_schema.sql
  rm -f build/current.db
  sh cmd-sqlite3.sh build/current.db < build/current_schema.sql
  # Then, compare the schema.
  cross_exec ./gobin run sqlite3def --file="${schema_path}" build/current.db --dry-run
}
