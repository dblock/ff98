#!/bin/bash
# Run the ported File & Folder 98 under Wine. Pass --debug to run folder-debug.exe.
set -euo pipefail
source "$(dirname "$0")/env.sh"

EXE=folder.exe
[ "${1:-}" = "--debug" ] && EXE=folder-debug.exe

if [ ! -f "$BIN_DIR/$EXE" ]; then
  echo "$BIN_DIR/$EXE not found, run scripts/build.sh ${1:-} first." >&2
  exit 1
fi

cd "$BIN_DIR"
wine_run "$EXE"
