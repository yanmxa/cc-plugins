#!/usr/bin/env bash
# shoot.sh — render one frame of a comic intro at timeline second <t>.
# The page freezes when loaded with ?t=<seconds>, so the frame is deterministic.
#
#   shoot.sh <html-file> <t-seconds> [out.png]
#
# Env: CHROME=/path/to/chrome overrides the browser binary.
set -euo pipefail
file="${1:?usage: shoot.sh <html-file> <t> [out.png]}"
t="${2:-0}"
out="${3:-/tmp/comic-shots/t${t}.png}"

CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
[ -x "$CHROME" ] || CHROME="$(command -v google-chrome || command -v chromium || command -v chromium-browser)"

abs="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
mkdir -p "$(dirname "$out")"
# --virtual-time-budget only lets fonts and layout settle; ?t= is what picks the frame.
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
  --window-size=1280,720 --virtual-time-budget=2500 \
  --screenshot="$out" "file://${abs}?t=${t}" >/dev/null 2>&1
echo "$out"
