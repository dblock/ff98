#!/bin/bash
# Writes ff98.mp4 and ff98.gif from $DEMO_DIR/rec.mov. Needs ffmpeg and gifsicle.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
D="${DEMO_DIR:-/tmp/ff98demo}"
START="${START:-2}"
TRIM="trim=start=$START,setpts=PTS-STARTPTS"

ffmpeg -loglevel error -i "$D/rec.mov" -vf "$TRIM,format=yuv420p" \
  -c:v libx264 -preset slow -crf 24 -movflags +faststart -an -y "$ROOT/ff98.mp4"
ffmpeg -loglevel error -i "$D/rec.mov" \
  -vf "$TRIM,fps=8,scale=524:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=64:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
  -y "$D/demo.gif"
gifsicle -O3 --lossy=30 "$D/demo.gif" -o "$ROOT/ff98.gif"
ls -la "$ROOT/ff98.mp4" "$ROOT/ff98.gif"
