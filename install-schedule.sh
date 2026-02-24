#!/bin/bash
# =============================================================================
# Install cron jobs to sleep/wake the display on a schedule.
# Safe to re-run: removes old entries before adding new ones.
#
# Usage:  bash install-schedule.sh [SLEEP_HOUR] [WAKE_HOUR]
# Example: bash install-schedule.sh 22 8    (sleep at 10pm, wake at 8am)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SLEEP_HOUR="${1:-22}"
WAKE_HOUR="${2:-8}"

SLEEP_CMD="DISPLAY=:0 bash $SCRIPT_DIR/sleep-display.sh"
WAKE_CMD="DISPLAY=:0 bash $SCRIPT_DIR/wake-display.sh"
MARKER="# slideshow-schedule"

echo "=== Display Schedule Installer ==="
echo "  Sleep at: ${SLEEP_HOUR}:00"
echo "  Wake at:  ${WAKE_HOUR}:00"
echo ""

# Remove any previous slideshow-schedule entries, then append new ones
(crontab -l 2>/dev/null | grep -v "$MARKER") | cat - <<EOF | crontab -
0 $SLEEP_HOUR * * * $SLEEP_CMD $MARKER
0 $WAKE_HOUR  * * * $WAKE_CMD  $MARKER
EOF

echo "Cron jobs installed:"
crontab -l | grep "$MARKER"
echo ""
echo "Done. The display will sleep at ${SLEEP_HOUR}:00 and wake at ${WAKE_HOUR}:00 daily."
echo ""
echo "To change the schedule:"
echo "  bash install-schedule.sh 23 7    (sleep at 11pm, wake at 7am)"
echo ""
echo "To remove the schedule:"
echo "  bash uninstall-schedule.sh"
