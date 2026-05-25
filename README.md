## **Raspberry Pi Wayland Thin Client Setup**

This guide provides a resilient, borderless, and locked-down RDP thin client setup for Raspberry Pi OS. It uses Sway (Wayland) to manage a single, infinite RDP session that automatically restarts if closed or crashed.

## ---

**Installation Command**

Run this command on a fresh installation of Raspberry Pi OS Lite. Replace the placeholders with your remote machine's details.

```bash
curl -sSL https://raw.githubusercontent.com/TonyMalandain/piclient/refs/heads/main/setup.sh | sudo bash -s -- <REMOTE_IP> <USERNAME> <PASSWORD>
```

## ---

**Setup Script**

The full setup script is in [`setup.sh`](setup.sh). No manual edits are needed — all configuration is passed as arguments at runtime.

## ---

**Features**

* **Zero Borders**: Sway is configured to strip all window decorations and frames.  
* **Zombie Protection**: A background while loop ensures the RDP client respawns if killed.  
* **Shell Erasure**: The exec sway command replaces the login shell, preventing users from dropping to a terminal.  
* **Standard User**: Runs as a non-privileged user (thinclient) for better security.  
* **Wayland Native**: Uses wlfreerdp for high-performance hardware acceleration on the Pi.

If you need to perform maintenance on the Pi, plug in a keyboard and press **Ctrl+Alt+F2** to switch to a different TTY and log in with your administrative user.

## ---

**Uninstalling**

The setup script creates an uninstall script at `/usr/local/sbin/thinclient-uninstall.sh`.

To revert the thin client setup:

1. Press **Ctrl+Alt+F2** to switch to a free TTY
2. Log in with your administrative user
3. Run:

```bash
sudo /usr/local/sbin/thinclient-uninstall.sh
```

The script will:
- Remove the `thinclient` user and its home directory
- Remove the TTY1 autologin override
- Reboot the system

> **Note:** Installed packages (`sway`, `freerdp2-wayland`) are left in place. Remove them manually if no longer needed:
> ```bash
> sudo apt-get remove sway freerdp2-wayland
> ```
