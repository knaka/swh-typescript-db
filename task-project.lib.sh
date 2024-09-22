#!/bin/sh
set -o nounset -o errexit

db_path="$(dirname "$0")"/main.db

task_db__dump() {
  cd "$(dirname "$0")" || exit 1
  sh cmd-sqlite3.sh "$db_path" .dump
}

task_db__migrate() {
  cd "$(dirname "$0")" || exit 1
  cross_exec ./gobin run sqlite3def --file=./schema.sql "${db_path}"
}
