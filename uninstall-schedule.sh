#!/bin/bash
# =============================================================================
# Remove the sleep/wake cron jobs.
# Usage:  bash uninstall-schedule.sh
# =============================================================================

MARKER="# slideshow-schedule"

echo "Removing sleep/wake cron jobs…"
crontab -l 2>/dev/null | grep -v "$MARKER" | crontab -
echo "Done — no more scheduled sleep/wake."
