# Raspberry Pi Thin Client Setup

Turn any Raspberry Pi into a **zero-maintenance thin client** that boots straight into a remote Windows or Linux desktop — with a single command.

## Why bother?

Got a spare Raspberry Pi gathering dust? Instead of buying dedicated thin-client hardware, repurpose that Pi and connect it to a central server you already own. All the heavy lifting happens on the server; the Pi is just a screen, keyboard, and mouse.

**The real benefit is centralization.** When all your computing lives on one server:

- 📁 **Files are safe** — store everything on a server with RAID, backups, and no risk of a lost or broken Pi taking data with it.
- 🔄 **One machine to maintain** — update software, install apps, and manage accounts in a single place instead of touching every device.
- 👤 **User management in one shot** — add, remove, or restrict users on the server; the Pi just shows whatever that user is allowed to see.
- 👧 **Give kids their own computer without losing control** — each child gets a Pi and their own account. Enforce GNOME parental controls, screen-time limits, and content filters entirely from the server. The Pi itself is a locked-down appliance they cannot break or circumvent.

The Pi boots directly into the remote session. There is no desktop to escape to, no files stored locally, and no way to accidentally (or intentionally) mess with the device. If anything goes wrong with the Pi, unplug it, plug in a new one, and run one command.

---

## Installation

Run this command on a fresh installation of Raspberry Pi OS Lite. Replace the placeholders with your remote machine's details.

```bash
curl -sSL https://raw.githubusercontent.com/TonyMalandain/piclient/refs/heads/main/setup.sh | sudo bash -s -- <REMOTE_IP> <USERNAME> <PASSWORD>
```

---

## Setup Script

The full setup script is in [`setup.sh`](setup.sh). No manual edits are needed — all configuration is passed as arguments at runtime.

---

## Features

* **Zero Borders** — Sway is configured to strip all window decorations and frames.
* **Zombie Protection** — A background while loop ensures the RDP client respawns if killed.
* **Shell Erasure** — The `exec sway` command replaces the login shell, preventing users from dropping to a terminal.
* **Standard User** — Runs as a non-privileged user (`thinclient`) for better security.
* **Wayland Native** — Uses `wlfreerdp` for high-performance hardware acceleration on the Pi.

If you need to perform maintenance on the Pi, plug in a keyboard and press **Ctrl+Alt+F2** to switch to a different TTY and log in with your administrative user.

---

## Local Development

To test changes without pushing to GitHub, run a local HTTP server from your dev machine:

```bash
chmod +x serve.sh
./serve.sh
```

The script will print a ready-to-use `curl` command — copy it, run it on the Pi:

```bash
curl -sSL http://<DEV_MACHINE_IP>:8080/setup.sh | sudo bash -s -- <REMOTE_IP> <USERNAME> <PASSWORD>
```

By default the server listens on port `8080`. Pass a different port as an argument if needed:

```bash
./serve.sh 9090
```

---

## Uninstalling

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
