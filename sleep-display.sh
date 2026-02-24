#!/bin/bash
# =============================================================================
# Turn off the Raspberry Pi display (screen goes black, Pi stays on).
# The slideshow keeps running in the background — nothing is killed.
#
# Usage:  bash sleep-display.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

export DISPLAY="${DISPLAY:-:0}"

echo "Turning display off…"

# Method 1: vcgencmd (most reliable on Raspberry Pi)
if command -v vcgencmd >/dev/null 2>&1; then
    vcgencmd display_power 0 2>/dev/null && echo "Display off (vcgencmd)" && exit 0
fi

# Method 2: xrandr
if command -v xrandr >/dev/null 2>&1; then
    OUTPUT=$(xrandr --query 2>/dev/null | grep ' connected' | head -1 | awk '{print $1}')
    if [[ -n "$OUTPUT" ]]; then
        xrandr --output "$OUTPUT" --off 2>/dev/null && echo "Display off (xrandr: $OUTPUT)" && exit 0
    fi
fi

# Method 3: xset dpms
xset +dpms 2>/dev/null
xset dpms force off 2>/dev/null && echo "Display off (xset)" && exit 0

echo "ERROR: Could not turn off display"
exit 1
