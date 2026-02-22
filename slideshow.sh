#!/bin/bash
# =============================================================================
# Fullscreen Photo & Video Slideshow for Raspberry Pi
# Loops through all images and videos in a folder on boot.
# =============================================================================

MEDIA_DIR="${MEDIA_DIR:-$HOME/slideshow-media}"
IMAGE_DISPLAY_SECS="${IMAGE_DISPLAY_SECS:-5}"
SHUFFLE="${SHUFFLE:-true}"

SUPPORTED_IMAGES="jpg|jpeg|png|bmp|gif|webp|tiff"
SUPPORTED_VIDEOS="mp4|mkv|avi|mov|wmv|flv|webm|m4v|mpg|mpeg"

log() { echo "[slideshow] $(date '+%H:%M:%S') $*"; }

# ---------------------------------------------------------------------------
# Dependency check / install
# ---------------------------------------------------------------------------
check_deps() {
    local missing=()
    command -v feh   >/dev/null 2>&1 || missing+=(feh)
    command -v mpv   >/dev/null 2>&1 || missing+=(mpv)
    command -v xdotool >/dev/null 2>&1 || missing+=(xdotool)

    if [[ ${#missing[@]} -gt 0 ]]; then
        log "Installing missing packages: ${missing[*]}"
        sudo apt-get update -qq
        sudo apt-get install -y -qq "${missing[@]}"
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
# Disable screen blanking / screensaver so the slideshow stays visible
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
        unclutter -idle 1 -root &
    fi
}

# ---------------------------------------------------------------------------
# Collect media files from MEDIA_DIR
# ---------------------------------------------------------------------------
collect_files() {
    local pattern=".*\\.($SUPPORTED_IMAGES|$SUPPORTED_VIDEOS)$"
    mapfile -t ALL_FILES < <(
        find "$MEDIA_DIR" -maxdepth 2 -type f | grep -iE "$pattern" | sort
    )

    if [[ ${#ALL_FILES[@]} -eq 0 ]]; then
        log "ERROR: No media files found in $MEDIA_DIR"
        exit 1
    fi

    if [[ "$SHUFFLE" == "true" ]]; then
        mapfile -t ALL_FILES < <(printf '%s\n' "${ALL_FILES[@]}" | shuf)
    fi

    log "Found ${#ALL_FILES[@]} media file(s)"
}

# ---------------------------------------------------------------------------
# Determine if a file is an image or a video
# ---------------------------------------------------------------------------
is_image() {
    [[ "${1,,}" =~ \.($SUPPORTED_IMAGES)$ ]]
}

# ---------------------------------------------------------------------------
# Show a single image fullscreen for IMAGE_DISPLAY_SECS
# ---------------------------------------------------------------------------
show_image() {
    log "Image: $(basename "$1") (${IMAGE_DISPLAY_SECS}s)"
    feh --fullscreen --auto-zoom --hide-pointer \
        --on-last-slide quit --slideshow-delay "$IMAGE_DISPLAY_SECS" \
        "$1" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Play a single video fullscreen
# ---------------------------------------------------------------------------
play_video() {
    log "Video: $(basename "$1")"
    mpv --fullscreen --no-osc --no-input-default-bindings \
        --really-quiet --hwdec=auto \
        --loop-file=no "$1" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Main loop – cycle through files forever
# ---------------------------------------------------------------------------
run_slideshow() {
    while true; do
        for f in "${ALL_FILES[@]}"; do
            [[ -f "$f" ]] || continue
            if is_image "$f"; then
                show_image "$f"
            else
                play_video "$f"
            fi
        done

        if [[ "$SHUFFLE" == "true" ]]; then
            mapfile -t ALL_FILES < <(printf '%s\n' "${ALL_FILES[@]}" | shuf)
        fi
        log "Loop complete – restarting slideshow"
    done
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
main() {
    log "Starting slideshow from: $MEDIA_DIR"
    check_deps
    wait_for_display
    disable_screensaver
    hide_cursor
    collect_files
    run_slideshow
}

main "$@"
