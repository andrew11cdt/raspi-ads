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

# Method 1: DRM kernel interface
for dpms_file in /sys/class/drm/card*-HDMI-A-*/dpms; do
    if [[ -f "$dpms_file" ]]; then
        echo "On" | sudo tee "$dpms_file" >/dev/null 2>&1
        echo "  HDMI on via $dpms_file"
    fi
done

for status_file in /sys/class/drm/card*-HDMI-A-*/status; do
    enabled_file="${status_file%/status}/enabled"
    if [[ -f "$enabled_file" ]]; then
        echo "enabled" | sudo tee "$enabled_file" >/dev/null 2>&1
        echo "  HDMI enabled via $enabled_file"
    fi
done

# Method 2: xrandr — re-enable the output
if command -v xrandr >/dev/null 2>&1; then
    OUTPUT=$(xrandr --query 2>/dev/null | grep 'HDMI' | head -1 | awk '{print $1}')
    if [[ -n "$OUTPUT" ]]; then
        xrandr --output "$OUTPUT" --auto 2>/dev/null
        echo "  xrandr --output $OUTPUT --auto"
    fi
fi

# Method 3: vcgencmd
if command -v vcgencmd >/dev/null 2>&1; then
    vcgencmd display_power 1 2>/dev/null
fi

# Method 4: xset — disable dpms so display stays on
xset dpms force on  2>/dev/null
xset -dpms          2>/dev/null
xset s off          2>/dev/null
xset s noblank      2>/dev/null

sleep 1

# Restart slideshow (sleep kills feh, so we need a fresh start)
pkill -f "slideshow.sh" 2>/dev/null
rm -f /tmp/slideshow.lock
sleep 0.5
echo "Starting slideshow…"
nohup bash "$SLIDESHOW_SCRIPT" >/dev/null 2>&1 &
echo "Slideshow started (PID: $!)"

echo "Done — display is on."
