#!/bin/sh
set -o nounset -o errexit

# Releases · volta-cli/volta https://github.com/volta-cli/volta/releases
cmd_base=volta
ver=2.0.1

# --------------------------------------------------------------------------

cleanup() {
  if test "${temp_dir_path+set}" = set
  then
    rm -rf "$temp_dir_path"
  fi
}

trap cleanup EXIT

if ! realpath "$(pwd)" | grep -q "^$(realpath "$(dirname "$0")")"
then
  echo "Please run this script in the same directory as the script." >&2
  exit 1
fi

. "$(dirname "$0")"/task.sh

arc_ext=".tar.gz"
case "$(uname -s)" in
  Linux)
    case "$(uname -m)" in
      x86_64) os_arch="linux" ;;
      arm64) os_arch="linux-arm" ;;
      *) exit 1;;
    esac
    ;;
  Darwin)
    # Mach-O universal binarries.
    os_arch="macos"
    ;;
  Windows_NT)
    arc_ext=".zip"
    case "$(uname -m)" in
      x86_64) os_arch="windows" ;;
      arm64) os_arch="windows-arm64" ;;
      *) exit 1;;
    esac
    ;;
  *)
    exit 1
    ;;
esac
bin_dir_path="$HOME"/.bin
volta_dir_path="$bin_dir_path/${cmd_base}@${ver}"
mkdir -p "$volta_dir_path"
volta_cmd_path="$volta_dir_path/$cmd_base$(exe_ext)"
if ! test -x "$volta_cmd_path"
then
  url=https://github.com/volta-cli/volta/releases/download/v${ver}/volta-${ver}-${os_arch}${arc_ext}
  temp_dir_path="$(mktemp -d)"
  curl"$(exe_ext)" --fail --location "$url" -o "$temp_dir_path"/tmp"$arc_ext"
  (cd "$volta_dir_path"; tar"$(exe_ext)" -xf "$temp_dir_path"/tmp"$arc_ext")
  chmod +x "$volta_dir_path"/*
fi
PATH="$volta_dir_path:$PATH" cross_exec "$cmd_base" "$@"
