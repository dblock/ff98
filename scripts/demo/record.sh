#!/bin/bash
# Records a demo of File & Folder 98 to $DEMO_DIR/rec.mov (macOS only).
#
# Needs ffmpeg and cliclick (brew install ffmpeg cliclick), and Screen Recording
# and Accessibility permissions for the terminal. Only the main window's area is
# recorded. Expects the UNIGE volume from the README, with a Telematique folder
# that holds tp4.router.doc. Don't touch the mouse or keyboard while it runs.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
export DEMO_DIR="${DEMO_DIR:-/tmp/ff98demo}"
D="$DEMO_DIR"
SCALE="${SCALE:-2}"
SCREEN="${SCREEN:-$(ffmpeg -hide_banner -f avfoundation -list_devices true -i "" 2>&1 | sed -n 's/.*\[\([0-9]*\)\] Capture screen 0.*/\1/p' | head -1)}"
mkdir -p "$D"
rm -f "$D/rec.mov"

"$HERE/../run.sh" >/dev/null 2>&1 &
PID=""
for _ in $(seq 60); do
  PID=$(pgrep -f 'folder\.exe' | head -1)
  [ -n "$PID" ] && osascript -e "tell application \"System Events\" to count windows of (first process whose unix id is $PID)" 2>/dev/null | grep -q '[1-9]' && break
  sleep 1
done
sleep 3
osascript -e "tell application \"System Events\" to set frontmost of (first process whose unix id is $PID) to true"
sleep 1

# The main window's origin and size, in points.
read -r X0 Y0 W H < <(osascript -e "tell application \"System Events\" to tell (first process whose unix id is $PID) to get {position, size} of window \"File & Folder 98\"" | tr -d ',' )

click() { # x y, relative to the main window
  local x=$((X0 + $1)) y=$((Y0 + $2))
  cliclick m:$x,$y w:200 dd:$x,$y w:150 du:$x,$y
}
move() { cliclick "m:$((X0 + $1)),$((Y0 + $2))"; }
windows() { osascript -e "tell application \"System Events\" to count windows of (first process whose unix id is $PID)"; }
# Wine sometimes drops the first click after a window activates. Click until
# the number of windows changes to what the click should produce.
click_for() { # x y expected-window-count
  for _ in 1 2 3; do
    click "$1" "$2"; sleep 1.5
    [ "$(windows)" = "$3" ] && return
  done
}

ffmpeg -loglevel error -f avfoundation -capture_cursor 1 -framerate 15 -pixel_format uyvy422 \
  -i "$SCREEN:none" -t 120 \
  -vf "crop=$((W * SCALE)):$((H * SCALE)):$((X0 * SCALE)):$((Y0 * SCALE))" \
  -c:v libx264 -preset ultrafast -crf 18 -y "$D/rec.mov" </dev/null >"$D/ffmpeg.log" 2>&1 &
FF=$!
sleep 3

move 360 300; sleep 1
click 196 121; sleep 2           # open the Telematique folder
click 205 175; sleep 2           # select tp4.router
N=$(windows)
click_for 84 487 $((N + 1)); sleep 3     # Document Properties
click_for 396 447 $N; sleep 1            # Close
click_for 92 524 $((N + 1)); sleep 2     # Doc Text Preview
for _ in 1 2 3 4 5; do click 504 380; sleep 0.5; done   # scroll the text down
sleep 1
click_for 51 407 $N; sleep 1             # Close
click_for 92 505 $((N + 1)); sleep 4     # Document Preview
click_for 86 393 $N; sleep 1             # Close
click 180 90; sleep 2                    # back to the UNIGE volume
click_for 84 105 $((N + 1)); sleep 5     # About File & Folder 98
click_for 62 166 $N; sleep 2             # Close
sleep 1
kill -INT $FF
wait $FF

kill "$PID" 2>/dev/null
echo "Recorded $D/rec.mov, now run $HERE/encode.sh"
