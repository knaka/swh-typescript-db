#!/bin/sh
set -o nounset -o errexit

# Prepare:
#   $ ./task db:plugin:build db:gen
#   $ ./task db:drop db:create db:migrate db:seed
#   $ ./task npm install
#
# Then:
#   $ ./task run

test "${guard_c5835f3+set}" = set && return 0; guard_c5835f3=-

. task.sh
. task-sqlite3.lib.sh
. task-volta.lib.sh

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

task_db__cli() {
  cd "$script_dir_path" || exit 1
  subcmd_sqlite3 "$db_file_path"
}

task_db__gen() (
  cd "$script_dir_path" || exit 1
  cross_run ./cmd-gobin run sqlc generate
  for file in sqlcgen/*.ts
  do
    IFS=''
    while read -r line
    do
      args="$(echo "$line" | sed -n -E -e 's/^.* stmt\.(get|all|run)\((.*)\).*$/\2/p')"
      if test -n "$args"
      then
        i=1
        obj=
        delim=
        while true
        do
          arg="${args%%, *}"
          obj="$obj$delim$i: $arg"
          i=$((i + 1))
          delim=", "
          args="${args#*, }"
          if test "$arg" = "$args"
          then
            break
          fi
        done
        obj="{ $obj }"
        line="$(echo "$line" | sed -E -e "s/stmt\.(get|all|run)\((.*)\)/stmt.\1($obj)/")"
      fi
      echo "$line"
    done < "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
  done
)

task_db__plugin__build() {
  cd "$script_dir_path" || exit 1
  if test -r build/sqlc-gen-typescript/examples/plugin.wasm
  then
    return 0
  fi
  cd build
  if ! test -d sqlc-gen-typescript
  then
    git clone https://github.com/sqlc-dev/sqlc-gen-typescript.git
  fi
  cd sqlc-gen-typescript
  cp ../../task.sh ../../task-*.lib.sh .
  sh task.sh npm install
  # https://github.com/sqlc-dev/sqlc-gen-typescript/blob/main/.github/workflows/ci.yml
  sh task.sh npx tsc --noEmit
  sh task.sh npx esbuild --bundle src/app.ts --tree-shaking=true --format=esm --target=es2020 --outfile=out.js
  sh task.sh javy build out.js -o examples/plugin.wasm
}

subcmd_run() {
  subcmd_npx ts-node --prefer-ts-exts index.ts
}

task_db__seed() {
  cd "$script_dir_path" || exit 1
  subcmd_sqlite3 "$db_file_path" ".read seed.sql"
}
