#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Positional arguments
REMOTE_IP=$1
REMOTE_USER=$2
REMOTE_PASS=$3
NEW_USER="thinclient"

# 1. Validation
if [ -z "$REMOTE_IP" ] || [ -z "$REMOTE_USER" ] || [ -z "$REMOTE_PASS" ]; then
    echo "❌ Error: Missing arguments."
    echo "Usage: curl ... | sudo bash -s -- <IP> <USER> <PASS>"
    exit 1
fi

echo "🚀 Starting Resilient Thin Client Setup..."

# 2. Install Dependencies
apt-get update
apt-get install -y sway freerdp2-wayland xwayland agetty

# 3. Create Dedicated User
if ! id "$NEW_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$NEW_USER"
fi

# 4. Group Assignment (Hardware Acceleration)
for grp in video input render dialout; do
    if getent group "$grp" >/dev/null; then
        usermod -aG "$grp" "$NEW_USER"
    fi
done

# 5. Create Borderless Sway Config with RESTART LOOP
CONFIG_DIR="/home/$NEW_USER/.config/sway"
mkdir -p "$CONFIG_DIR"

cat <<EOF > "$CONFIG_DIR/config"
# --- BORDERLESS MANAGEMENT ---
default_border none
default_floating_border none
font pango:monospace 0
titlebar_border_thickness 0
for_window [app_id=".*"] border pixel 0

# UI Lockdown
bar mode hide

# The Infinite RDP Loop: Respawns if closed or crashed
exec bash -c "while true; do wlfreerdp /v:$REMOTE_IP /u:$REMOTE_USER /p:$REMOTE_PASS /f /cert-ignore /network:auto; sleep 2; done"

# Security: Disable ability to exit Sway or open terminal
unbindsym \$mod+Shift+e
unbindsym \$mod+Return
EOF

# 6. Configure .bash_profile for Session Lockdown
cat <<EOF > /home/$NEW_USER/.bash_profile
# Replace shell with Sway (no shell to fall back to)
if [[ -z "\$DISPLAY" && "\$(tty)" == /dev/tty1 ]]; then
  exec sway
fi
EOF

# 7. Configure Systemd for Console Auto-Login
GETTY_CONF="/etc/systemd/system/getty@tty1.service.d"
mkdir -p "$GETTY_CONF"
cat <<EOF > "$GETTY_CONF/override.conf"
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $NEW_USER --noclear %I \$TERM
EOF

# 8. Set Permissions
chown -R "$NEW_USER:$NEW_USER" "/home/$NEW_USER/"
chmod +x "/home/$NEW_USER/.bash_profile"

echo "✨ Setup complete. Rebooting in 3 seconds..."
sleep 3
reboot
