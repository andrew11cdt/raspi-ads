#!/bin/bash
# =============================================================================
# Installer – sets up the slideshow to auto-start on Raspberry Pi boot
# Safe to re-run: skips steps that are already done.
# Usage:  sudo bash install-slideshow.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SLIDESHOW_SCRIPT="$SCRIPT_DIR/slideshow.sh"
MEDIA_DIR="${1:-$SCRIPT_DIR/media}"
USER_NAME="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$USER_NAME")
AUTOSTART_DIR="$USER_HOME/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/slideshow.desktop"

echo "=== Slideshow Installer ==="
echo "  Script:    $SLIDESHOW_SCRIPT"
echo "  Media dir: $MEDIA_DIR"
echo "  User:      $USER_NAME"
echo ""

# 1. Install dependencies (skip if all already installed)
DEPS=(feh mpv unclutter)
missing=()
for pkg in "${DEPS[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        missing+=("$pkg")
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "[1/4] Installing missing packages: ${missing[*]}"
    apt-get update -qq
    apt-get install -y -qq "${missing[@]}"
else
    echo "[1/4] Dependencies already installed — skipped"
fi

# 2. Create media directory (skip if exists)
if [[ -d "$MEDIA_DIR" ]]; then
    echo "[2/4] Media directory already exists — skipped"
else
    echo "[2/4] Creating media directory: $MEDIA_DIR"
    sudo -u "$USER_NAME" mkdir -p "$MEDIA_DIR"
fi

# 3. Make script executable (skip if already executable)
if [[ -x "$SLIDESHOW_SCRIPT" ]]; then
    echo "[3/4] Script already executable — skipped"
else
    echo "[3/4] Making slideshow script executable"
    chmod +x "$SLIDESHOW_SCRIPT"
fi

# 4. Create autostart desktop entry (skip if identical file exists)
DESKTOP_CONTENT="[Desktop Entry]
Type=Application
Name=Media Slideshow
Comment=Fullscreen photo and video slideshow
Exec=/bin/bash $SLIDESHOW_SCRIPT
X-GNOME-Autostart-enabled=true
Hidden=false
NoDisplay=false"

if [[ -f "$AUTOSTART_FILE" ]] && [[ "$(cat "$AUTOSTART_FILE")" == "$DESKTOP_CONTENT" ]]; then
    echo "[4/4] Autostart entry already exists — skipped"
else
    echo "[4/4] Creating autostart entry"
    sudo -u "$USER_NAME" mkdir -p "$AUTOSTART_DIR"
    echo "$DESKTOP_CONTENT" > "$AUTOSTART_FILE"
    chown "$USER_NAME:$USER_NAME" "$AUTOSTART_FILE"
fi

# Cleanup: remove any previously installed systemd service to avoid double-launch
SERVICE_FILE="$USER_HOME/.config/systemd/user/slideshow.service"
if [[ -f "$SERVICE_FILE" ]]; then
    echo ""
    echo "  Removing old systemd service to prevent duplicate instances…"
    sudo -u "$USER_NAME" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$USER_NAME")/bus" \
        systemctl --user disable slideshow.service 2>/dev/null || true
    rm -f "$SERVICE_FILE"
fi

echo ""
echo "=== Installation complete ==="
echo ""
echo "Next steps:"
echo "  1. Copy your photos/videos into: $MEDIA_DIR"
echo "  2. Reboot:  sudo reboot"
echo ""
echo "Configuration (edit slideshow.sh or set env vars):"
echo "  MEDIA_DIR             – folder with media  (default: <script-dir>/media)"
echo "  IMAGE_DISPLAY_SECS    – seconds per image  (default: 5)"
echo "  SHUFFLE               – randomize order     (default: true)"
echo ""
echo "Manual controls:"
echo "  Start now:   bash $SLIDESHOW_SCRIPT"
echo "  Stop:        pkill -f slideshow.sh"
