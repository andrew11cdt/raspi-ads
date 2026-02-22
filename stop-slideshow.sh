#!/bin/bash
# =============================================================================
# Emergency stop — kills the slideshow and all related processes
# Usage:  bash stop-slideshow.sh
# =============================================================================

echo "Stopping slideshow…"

pkill -f "slideshow.sh" 2>/dev/null
pkill -f "feh --fullscreen" 2>/dev/null
pkill -f "mpv --fullscreen" 2>/dev/null
pkill -x feh 2>/dev/null
pkill -x mpv 2>/dev/null
pkill -x unclutter 2>/dev/null

rm -f /tmp/slideshow.lock

# Disable autostart so it won't come back after reboot
AUTOSTART_FILE="$HOME/.config/autostart/slideshow.desktop"
if [[ -f "$AUTOSTART_FILE" ]]; then
    mv "$AUTOSTART_FILE" "$AUTOSTART_FILE.disabled"
    echo "Autostart disabled (renamed to slideshow.desktop.disabled)"
fi

echo "Done. Slideshow is stopped and won't restart on reboot."
echo ""
echo "To re-enable autostart later:"
echo "  mv ~/.config/autostart/slideshow.desktop.disabled ~/.config/autostart/slideshow.desktop"
