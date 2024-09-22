#!/bin/sh
set -o nounset -o errexit

# --------------------------------------------------------------------------

is_windows() {
  case "$(uname -s)" in
    Windows_NT|CYGWIN*|MINGW*|MSYS*) return 0 ;;
    *) return 1 ;;
  esac
}

exe_ext() {
  if is_windows
  then
    echo ".exe"
  fi
}

set_path_attr() (
  path="$1"
  attribute="$2"
  value="$3"
  if which xattr > /dev/null 2>&1
  then
    xattr -w "$attribute" "$value" "$path"
  elif which PowerShell > /dev/null 2>&1
  then
    PowerShell -Command "Set-Content -Path '$path' -Stream '$attribute' -Value '$value'"
  elif which attr > /dev/null 2>&1
  then
    attr -s "$attribute" -V "$value" "$path"
  fi
)

set_dir_sync_ignored() (
  for path in "$@"
  do
    mkdir -p "$path"
    for attribute in "com.dropbox.ignored" "com.apple.fileprovider.ignore#P"
    do
      set_path_attr "$path" "$attribute" 1
    done
  done
)

is_newer_than() {
  test -n "$(find "$1" -newer "$2"  2>/dev/null)" || return 1
}

# Busybox sh seems to fail to detect proper executable if POSIX style one exists in the same directory.
cross_exec() {
  if type cleanup > /dev/null 2>&1
  then
    cleanup
  fi
  if ! is_windows
  then
    exec "$@"
  fi
  if ! test "${1+set}" = set
  then
    exit 1
  fi
  cmd_path="$1"
  shift
  if type "$cmd_path.exe" >/dev/null 2>&1
  then
    exec "$cmd_path.exe" "$@"
  fi
  if type "$cmd_path.cmd" >/dev/null 2>&1
  then
    exec "$cmd_path.cmd" "$@"
  fi
  if type "$cmd_path.bat" >/dev/null 2>&1
  then
    exec "$cmd_path.bat" "$@"
  fi
  exec "$cmd_path" "$@"
}

# --------------------------------------------------------------------------

task_subcmds() ( # List subcommands.
  cd "$(dirname "$0")"
  delim=" delim_2ed1065 "
  # shellcheck disable=SC2086
  cnt="$(grep -E -h -e "^subcmd_[_[:alnum:]]+\(" $task_file_paths | sed -r -e 's/^subcmd_//' -e 's/^([^ ()]+)__/\1:/g' -e "s/\(\) *[{(] *(# *)?/$delim/")"
  if type delegate_tasks > /dev/null 2>&1
  then
    if delegate_tasks subcmds > /dev/null 2>&1
    then
      cnt="$(printf "%s\n%s" "$cnt" "$(delegate_tasks subcmds | sed -r -e "s/(^[^ ]+) +/\1$delim/")")"
    fi
  fi
  max_len="$(echo "$cnt" | awk '{ if (length($1) > max_len) max_len = length($1) } END { print max_len }')"
  echo "$cnt" | sort | awk -F"$delim" "{ printf \"%-${max_len}s  %s\n\", \$1, \$2 }"
)

task_tasks() { # List tasks.
  (
    delim=" delim_d3984dd "
    # shellcheck disable=SC2086
    cnt="$(grep -E -h -e "^task_[_[:alnum:]]+\(" $task_file_paths | sed -r -e 's/^task_//' -e 's/^([^ ()]+)__/\1:/g' -e "s/\(\) *[{(] *(# *)?/$delim/")"
    if type delegate_tasks > /dev/null 2>&1
    then
      if delegate_tasks tasks > /dev/null 2>&1
      then
        cnt="$(printf "%s\n%s" "$cnt" "$(delegate_tasks tasks | sed -r -e "s/(^[^ ]+) +/\1$delim/")")"
      fi
    fi
    max_len="$(echo "$cnt" | awk '{ if (length($1) > max_len) max_len = length($1) } END { print max_len }')"
    echo "$cnt" | sort | awk -F"$delim" "{ printf \"%-${max_len}s  %s\n\", \$1, \$2 }"
  )
}

task_help() ( # Show help message.
  cd "$(dirname "$0")" || exit 1
  cat <<EOF
Usage:
  $0 <subcommand> [args...]
  $0 <task[arg1,arg2,...]> [tasks...]

Subcommands:
EOF
  task_subcmds | sed -r -e 's/^/  /'
  cat <<EOF

Tasks:
EOF
  task_tasks | sed -r -e 's/^/  /'
)

subcmd_pwd() {
  pwd "$@"
}

subcmd_false() { # Always fail.
  false "$@"
}

task_nop() { # Do nothing.
  echo NOP
}

main() {
  if test "${ARG0BASE+set}" = "set"
  then
    case "$ARG0BASE" in
      task-*)
        env="${ARG0BASE#task-}"
        case "$env" in
          dev|development)
            APP_ENV=development
            APP_SENV=dev
            ;;
          prd|production)
            APP_ENV=production
            APP_SENV=prd
            ;;
          *) echo "Unknown environment: $env" >&2; exit 1;;
        esac
        export APP_ENV APP_SENV
        ;;
      *)
        ;;
    esac
  fi

  verbose=false
  shows_help=false
  directory=""
  while getopts "vhd:" opt
  do
    case "$opt" in
      v) verbose=true;;
      h) shows_help=true;;
      d) directory="$OPTARG";;
      *) exit 1;;
    esac
  done
  shift $((OPTIND-1))

  if test -n "$directory"
  then
    cd "$directory"
  fi

  task_file_paths="$0"
  for file_path in "$(dirname "$0")"/task_*.sh "$(dirname "$0")"/task-*.sh
  do
    if ! test -r "$file_path"
    then
      continue
    fi
    case "$(basename "$file_path")" in
      task-dev.sh|task-prd.sh) continue;;
    esac
    task_file_paths="$task_file_paths $file_path"
    # shellcheck disable=SC1090
    . "$file_path"
    if $verbose; then echo "Loaded $file_path" >&2; fi
  done

  if $shows_help || test "${1+set}" != "set"
  then
    task_help
    exit 0
  fi

  subcmd="$1"
  if type subcmd_"$subcmd" > /dev/null 2>&1
  then
    shift
    subcmd_"$subcmd" "$@"
    exit 0
  fi

  for task_with_args in "$@"
  do
    task="$task_with_args"
    args=""
    case "$task_with_args" in
      *\[*)
        task="${task_with_args%%\[*}"
        args="$(echo "$task_with_args" | sed -r -e 's/^.*\[//' -e 's/\]$//' -e 's/,/ /')"
        ;;
    esac
    task="$(echo "$task" | sed -r -e 's/:/__/g')"
    if ! type task_"$task" > /dev/null 2>&1
    then
      if type delegate_tasks > /dev/null 2>&1
      then  
        delegate_tasks "$@"
        exit 0
      fi
      echo "Unknown task: $task" >&2
      exit 1
    fi
    # shellcheck disable=SC2086
    task_"$task" $args
  done
}

# To make this file can be sourced to provide functions.
if test "$(basename "$0")" = "task.sh"
then
  main "$@"
fi
