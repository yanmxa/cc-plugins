#!/usr/bin/env bash
# render.sh — render a comic intro to a crisp GIF (and optionally MP4).
#
#   render.sh <html-file> <out.gif> [fps=12] [jobs=8]
#
# Frames are shot at full 1280×720 and never scaled down: scaling is what makes
# README GIFs blurry. Black-and-white art needs only a small palette, so 32
# colours without dithering stays sharp and small. Also writes <out>.mp4.
set -euo pipefail
html="${1:?usage: render.sh <html-file> <out.gif> [fps] [jobs]}"
out="${2:?usage: render.sh <html-file> <out.gif> [fps] [jobs]}"
fps="${3:-12}"
jobs="${4:-8}"
here="$(cd "$(dirname "$0")" && pwd)"

# timeline length = the latest data-start + data-dur in the page
total="$(grep -o 'data-start="[0-9.]*" data-dur="[0-9.]*"' "$html" \
  | sed -E 's/data-start="([0-9.]+)" data-dur="([0-9.]+)"/\1 \2/' \
  | awk 'BEGIN{m=0} {e=$1+$2; if (e>m) m=e} END{print m}')"
n="$(awk -v t="$total" -v f="$fps" 'BEGIN{printf "%d", t*f}')"

frames="$(mktemp -d)"
trap 'rm -rf "$frames"' EXIT
echo "rendering $n frames (${total}s @ ${fps}fps) with $jobs workers…"
# one "<t> <out.png>" pair per frame, shot in parallel
awk -v n="$n" -v f="$fps" -v d="$frames" 'BEGIN{for (i = 0; i < n; i++) printf "%.4f %s/f%05d.png\n", i / f, d, i}' \
  | xargs -P "$jobs" -n 2 "$here/shoot.sh" "$html" >/dev/null

ffmpeg -v error -y -framerate "$fps" -i "$frames/f%05d.png" \
  -vf "split[a][b];[a]palettegen=max_colors=32:stats_mode=diff[p];[b][p]paletteuse=dither=none:diff_mode=rectangle" "$out"
ffmpeg -v error -y -framerate "$fps" -i "$frames/f%05d.png" -c:v libx264 -pix_fmt yuv420p -crf 18 "${out%.*}.mp4"
ls -lh "$out" "${out%.*}.mp4"
