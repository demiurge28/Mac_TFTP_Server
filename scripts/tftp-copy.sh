#!/usr/bin/env bash
# tftp-copy — called by the Finder Service inside a new Terminal window
# Usage: tftp-copy <file_or_folder> [<file_or_folder> ...]

PLIST="/System/Library/LaunchDaemons/tftp.plist"
TFTPBOOT="/private/tftpboot"
SERVICE="com.apple.tftpd"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

printf "${BOLD}${CYAN}╔══════════════════════════════════╗${NC}\n"
printf "${BOLD}${CYAN}║      TFTP Copy Utility           ║${NC}\n"
printf "${BOLD}${CYAN}╚══════════════════════════════════╝${NC}\n"
printf "\n"

if [ $# -eq 0 ]; then
    printf "${RED}✗ No files specified.${NC}\n"
    printf "\nPress Enter to close..."
    read -r
    exit 1
fi

# ── Start TFTP if not running ─────────────────────────────────────────────────
if sudo launchctl list "$SERVICE" &>/dev/null 2>&1; then
    printf "${GREEN}✓ TFTP server is running${NC}\n"
else
    printf "→ TFTP server not running — starting...\n"
    sudo mkdir -p "$TFTPBOOT"
    sudo chmod 777 "$TFTPBOOT"
    if sudo launchctl load -w "$PLIST"; then
        printf "${GREEN}✓ TFTP server started.  Root: %s${NC}\n" "$TFTPBOOT"
    else
        printf "${RED}✗ Failed to start TFTP server. Aborting copy.${NC}\n"
        printf "\nPress Enter to close..."
        read -r
        exit 1
    fi
fi

printf "\n"

# ── Copy each item ────────────────────────────────────────────────────────────
printf "→ Copying to %s:\n\n" "$TFTPBOOT"

for item in "$@"; do
    printf "${BOLD}  %s${NC}\n" "$(basename "$item")"
    sudo cp -Rv "$item" "$TFTPBOOT/"
    printf "\n"
done

printf "${GREEN}✓ Done.  All items are in %s${NC}\n" "$TFTPBOOT"
printf "\nPress Enter to close..."
read -r
