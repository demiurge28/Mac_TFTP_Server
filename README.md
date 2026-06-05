# macOS TFTP Server Manager

A Bash CLI and Finder Quick Action for managing macOS's built-in TFTP server (`com.apple.tftpd`).

- **Start/stop** the TFTP daemon from a simple terminal menu
- **Right-click** any file or folder in Finder to copy it straight to the TFTP root
- A new Terminal window opens for every copy so you can watch the transfer live
- `/private/tftpboot` is created on start and deleted on stop — no leftover state

## Quick Start

```bash
# 1. Install
git clone https://github.com/demiurge28/Mac_TFTP_Server.git
cd Mac_TFTP_Server && ./install.sh
# System Settings opens automatically — enable "Copy to TFTP Server" under Finder

# 2. Start the TFTP server
tftp-manager          # choose option 1

# 3. Copy files via terminal (optional)
tftp-copy /path/to/file.bin

# 4. Stop the server and clear /private/tftpboot
tftp-manager          # choose option 2
```

Or skip the terminal entirely — **right-click any file or folder in Finder** and choose **Copy to TFTP Server**. A Terminal window opens, starts the server if needed, and copies the selection.

## Requirements

- macOS Sequoia or later (tested on 26.x)
- Administrator account (several operations require `sudo`)
- Xcode Command Line Tools

Install Xcode Command Line Tools if not already present:

```bash
xcode-select --install
```

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/demiurge28/Mac_TFTP_Server.git
cd Mac_TFTP_Server
```

### 2. Run the installer

```bash
chmod +x install.sh
./install.sh
```

You will be prompted for your administrator password. The installer places the following files:

| File | Location | Purpose |
|------|-----------|---------|
| `tftp-manager` | `/usr/local/bin/tftp-manager` | Interactive CLI menu |
| `tftp-copy` | `/usr/local/bin/tftp-copy` | Quick Action helper script |
| Workflow data | `/usr/local/share/tftp-manager/` | Source for Quick Action reinstall |
| Quick Action | `~/Library/Services/` | Finder right-click service |

Finder restarts automatically so the Quick Action is available immediately.

### 3. Enable the Quick Action in System Settings

The installer opens System Settings automatically at the end of installation. When it opens:

1. Navigate to **Privacy & Security → Extensions → Finder** (if not already there)
2. Enable the toggle next to **Copy to TFTP Server**

This is a one-time step required by macOS for any unsigned software that extends Finder's right-click menu. Once enabled, **Copy to TFTP Server** appears directly in the right-click Quick Actions section and in the Finder preview pane.

> **Already works without this step** — the action is also available immediately under Finder → Services → Copy to TFTP Server (no toggle required).

### 4. Verify

Confirm both commands are on your PATH:

```bash
which tftp-manager   # /usr/local/bin/tftp-manager
which tftp-copy      # /usr/local/bin/tftp-copy
```

## Usage

### CLI — `tftp-manager`

Launch the interactive menu from any terminal:

```bash
tftp-manager
```

The menu shows the current server status at the top and loops after each action until you choose Exit.

```
╔══════════════════════════════════╗
║   macOS TFTP Server Manager      ║
╚══════════════════════════════════╝

  Status: ○ Stopped

  1) Start TFTP Server
  2) Stop TFTP Server
  3) Install Quick Action
  4) Exit

  Enter choice [1-4]:
