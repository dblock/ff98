#!/bin/bash
# Build ported/ into ported/bin/folder.exe with the win32 Free Pascal
# compiler under Wine. Pass --debug for a console build with line info,
# folder-debug.exe, which prints start-up exceptions to stderr.
set -euo pipefail
source "$(dirname "$0")/env.sh"

if [ ! -x "$WINE_BIN" ]; then
  echo "Toolchain missing, run scripts/setup.sh first." >&2
  exit 1
fi

MODE_FLAGS=(-WG -O1)
OUT=folder.exe
LIB=lib/release
if [ "${1:-}" = "--debug" ]; then
  MODE_FLAGS=(-WC -gl -O- -dFF98DEBUG)
  OUT=folder-debug.exe
  LIB=lib/debug
fi

cd "$PORTED_DIR"
mkdir -p "$BIN_DIR" "$LIB"

L="$LAZARUS_DIR"
cd src
wine_run "$FPC_EXE" -Mdelphi -Twin32 -vewn -Sh -B "${MODE_FLAGS[@]}" \
  -dLCL -dLCLwin32 \
  -Fu"$L\\lcl\\units\\i386-win32\\win32" -Fu"$L\\lcl\\units\\i386-win32" \
  -Fu"$L\\components\\lazutils\\lib\\i386-win32" \
  -Fu"$L\\components\\freetype\\lib\\i386-win32" \
  -Fu"$L\\components\\lazcontrols\\lib\\i386-win32\\win32" \
  -Fu'..\common.d32' -Fu'..\compat' \
  -FU"..\\${LIB//\//\\}" -o"..\\bin\\$OUT" folder.lpr \
  | grep -v -e 'Hint:' -e 'Note:'

# The Word text preview calls ReadWordDocument in the original 1998 docdll.dll,
# and Help opens the original WinHelp file.
cp "$APP_DIR/original/docdll.dll" "$APP_DIR/original/folder.hlp" "$APP_DIR/original/folder.cnt" "$BIN_DIR/"

test -f "$BIN_DIR/$OUT"
echo "Built $BIN_DIR/$OUT"
