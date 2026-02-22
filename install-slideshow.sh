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
echo "[1/5] Installing dependencies…"
apt-get update -qq
apt-get install -y -qq feh mpv xdotool unclutter

# 2. Create media directory
echo "[2/5] Creating media directory: $MEDIA_DIR"
sudo -u "$USER_NAME" mkdir -p "$MEDIA_DIR"

# 3. Make script executable
echo "[3/5] Making slideshow script executable"
chmod +x "$SLIDESHOW_SCRIPT"

# 4. Create autostart desktop entry (works with LXDE / LXQt / PIXEL desktop)
echo "[4/5] Creating autostart entry"
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

# 5. Also create a systemd user service as a fallback
echo "[5/5] Creating systemd user service (fallback)"
SERVICE_DIR="$USER_HOME/.config/systemd/user"
sudo -u "$USER_NAME" mkdir -p "$SERVICE_DIR"

cat > "$SERVICE_DIR/slideshow.service" <<EOF
[Unit]
Description=Fullscreen Photo & Video Slideshow
After=graphical-session.target

[Service]
Type=simple
Environment=DISPLAY=:0
Environment=XAUTHORITY=$USER_HOME/.Xauthority
Environment=MEDIA_DIR=$MEDIA_DIR
ExecStart=/bin/bash $SLIDESHOW_SCRIPT
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
chown "$USER_NAME:$USER_NAME" "$SERVICE_DIR/slideshow.service"

# Enable the service for the user
sudo -u "$USER_NAME" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$USER_NAME")/bus" \
    systemctl --user enable slideshow.service 2>/dev/null || true

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