```

#### Option 1 — Start TFTP Server

1. Creates `/private/tftpboot` with permissions `777`
2. Loads `com.apple.tftpd` via `launchctl`
3. Status updates to **● Running**

You will be prompted for your password if sudo credentials have expired.

#### Option 2 — Stop TFTP Server

1. Unloads `com.apple.tftpd` via `launchctl`
2. Deletes `/private/tftpboot` and all its contents
3. Status updates to **○ Stopped**

> **Warning:** stopping the server removes everything in `/private/tftpboot`. Copy any files you want to keep before stopping.

#### Option 3 — Install / Uninstall Quick Action

This option toggles based on the current state:

- **Install Quick Action** — copies the workflow to `~/Library/Services/`, strips the quarantine attribute, registers it with macOS, and restarts Finder. Use this after a fresh clone or if the service disappears.
- **Uninstall Quick Action** — removes the workflow from `~/Library/Services/` and restarts Finder.

#### Option 4 — Exit

Exits the program. The TFTP server continues running if started.

---

### Finder Quick Action — Copy to TFTP Server

#### Where it appears

Right after `./install.sh` the action is available in:

- **Finder menu bar** → Finder → Services → **Copy to TFTP Server**
- **Right-click context menu** → Services → **Copy to TFTP Server**

To promote it out of the Services submenu and into the **Quick Actions** section directly in the right-click menu (and the Finder preview pane), enable it once in System Settings:

**System Settings → Privacy & Security → Extensions → Finder**

Enable the toggle next to **Copy to TFTP Server**. After that it appears directly in the right-click menu and in the Finder preview pane toolbar.

The installer opens this page for you automatically. `tftp-manager` option 3 also opens it when installing.

> The item only appears when at least one file or folder is selected. It is not visible with an empty selection.

#### How to use it

1. In Finder, select one or more files or folders
2. Right-click → **Copy to TFTP Server** (Quick Actions section, once enabled)
   - Or: Finder menu → Services → **Copy to TFTP Server** (always available without enabling)
3. A Terminal window opens automatically and runs `tftp-copy`
4. When the Terminal shows **Press Enter to close...**, press Enter to dismiss it

You can select multiple files and folders at once — all items are copied in a single operation.

#### What happens in the Terminal window

```
╔══════════════════════════════════╗
║      TFTP Copy Utility           ║
╚══════════════════════════════════╝

→ TFTP server not running — starting...
✓ TFTP server started.  Root: /private/tftpboot

→ Copying to /private/tftpboot:

  firmware.bin
  /private/tftpboot/firmware.bin

✓ Done.  All items are in /private/tftpboot

Press Enter to close...
```

If the server is already running the start step is skipped.

#### About the TFTP daemon state

`com.apple.tftpd` is an **inetd-style** daemon. Once started, `launchd` holds the UDP port 69 socket open permanently. The process itself (`tftpd`) only spawns when an actual TFTP transfer request arrives, then exits after serving it. This means:

- `launchctl print system/com.apple.tftpd` shows `state = not running` — this is **normal and expected**
- `sudo lsof -iUDP:69` shows `launchd` holding `*:tftp` — this confirms the server is **active and listening**
- The TFTP manager status indicator uses `launchctl list com.apple.tftpd` exit code to detect the loaded state

---

## File Structure

```
Mac_TFTP_Server/
├── tftp-manager.sh          # Main CLI script
├── install.sh               # Installer
├── scripts/
│   └── tftp-copy.sh         # Quick Action helper (runs in Terminal)
└── quick-action/
    └── Copy to TFTP Server.workflow/
        └── Contents/
            ├── document.wflow   # Automator workflow definition
            └── Info.plist       # Bundle metadata (required for macOS service registration)
```

## Uninstall

```bash
sudo rm /usr/local/bin/tftp-manager /usr/local/bin/tftp-copy
sudo rm -rf /usr/local/share/tftp-manager
rm -rf "$HOME/Library/Services/Copy to TFTP Server.workflow"
```

## Troubleshooting

**Quick Action does not appear in the right-click menu directly**
Enable it in System Settings → Privacy & Security → Extensions → Finder. It always appears under Finder → Services as a fallback.

**Quick Action is greyed out or does nothing**
Confirm **Copy to TFTP Server** is toggled on in System Settings → Privacy & Security → Extensions → Finder. The toggle must be enabled for the Quick Action section to show it.

**TFTP server shows `state = not running` but should be running**
This is normal. `com.apple.tftpd` is an inetd-style daemon — `launchd` holds the UDP 69 socket and only spawns `tftpd` on an incoming request. Confirm it is listening with:
```bash
sudo lsof -iUDP:69
```

**`launchctl` fails with a permissions error**
Make sure you are running as an administrator account. Standard (non-admin) accounts cannot load system LaunchDaemons.

**Files are not served by the TFTP client**
TFTP requires files to be world-readable. Check permissions with `ls -l /private/tftpboot/`. If needed:
```bash
sudo chmod a+r /private/tftpboot/*
```

**`tftp-manager: command not found`**
Ensure `/usr/local/bin` is on your `PATH`. Add this to `~/.zshrc` if missing:
```bash
export PATH="/usr/local/bin:$PATH"
```
