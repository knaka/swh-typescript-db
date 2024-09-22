#!/bin/sh
set -o errexit -o nounset

set_dir_sync_ignored "$(dirname "$0")"/node_modules

subcmd_run() { # Run JS script.
  original_wokrking_dir_path="$PWD"
  cd "$(dirname "$0")" || exit 1
  cross_exec sh volta-cmd.sh run node lib/run-node.mjs "$original_wokrking_dir_path" "$@"
}

subcmd_volta() { # Run Volta.
  cd "$(dirname "$0")" || exit 1
  cross_exec sh volta-cmd.sh "$@"
}

subcmd_npm() { # Run npm.
  cd "$(dirname "$0")" || exit 1
  cross_exec sh volta-cmd.sh run npm "$@"
}

excluded_scrs=",invalid.py,"

_install() {
  _is_windows=$1
  _js_bin_dir_path="$HOME"/js-bin
  mkdir -p "$_js_bin_dir_path"
  rm -f "$_js_bin_dir_path"/*
  for _js_file in *.js *.mjs *.cjs
  do
    if ! test -r "$_js_file"
    then
      continue
    fi
    if echo "$excluded_scrs" | grep -q ",$_js_file,"
    then
      continue
    fi
    _js_name="${_js_file%.*}"
    if $_is_windows
    then
      _js_bin_file_path="$_js_bin_dir_path"/"$_js_name".cmd
      cat <<EOF > "$_js_bin_file_path"
@echo off
"$PWD"\task.cmd run "$PWD\\${_js_file}" %*
EOF
    else 
      _js_bin_file_path="$_js_bin_dir_path"/"$_js_name"
      cat <<EOF > "$_js_bin_file_path"
#!/bin/sh
exec "$PWD"/task run "$PWD/${_js_file}" "\$@"
EOF
      chmod +x "$_js_bin_file_path"
    fi
  done
}

install_unix() {
  _install false
}

install_windows() {
  _install true
}

task_install() { # Install JS scripts.
  if is_windows
  then
    install_windows
  else
    install_unix
  fi
}
