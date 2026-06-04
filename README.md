# macOS TFTP Server Manager

A Bash CLI and Finder Quick Action for managing macOS's built-in TFTP server (`com.apple.tftpd`).

- **Start/stop** the TFTP daemon from a simple terminal menu
- **Right-click** any file or folder in Finder to copy it straight to the TFTP root
- A new Terminal window opens for every copy so you can watch the transfer live
- `/private/tftpboot` is created on start and deleted on stop — no leftover state

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
git clone <repo-url>
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

### 3. Verify

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

#### Option 3 — Install Quick Action

Copies the Finder Quick Action to `~/Library/Services/` and restarts Finder. Use this to reinstall the Quick Action after a macOS update or if it disappears from the right-click menu.

#### Option 4 — Exit

Exits the program. The TFTP server continues running if started.

---

### Finder Quick Action — Copy to TFTP Server

Right-click any file or folder in Finder and select **Copy to TFTP Server**.

![Quick Action in Finder context menu](docs/quick-action-screenshot.png)

A Terminal window opens and runs automatically:

1. Checks if the TFTP server is running; starts it if not
2. Copies each selected item to `/private/tftpboot/` using `cp -Rv` so every file path prints as it is copied
3. Displays a completion message and waits for you to press Enter before closing

Example Terminal output:

```
╔══════════════════════════════════╗
║      TFTP Copy Utility           ║
╚══════════════════════════════════╝

✓ TFTP server is running

→ Copying to /private/tftpboot:

  firmware.bin
  /private/tftpboot/firmware.bin

✓ Done.  All items are in /private/tftpboot

Press Enter to close...
```

You can select multiple files or folders before right-clicking — all selected items are copied in one operation.

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
            └── document.wflow   # Automator workflow definition
```

## Uninstall

```bash
sudo rm /usr/local/bin/tftp-manager /usr/local/bin/tftp-copy
sudo rm -rf /usr/local/share/tftp-manager
rm -rf "$HOME/Library/Services/Copy to TFTP Server.workflow"
```

## Troubleshooting

**Quick Action does not appear in Finder**
Run `tftp-manager`, choose option 3 (Install Quick Action), or log out and back in.

**`launchctl` fails with a permissions error**
Make sure you are running as an administrator account. Standard (non-admin) accounts cannot load system LaunchDaemons.

**Files are not served by the TFTP client**
TFTP requires files to be world-readable. Check permissions with `ls -l /private/tftpboot/`. If needed, run `chmod a+r /private/tftpboot/*` to fix them.

**`tftp-manager: command not found`**
Ensure `/usr/local/bin` is on your `PATH`. Add this to `~/.zshrc` if missing:
```bash
export PATH="/usr/local/bin:$PATH"
```
