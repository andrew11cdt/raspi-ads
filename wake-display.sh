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

# Method 1: xrandr (works on Bookworm with KMS driver)
if command -v xrandr >/dev/null 2>&1; then
    OUTPUT=$(xrandr --query 2>/dev/null | grep ' connected' | head -1 | awk '{print $1}')
    if [[ -n "$OUTPUT" ]]; then
        xrandr --output "$OUTPUT" --auto 2>/dev/null
        echo "Display on (xrandr: $OUTPUT)"
    fi
fi

# Method 2: wlr-randr (Wayland / Wayfire on newer Pi OS)
if command -v wlr-randr >/dev/null 2>&1; then
    OUTPUT=$(wlr-randr 2>/dev/null | grep '^[A-Z]' | head -1 | awk '{print $1}')
    if [[ -n "$OUTPUT" ]]; then
        wlr-randr --output "$OUTPUT" --on 2>/dev/null
        echo "Display on (wlr-randr: $OUTPUT)"
    fi
fi

# Method 3: vcgencmd
if command -v vcgencmd >/dev/null 2>&1; then
    vcgencmd display_power 1 2>/dev/null
fi

# Method 4: xset — re-enable and disable dpms
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
