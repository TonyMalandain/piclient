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

echo "🚀 Installing Thin Client..."

# 2. Check for Conflicting Display Manager
if systemctl is-enabled display-manager.service &>/dev/null; then
    FOUND_DM=""
    for dm in lightdm gdm gdm3 sddm xdm lxdm slim; do
        if systemctl is-enabled "$dm" &>/dev/null; then
            FOUND_DM="$dm"
            break
        fi
    done
    DM_LABEL="${FOUND_DM:-display-manager}"
    echo "❌ Error: A display manager is already configured on this system (${DM_LABEL})."
    echo "   This script will not install over an existing graphical session manager."
    echo ""
    echo "   To proceed, disable it first:"
    echo "     sudo systemctl disable ${DM_LABEL}"
    echo "     sudo reboot"
    echo ""
    echo "   Then re-run this script on the headless system."
    exit 1
fi

# 3. Install Dependencies
apt-get update
apt-get install -y sway freerdp2-wayland xwayland

# 4. Create Dedicated User
if ! id "$NEW_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$NEW_USER"
fi

# 5. Group Assignment (Hardware Acceleration)
for grp in video input render dialout; do
    if getent group "$grp" >/dev/null; then
        usermod -aG "$grp" "$NEW_USER"
    fi
done

# 6. Create Borderless Sway Config with RESTART LOOP
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

# 7. Configure .bash_profile for Session Lockdown
cat <<EOF > /home/$NEW_USER/.bash_profile
# Replace shell with Sway (no shell to fall back to)
if [[ -z "\$DISPLAY" && "\$(tty)" == /dev/tty1 ]]; then
  exec sway
fi
EOF

# 8. Configure Systemd for Console Auto-Login
GETTY_CONF="/etc/systemd/system/getty@tty1.service.d"
mkdir -p "$GETTY_CONF"
cat <<EOF > "$GETTY_CONF/override.conf"
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $NEW_USER --noclear %I \$TERM
EOF

# 9. Set Permissions
chown -R "$NEW_USER:$NEW_USER" "/home/$NEW_USER/"
chmod +x "/home/$NEW_USER/.bash_profile"

# 10. Generate Uninstall Script
UNINSTALL_SCRIPT="/usr/local/sbin/thinclient-uninstall.sh"
cat <<'UNINSTALL' > "$UNINSTALL_SCRIPT"
#!/bin/bash
set -e

echo "🧹 Uninstalling Raspberry Pi Thin Client..."

# Remove getty autologin override
if [ -d /etc/systemd/system/getty@tty1.service.d ]; then
    rm -rf /etc/systemd/system/getty@tty1.service.d
    echo "  ✔ Removed getty autologin override"
fi

# Remove thinclient user and home directory
if id thinclient &>/dev/null; then
    userdel -r thinclient 2>/dev/null || true
    echo "  ✔ Removed thinclient user"
fi

# Reload systemd
systemctl daemon-reload
systemctl reset-failed

echo ""
echo "📦 Note: The following packages were installed and have NOT been removed:"
echo "     sway, freerdp2-wayland, xwayland"
echo "   Remove them manually if no longer needed:"
echo "     sudo apt-get remove sway freerdp2-wayland xwayland"
echo ""
echo "✅ Thin client removed. Rebooting in 3 seconds..."
rm -f "$0"
sleep 3
reboot
UNINSTALL

chmod +x "$UNINSTALL_SCRIPT"
echo "  ✔ Uninstall script written to $UNINSTALL_SCRIPT"

echo "✨ Setup complete. Rebooting in 3 seconds..."
sleep 3
reboot
