#!/bin/bash
# =============================================================================
# Turn off the Raspberry Pi display (screen goes black, Pi stays on).
# Stops feh so nothing holds the display active, then powers off HDMI.
#
# Usage:  bash sleep-display.sh
# =============================================================================

export DISPLAY="${DISPLAY:-:0}"

echo "Turning display off…"

# Stop feh so it doesn't hold the display active
pkill -x feh 2>/dev/null && echo "  Stopped feh"

sleep 0.5

SUCCESS=false

# Method 1: DRM kernel interface (most reliable on Bookworm with KMS)
for dpms_file in /sys/class/drm/card*-HDMI-A-*/dpms; do
    if [[ -f "$dpms_file" ]]; then
        echo "Off" | sudo tee "$dpms_file" >/dev/null 2>&1
        echo "  HDMI off via $dpms_file"
        SUCCESS=true
    fi
done

for status_file in /sys/class/drm/card*-HDMI-A-*/status; do
    enabled_file="${status_file%/status}/enabled"
    if [[ -f "$enabled_file" ]]; then
        echo "disabled" | sudo tee "$enabled_file" >/dev/null 2>&1
        echo "  HDMI disabled via $enabled_file"
        SUCCESS=true
    fi
done

# Method 2: xset dpms (re-enable dpms first since slideshow disables it)
xset +dpms          2>/dev/null
xset dpms 1 1 1     2>/dev/null
xset dpms force off 2>/dev/null && echo "  xset dpms force off" && SUCCESS=true

# Method 3: vcgencmd
if command -v vcgencmd >/dev/null 2>&1; then
    vcgencmd display_power 0 2>/dev/null
fi

if $SUCCESS; then
    echo "Display is off."
else
    echo "ERROR: Could not turn off display."
    echo "Try: sudo bash sleep-display.sh"
    exit 1
fi
