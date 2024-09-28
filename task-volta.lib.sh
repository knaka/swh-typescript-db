#!/bin/sh
set -o nounset -o errexit

test "${guard_ca67a57+set}" = set && return 0; guard_ca67a57=-

subcmd_volta() ( # Executes volta command.
  # Releases · volta-cli/volta https://github.com/volta-cli/volta/releases
  cmd_base=volta
  ver=2.0.1

  arc_ext=".tar.gz"
  case "$(uname -s)" in
    Linux)
      case "$(uname -m)" in
        x86_64) os_arch="linux" ;;
        arm64) os_arch="linux-arm" ;;
        *)
          echo "Unspoorted architecture: $(uname -m)" >&2
          exit 1;;
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
      echo "Unsupported OS: $(uname -s)" >&2
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
    rm -fr "$temp_dir_path"
  fi
  PATH="$volta_dir_path:$PATH" "$cmd_base" "$@"
)

subcmd_npm() { # Run npm.
  cd "$(dirname "$0")" || exit 1
  subcmd_volta run npm "$@"
}

subcmd_npx() { # Run npx.
  cd "$(dirname "$0")" || exit 1
  subcmd_volta run npx "$@"
}
