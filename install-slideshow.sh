#!/bin/bash
# =============================================================================
# Installer – sets up the slideshow to auto-start on Raspberry Pi boot
# Usage:  sudo bash install-slideshow.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SLIDESHOW_SCRIPT="$SCRIPT_DIR/slideshow.sh"
MEDIA_DIR="${1:-$HOME/slideshow-media}"
USER_NAME="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$USER_NAME")

echo "=== Slideshow Installer ==="
echo "  Script:    $SLIDESHOW_SCRIPT"
echo "  Media dir: $MEDIA_DIR"
echo "  User:      $USER_NAME"
echo ""

# 1. Install dependencies
echo "[1/4] Installing dependencies…"
apt-get update -qq
apt-get install -y -qq feh mpv unclutter

# 2. Create media directory
echo "[2/4] Creating media directory: $MEDIA_DIR"
sudo -u "$USER_NAME" mkdir -p "$MEDIA_DIR"

# 3. Make script executable
echo "[3/4] Making slideshow script executable"
chmod +x "$SLIDESHOW_SCRIPT"

# 4. Create autostart desktop entry (works with LXDE / LXQt / PIXEL desktop)
#    This is the ONLY autostart method — no systemd service, to avoid duplicates.
echo "[4/4] Creating autostart entry"
AUTOSTART_DIR="$USER_HOME/.config/autostart"
sudo -u "$USER_NAME" mkdir -p "$AUTOSTART_DIR"

cat > "$AUTOSTART_DIR/slideshow.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Media Slideshow
Comment=Fullscreen photo and video slideshow
Exec=/bin/bash $SLIDESHOW_SCRIPT
X-GNOME-Autostart-enabled=true
Hidden=false
NoDisplay=false
EOF
chown "$USER_NAME:$USER_NAME" "$AUTOSTART_DIR/slideshow.desktop"

# Remove any previously installed systemd service to avoid double-launch
SERVICE_FILE="$USER_HOME/.config/systemd/user/slideshow.service"
if [[ -f "$SERVICE_FILE" ]]; then
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
echo "  MEDIA_DIR             – folder with media  (default: ~/slideshow-media)"
echo "  IMAGE_DISPLAY_SECS    – seconds per image  (default: 5)"
echo "  SHUFFLE               – randomize order     (default: true)"
echo ""
echo "Manual controls:"
echo "  Start now:   bash $SLIDESHOW_SCRIPT"
echo "  Stop:        pkill -f slideshow.sh"
