# Shared settings for the ff98 build scripts. Source this file, don't run it.

FF98_TOOLS="${FF98_TOOLS:-$HOME/.cache/ff98}"
WINE_VERSION="${WINE_VERSION:-11.18}"
LAZARUS_VERSION="${LAZARUS_VERSION:-4.8}"
FPC_VERSION="${FPC_VERSION:-3.2.2}"

WINE_APP="$FF98_TOOLS/Wine Devel.app"
WINE_BIN="$WINE_APP/Contents/Resources/wine/bin/wine"
export WINEPREFIX="$FF98_TOOLS/wineprefix"
export WINEDEBUG="${WINEDEBUG:--all}"

LAZARUS_DIR='C:\lazarus'
FPC_EXE="$LAZARUS_DIR\\fpc\\$FPC_VERSION\\bin\\i386-win32\\fpc.exe"

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORTED_DIR="$APP_DIR/ported"
BIN_DIR="$PORTED_DIR/bin"

# Run a Windows program under Wine, hiding MoltenVK/Metal start-up chatter.
wine_run() {
  "$WINE_BIN" "$@" 2> >(grep -v -e '^\s' -e 'mvk-' -e 'MoltenVK' -e 'Vulkan' >&2)
}
