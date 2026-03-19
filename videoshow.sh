#!/bin/bash
# =============================================================================
# Fullscreen Video Player for Raspberry Pi
# Loops through all videos in the media/ folder. Plays fullscreen on boot.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEDIA_DIR="${MEDIA_DIR:-$SCRIPT_DIR/media}"
SHUFFLE="${SHUFFLE:-false}"
LOOP_SINGLE="${LOOP_SINGLE:-false}"

SUPPORTED_VIDEOS="mp4|mkv|avi|mov|wmv|flv|webm|m4v|mpg|mpeg"
LOCK_FILE="/tmp/videoshow.lock"

log() { echo "[videoshow] $(date '+%H:%M:%S') $*"; }

# ---------------------------------------------------------------------------
# Prevent multiple instances from running at the same time
# ---------------------------------------------------------------------------
acquire_lock() {
    exec 200>"$LOCK_FILE"
    if ! flock -n 200; then
        log "Another videoshow instance is already running – exiting."
        exit 0
    fi
}

# ---------------------------------------------------------------------------
# Dependency check / install
# ---------------------------------------------------------------------------
check_deps() {
    if ! command -v mpv >/dev/null 2>&1; then
        log "Installing mpv…"
        sudo apt-get update -qq
        sudo apt-get install -y -qq mpv
    fi
}

# ---------------------------------------------------------------------------
# Wait for the X display to be ready (important at boot)
# ---------------------------------------------------------------------------
wait_for_display() {
    local retries=30
    while [[ -z "${DISPLAY:-}" ]] && [[ $retries -gt 0 ]]; do
        if [[ -e /tmp/.X11-unix/X0 ]]; then
            export DISPLAY=:0
            break
        fi
        log "Waiting for X display… ($retries)"
        sleep 2
        ((retries--))
    done
    export DISPLAY="${DISPLAY:-:0}"
}

# ---------------------------------------------------------------------------
# Disable screen blanking / screensaver
# ---------------------------------------------------------------------------
disable_screensaver() {
    xset s off      2>/dev/null
    xset -dpms      2>/dev/null
    xset s noblank  2>/dev/null
}

# ---------------------------------------------------------------------------
# Hide the mouse cursor after 1 second of inactivity
# ---------------------------------------------------------------------------
hide_cursor() {
    if command -v unclutter >/dev/null 2>&1; then
        pkill -x unclutter 2>/dev/null || true
        unclutter -idle 1 -root &
    fi
}

# ---------------------------------------------------------------------------
# Clean up child processes on exit
# ---------------------------------------------------------------------------
cleanup() {
    log "Stopping videoshow"
    pkill -P $$ 2>/dev/null || true
    rm -f "$LOCK_FILE"
    exit 0
}
trap cleanup EXIT INT TERM

# ---------------------------------------------------------------------------
# Collect video files from MEDIA_DIR
# ---------------------------------------------------------------------------
collect_files() {
    local pattern=".*\\.($SUPPORTED_VIDEOS)$"
    mapfile -t ALL_FILES < <(
        find "$MEDIA_DIR" -maxdepth 2 -type f | grep -iE "$pattern" | sort
    )

    if [[ ${#ALL_FILES[@]} -eq 0 ]]; then
        log "ERROR: No video files found in $MEDIA_DIR — waiting 30s and retrying…"
        sleep 30
        collect_files
        return
    fi

    if [[ "$SHUFFLE" == "true" ]]; then
        mapfile -t ALL_FILES < <(printf '%s\n' "${ALL_FILES[@]}" | shuf)
    fi

    log "Found ${#ALL_FILES[@]} video(s)"
}

# ---------------------------------------------------------------------------
# Play a single video fullscreen
# ---------------------------------------------------------------------------
play_video() {
    log "Playing: $(basename "$1")"
    local loop_flag="no"
    [[ "$LOOP_SINGLE" == "true" ]] && loop_flag="inf"

    mpv --fullscreen --no-osc --no-input-default-bindings \
        --really-quiet --hwdec=auto \
        --loop-file="$loop_flag" -- "$1" >/dev/null 2>&1 || true
}

# ---------------------------------------------------------------------------
# Main loop – play all videos, then restart the playlist forever
# ---------------------------------------------------------------------------
run_videoshow() {
    if [[ ${#ALL_FILES[@]} -eq 1 ]]; then
        log "Single video — looping forever"
        LOOP_SINGLE=true
        play_video "${ALL_FILES[0]}"
        return
    fi

    while true; do
        for f in "${ALL_FILES[@]}"; do
            [[ -f "$f" ]] || continue
            play_video "$f"
        done

        if [[ "$SHUFFLE" == "true" ]]; then
            mapfile -t ALL_FILES < <(printf '%s\n' "${ALL_FILES[@]}" | shuf)
        fi
        log "Playlist complete – restarting"
    done
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
main() {
    acquire_lock
    log "Starting videoshow from: $MEDIA_DIR"
    check_deps
    wait_for_display
    disable_screensaver
    hide_cursor
    collect_files
    run_videoshow
}

main "$@"
