#!/bin/bash
# =============================================================================
# Install cron jobs to sleep/wake the display on a schedule.
# Safe to re-run: removes old entries before adding new ones.
#
# Usage:
#   bash install-schedule.sh <SLEEP_TIME> <WAKE_TIME> [DAYS]
#
# Time format:  HH:MM  (24-hour)
# Days format:  Comma-separated weekday abbreviations or "all"
#               Mon,Tue,Wed,Thu,Fri,Sat,Sun  or  all
#
# Examples:
#   bash install-schedule.sh 22:00 08:00                 (every day)
#   bash install-schedule.sh 22:30 07:45 Mon,Tue,Wed,Thu,Fri  (weekdays)
#   bash install-schedule.sh 23:00 10:00 Sat,Sun         (weekends only)
#   bash install-schedule.sh 18:15 09:00 all             (every day)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SLEEP_CMD="DISPLAY=:0 bash $SCRIPT_DIR/sleep-display.sh"
WAKE_CMD="DISPLAY=:0 bash $SCRIPT_DIR/wake-display.sh"
MARKER="# slideshow-schedule"

# ---------------------------------------------------------------------------
# Parse time string "HH:MM" into hour and minute
# ---------------------------------------------------------------------------
parse_time() {
    local time_str="$1"
    local label="$2"

    if [[ ! "$time_str" =~ ^([0-9]{1,2}):([0-9]{2})$ ]]; then
        echo "ERROR: Invalid $label time '$time_str'. Use HH:MM format (e.g. 22:30)"
        exit 1
    fi

    local hour=$((10#${BASH_REMATCH[1]}))
    local minute=$((10#${BASH_REMATCH[2]}))

    if [[ $hour -gt 23 || $minute -gt 59 ]]; then
        echo "ERROR: $label time '$time_str' out of range."
        exit 1
    fi

    echo "$hour $minute"
}

# ---------------------------------------------------------------------------
# Convert day abbreviations to cron day-of-week numbers
# ---------------------------------------------------------------------------
parse_days() {
    local days_str="${1:-all}"

    if [[ "$days_str" == "all" || -z "$days_str" ]]; then
        echo "*"
        return
    fi

    local cron_days=""
    IFS=',' read -ra DAY_LIST <<< "$days_str"
    for day in "${DAY_LIST[@]}"; do
        case "${day,,}" in
            mon) cron_days+="1," ;;
            tue) cron_days+="2," ;;
            wed) cron_days+="3," ;;
            thu) cron_days+="4," ;;
            fri) cron_days+="5," ;;
            sat) cron_days+="6," ;;
            sun) cron_days+="0," ;;
            *)
                echo "ERROR: Unknown day '$day'. Use: Mon,Tue,Wed,Thu,Fri,Sat,Sun or all"
                exit 1
                ;;
        esac
    done

    # Remove trailing comma
    echo "${cron_days%,}"
}

# ---------------------------------------------------------------------------
# Format cron days back to readable names for display
# ---------------------------------------------------------------------------
format_days() {
    local cron_days="$1"
    if [[ "$cron_days" == "*" ]]; then
        echo "every day"
        return
    fi

    local names=""
    IFS=',' read -ra NUMS <<< "$cron_days"
    for n in "${NUMS[@]}"; do
        case "$n" in
            0) names+="Sun," ;; 1) names+="Mon," ;; 2) names+="Tue," ;;
            3) names+="Wed," ;; 4) names+="Thu," ;; 5) names+="Fri," ;;
            6) names+="Sat," ;;
        esac
    done
    echo "${names%,}"
}

# ---------------------------------------------------------------------------
# Show usage
# ---------------------------------------------------------------------------
usage() {
    echo "Usage: bash install-schedule.sh <SLEEP_TIME> <WAKE_TIME> [DAYS]"
    echo ""
    echo "  SLEEP_TIME   HH:MM  when to turn off display  (e.g. 22:00)"
    echo "  WAKE_TIME    HH:MM  when to turn on display   (e.g. 08:00)"
    echo "  DAYS         Weekdays, comma-separated         (default: all)"
    echo "               Mon,Tue,Wed,Thu,Fri,Sat,Sun or all"
    echo ""
    echo "Examples:"
    echo "  bash install-schedule.sh 22:00 08:00"
    echo "  bash install-schedule.sh 22:30 07:45 Mon,Tue,Wed,Thu,Fri"
    echo "  bash install-schedule.sh 23:00 10:00 Sat,Sun"
    exit 1
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if [[ $# -lt 2 ]]; then
    usage
fi

read -r SLEEP_HOUR SLEEP_MIN <<< "$(parse_time "$1" "sleep")"
read -r WAKE_HOUR WAKE_MIN   <<< "$(parse_time "$2" "wake")"
CRON_DAYS=$(parse_days "${3:-all}")
DAYS_LABEL=$(format_days "$CRON_DAYS")

echo "=== Display Schedule Installer ==="
echo "  Sleep at: $(printf '%02d:%02d' "$SLEEP_HOUR" "$SLEEP_MIN")"
echo "  Wake at:  $(printf '%02d:%02d' "$WAKE_HOUR" "$WAKE_MIN")"
echo "  Days:     $DAYS_LABEL"
echo ""

# Remove old entries, then add new ones
(crontab -l 2>/dev/null | grep -v "$MARKER") | cat - <<EOF | crontab -
$SLEEP_MIN $SLEEP_HOUR * * $CRON_DAYS $SLEEP_CMD $MARKER
$WAKE_MIN $WAKE_HOUR * * $CRON_DAYS $WAKE_CMD $MARKER
EOF

echo "Cron jobs installed:"
crontab -l | grep "$MARKER"
echo ""
echo "Done."
echo ""
echo "To change:  bash install-schedule.sh 23:00 07:30 Mon,Tue,Wed,Thu,Fri"
echo "To remove:  bash uninstall-schedule.sh"
