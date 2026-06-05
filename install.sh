#!/usr/bin/env bash
# install.sh — macOS TFTP Manager installer
# Installs tftp-manager, tftp-copy, and the Finder Service

set -euo pipefail

INSTALL_BIN="/usr/local/bin"
INSTALL_SHARE="/usr/local/share/tftp-manager"
SERVICES_DIR="$HOME/Library/Services"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

printf "${BOLD}${CYAN}=== macOS TFTP Manager — Installer ===${NC}\n\n"

# ── Binaries ──────────────────────────────────────────────────────────────────
sudo mkdir -p "$INSTALL_BIN"
printf "→ Installing tftp-manager to %s ...\n" "$INSTALL_BIN"
sudo install -m 0755 "$SCRIPT_DIR/tftp-manager.sh" "$INSTALL_BIN/tftp-manager"

printf "→ Installing tftp-copy to %s ...\n" "$INSTALL_BIN"
sudo install -m 0755 "$SCRIPT_DIR/scripts/tftp-copy.sh" "$INSTALL_BIN/tftp-copy"

# ── Shared data (workflow source for menu option 3) ───────────────────────────
printf "→ Installing shared data to %s ...\n" "$INSTALL_SHARE"
sudo mkdir -p "$INSTALL_SHARE"
sudo cp -R "$SCRIPT_DIR/quick-action" "$INSTALL_SHARE/"

# ── Finder Service ────────────────────────────────────────────────────────────
printf "→ Installing Finder Service to %s ...\n" "$SERVICES_DIR"
mkdir -p "$SERVICES_DIR"
cp -R "$SCRIPT_DIR/quick-action/Copy to TFTP Server.workflow" "$SERVICES_DIR/"
xattr -rd com.apple.quarantine "$SERVICES_DIR/Copy to TFTP Server.workflow" 2>/dev/null || true
LSREG="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
"$LSREG" -f "$SERVICES_DIR/Copy to TFTP Server.workflow" 2>/dev/null || true
killall Finder 2>/dev/null || true

# ── Done ──────────────────────────────────────────────────────────────────────
printf "\n${GREEN}✓ Installation complete!${NC}\n\n"
printf "  • Run ${BOLD}tftp-manager${NC} from any terminal\n"
printf "  • In Finder, right-click a file or folder → ${BOLD}Services${NC} → ${BOLD}Copy to TFTP Server${NC}\n\n"
