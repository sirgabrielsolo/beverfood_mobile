#!/usr/bin/env bash
# Measures smoothness the way a finger feels it: real touch flings sent with
# adb, timed by SurfaceFlinger (when each of the app's frames reached the
# screen). Unlike the integration test's synthetic flings, real touches get
# Android's touch boost, so these numbers match what the user sees.
#
# Open the app (a profile build) on the screen to measure, then:
#   tool/fling_stats.sh <device-id> <label> <flings> <y-from> <y-to> [x]
# e.g. on a 1080×2400 phone, scrolling down a list eight times:
#   tool/fling_stats.sh TSMNEAX4RCQOIJDA prodotti 8 1900 500
#
# Prints the frames seen and those late by more than half a refresh period
# (each one a dropped frame), at the display's current refresh rate.
set -euo pipefail
device=$1 label=$2 flings=$3 y1=$4 y2=$5 x=${6:-540}
adb_shell() { adb -s "$device" shell "$@"; }

layer=$(adb_shell "dumpsys SurfaceFlinger --list" |
  grep -F 'SurfaceView[com.example.beverfood_mobile' | grep -F '(BLAST)' |
  head -1 | tr -d '\r')
fps=$(adb_shell "dumpsys display" | grep -o 'mActiveRenderFrameRate=[0-9.]*' |
  head -1 | cut -d= -f2)
[ -n "$layer" ] || { echo "The app's surface isn't on screen." >&2; exit 1; }

samples=""
for _ in $(seq 1 "$flings"); do
  adb_shell "dumpsys SurfaceFlinger --latency-clear '$layer'" >/dev/null
  adb_shell input swipe "$x" "$y1" "$x" "$y2" 60
  # SurfaceFlinger keeps the last 128 frames: read them before they roll over.
  sleep 1.3
  samples+=$(adb_shell "dumpsys SurfaceFlinger --latency '$layer'" | tail -n +2)$'\n'
  samples+=$'break\n'
  sleep 0.3
done

python3 -c '
import sys
label, fps = sys.argv[1], float(sys.argv[2])
period = 1000 / fps
gaps, frames, prev = [], 0, None
for line in sys.stdin:
    parts = line.split()
    if len(parts) != 3:
        prev = None
        continue
    present = int(parts[1])
    if not 0 < present < 2**62:
        prev = None
        continue
    if prev is not None and 0 < (present - prev) / 1e6 < 200:
        gaps.append((present - prev) / 1e6)
    prev, frames = present, frames + 1
late = [g for g in gaps if g > period * 1.5]
dropped = sum(round(g / period) - 1 for g in late)
worst = max(gaps, default=0)
print(f"{label} @{fps:.0f} Hz: {frames} frames, {dropped} dropped "
      f"({100 * dropped / max(1, len(gaps) + dropped):.1f}%), worst {worst:.1f} ms")
' "$label" "$fps" <<<"$samples"
