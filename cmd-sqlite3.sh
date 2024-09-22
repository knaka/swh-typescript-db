#!/bin/sh
set -o nounset -o errexit

if ! realpath "$(pwd)" | grep -q "^$(realpath "$(dirname "$0")")"
then
  echo "Please run this script in the same directory as the script." >&2
  exit 1
fi

. "$(dirname "$0")"/task.sh

if ! is_windows
then
  if ! type sqlite3 > /dev/null 2>&1
  then
    echo "Please install SQLite3." >&2
    exit 1
  fi
  cross_exec sqlite3 "$@"
fi

cmd_path=
if ! type "$cmd_path" > /dev/null 2>&1
then
  winget install -e --id SQLite.SQLite
  cmd_path=sqlite3
fi

cross_exec "$cmd_path"
