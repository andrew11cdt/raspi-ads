#!/bin/bash
# =============================================================================
# Turn on the Raspberry Pi display and ensure the slideshow is running.
#
# Usage:  bash wake-display.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SLIDESHOW_SCRIPT="$SCRIPT_DIR/slideshow.sh"

export DISPLAY="${DISPLAY:-:0}"

echo "Turning display on…"

# Method 1: vcgencmd (most reliable on Raspberry Pi)
if command -v vcgencmd >/dev/null 2>&1; then
    vcgencmd display_power 1 2>/dev/null && echo "Display on (vcgencmd)"
fi

# Method 2: xrandr — detect and re-enable the output
if command -v xrandr >/dev/null 2>&1; then
    OUTPUT=$(xrandr --query 2>/dev/null | grep ' connected' | head -1 | awk '{print $1}')
    if [[ -n "$OUTPUT" ]]; then
        xrandr --output "$OUTPUT" --auto 2>/dev/null && echo "Display on (xrandr: $OUTPUT)"
    fi
fi

# Method 3: xset dpms
xset dpms force on  2>/dev/null
xset -dpms          2>/dev/null
xset s off          2>/dev/null
xset s noblank      2>/dev/null

# Ensure slideshow is running (if not already)
if ! pgrep -f "slideshow.sh" >/dev/null 2>&1; then
    echo "Slideshow not running — starting it…"
    nohup bash "$SLIDESHOW_SCRIPT" >/dev/null 2>&1 &
    echo "Slideshow started (PID: $!)"
else
    echo "Slideshow already running"
fi

echo "Done — display is on."
