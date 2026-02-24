#!/bin/bash
# =============================================================================
# Turn off the Raspberry Pi display (screen goes black, Pi stays on).
# Stops the slideshow and covers the screen with a black window.
#
# Usage:  bash sleep-display.sh
# =============================================================================

export DISPLAY="${DISPLAY:-:0}"

echo "Putting display to sleep…"

# Stop the slideshow
pkill -x feh 2>/dev/null && echo "  Stopped feh"
pkill -f "slideshow.sh" 2>/dev/null && echo "  Stopped slideshow"
rm -f /tmp/slideshow.lock

# Kill any previous black screen
pkill -f "feh --fullscreen.*black" 2>/dev/null

# Create a 1x1 black pixel image if it doesn't exist
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLACK_IMG="$SCRIPT_DIR/.black.png"
if [[ ! -f "$BLACK_IMG" ]]; then
    if command -v convert >/dev/null 2>&1; then
        convert -size 1x1 xc:black "$BLACK_IMG" 2>/dev/null
    else
        printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\x60\x60\x60\x00\x00\x00\x04\x00\x01\xa3\x01\x18\xd8\x00\x00\x00\x00IEND\xaeB\x60\x82' > "$BLACK_IMG"
    fi
fi

# Disable screensaver and blank the screen
xset s off      2>/dev/null
xset -dpms      2>/dev/null
xset s noblank  2>/dev/null

# Show fullscreen black image (stays on top of desktop, panel, everything)
feh --fullscreen --auto-zoom --hide-pointer \
    --image-bg black --title "black" \
    "$BLACK_IMG" >/dev/null 2>&1 &

echo "Display is sleeping (black screen). Run wake-display.sh to restore."
