#!/bin/bash
# =============================================================================
# Wake the Raspberry Pi display and restart the slideshow.
#
# Usage:  bash wake-display.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SLIDESHOW_SCRIPT="$SCRIPT_DIR/slideshow.sh"

export DISPLAY="${DISPLAY:-:0}"

echo "Waking display…"

# Kill the black screen
pkill -f "feh --fullscreen.*black" 2>/dev/null
pkill -f 'feh.*\.black\.png' 2>/dev/null
pkill -x feh 2>/dev/null

sleep 0.5

# Clean up lock so slideshow can start
rm -f /tmp/slideshow.lock

# Start the slideshow
echo "Starting slideshow…"
nohup bash "$SLIDESHOW_SCRIPT" >/dev/null 2>&1 &
echo "Slideshow started (PID: $!)"

echo "Done — display is awake."
