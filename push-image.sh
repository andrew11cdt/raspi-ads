#!/bin/bash
# =============================================================================
# Push an image to the Raspberry Pi – replaces the displayed image live.
# Run this from your local machine (not the Pi).
#
# Usage:  bash push-image.sh <image-file> [pi-address]
# Example: bash push-image.sh flyer.jpg 192.168.1.50
#          bash push-image.sh banner.png pi@raspberrypi.local
# =============================================================================

set -euo pipefail

IMAGE_FILE="${1:-}"
PI_HOST="${2:-pi@raspberrypi.local}"
REMOTE_MEDIA_DIR="~/slideshow-media"

if [[ -z "$IMAGE_FILE" ]]; then
    echo "Usage: bash push-image.sh <image-file> [user@pi-address]"
    echo ""
    echo "Examples:"
    echo "  bash push-image.sh photo.jpg pi@192.168.1.50"
    echo "  bash push-image.sh ad.png pi@raspberrypi.local"
    exit 1
fi

if [[ ! -f "$IMAGE_FILE" ]]; then
    echo "ERROR: File not found: $IMAGE_FILE"
    exit 1
fi

REMOTE_FIRST_IMAGE=$(ssh "$PI_HOST" "ls $REMOTE_MEDIA_DIR/*.{jpg,jpeg,png,bmp,gif,webp,tiff} 2>/dev/null | head -1")

if [[ -z "$REMOTE_FIRST_IMAGE" ]]; then
    echo "No existing image found on Pi. Uploading as display.jpg …"
    REMOTE_FIRST_IMAGE="$REMOTE_MEDIA_DIR/display.jpg"
fi

echo "Pushing: $IMAGE_FILE"
echo "     To: $PI_HOST:$REMOTE_FIRST_IMAGE"

scp "$IMAGE_FILE" "$PI_HOST:$REMOTE_FIRST_IMAGE"

echo "Done — the Pi display will update within 1 second."
