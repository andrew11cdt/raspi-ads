#!/bin/bash
# =============================================================================
# Turn off the Raspberry Pi display (screen goes black, Pi stays on).
# The slideshow keeps running in the background — nothing is killed.
#
# Usage:  bash sleep-display.sh
# =============================================================================

export DISPLAY="${DISPLAY:-:0}"

echo "Turning display off…"

# Method 1: xrandr (works on Bookworm with KMS driver)
if command -v xrandr >/dev/null 2>&1; then
    OUTPUT=$(xrandr --query 2>/dev/null | grep ' connected' | head -1 | awk '{print $1}')
    if [[ -n "$OUTPUT" ]]; then
        xrandr --output "$OUTPUT" --off 2>/dev/null
        echo "Display off (xrandr: $OUTPUT)"
        exit 0
    fi
fi

# Method 2: wlr-randr (Wayland / Wayfire on newer Pi OS)
if command -v wlr-randr >/dev/null 2>&1; then
    OUTPUT=$(wlr-randr 2>/dev/null | grep '^[A-Z]' | head -1 | awk '{print $1}')
    if [[ -n "$OUTPUT" ]]; then
        wlr-randr --output "$OUTPUT" --off 2>/dev/null
        echo "Display off (wlr-randr: $OUTPUT)"
        exit 0
    fi
fi

# Method 3: vcgencmd — verify it actually worked
if command -v vcgencmd >/dev/null 2>&1; then
    vcgencmd display_power 0 2>/dev/null
    result=$(vcgencmd display_power 2>/dev/null)
    if [[ "$result" == *"display_power=0"* ]]; then
        echo "Display off (vcgencmd)"
        exit 0
    else
        echo "vcgencmd failed ($result), trying next method…"
    fi
fi

# Method 4: xset dpms
xset +dpms 2>/dev/null
xset dpms 1 1 1 2>/dev/null
xset dpms force off 2>/dev/null && echo "Display off (xset)" && exit 0

echo "ERROR: Could not turn off display"
exit 1
