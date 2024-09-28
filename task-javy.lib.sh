#!/bin/sh
set -o nounset -o errexit

test "${guard_7ebf15b+set}" = set && return 0; guard_7ebf15b=-

. task.sh

subcmd_javy() (
  # Releases · bytecodealliance/javy https://github.com/bytecodealliance/javy/releases
  ver=v3.1.1
  case "$(uname -s)" in
    Linux) rust_os="linux" ;;
    Darwin) rust_os="macos" ;;
    Windows_NT) rust_os="windows";;
    *) echo "Unsupported platform: $(uname -s)" >&2; exit 1;;
  esac
  case "$(uname -m)" in
    i386 | i486 | i586 | i686) rust_arch="x86" ;;
    x86_64) rust_arch="x86_64" ;;
    arm64) rust_arch="aarch64" ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1;;
  esac
  cmd_path=$HOME/.bin/javy-${rust_arch}-${rust_os}-${ver}
  if ! type "$cmd_path" > /dev/null 2>&1
  then
    # https://github.com/bytecodealliance/javy/releases/download/v3.1.1/javy-x86_64-macos-v3.1.1.gz
    url="https://github.com/bytecodealliance/javy/releases/download/${ver}/javy-${rust_arch}-${rust_os}-${ver}.gz"
    cross_run curl --fail --location --output - "$url" | gunzip --stdout - > "$cmd_path"
    chmod +x "$cmd_path"
  fi 
  "$cmd_path" "$@"
)
