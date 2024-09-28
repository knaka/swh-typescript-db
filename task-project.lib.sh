#!/bin/sh
set -o nounset -o errexit

test "${guard_c5835f3+set}" = set && return 0; guard_c5835f3=-

. task.sh
. task-sqlite3.lib.sh

set_dir_sync_ignored "$script_dir_path"/build

db_file_path="$script_dir_path"/main.db
schema_file_path="$script_dir_path"/schema.sql

task_db__create() {
  cd "$script_dir_path" || exit 1
  subcmd_sqlite3 "$db_file_path" "VACUUM"
}

task_db__drop() {
  cd "$script_dir_path" || exit 1
  rm -f "$db_file_path"
}

task_db__dump() {
  cd "$script_dir_path" || exit 1
  subcmd_sqlite3 "$db_file_path" ".dump"
}

task_db__migrate() {
  cd "$script_dir_path" || exit 1
  cross_run ./cmd-gobin run sqlite3def --file="${schema_file_path}" "${db_file_path}"
}

task_db__diff() {
  cd "$script_dir_path" || exit 1
  if ! test -f "${db_file_path}"
  then
    echo "-- initial --"
    cat "${schema_file_path}"
    exit 0
  fi
  # Copy only the schema from the current database to a temporary database.
  mkdir -p build
  subcmd_sqlite3 "$db_file_path" ".dump" > build/current_schema.sql
  rm -f build/current.db
  subcmd_sqlite3 build/current.db < build/current_schema.sql
  # Then, compare the schema.
  cross_run ./cmd-gobin run sqlite3def --file="${schema_file_path}" build/current.db --dry-run
}
