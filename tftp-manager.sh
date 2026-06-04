#!/usr/bin/env bash
# tftp-manager — macOS TFTP Server Manager
# Manages com.apple.tftpd and the Finder Quick Action

PLIST="/System/Library/LaunchDaemons/tftp.plist"
TFTPBOOT="/private/tftpboot"
SERVICE="com.apple.tftpd"

# Locate the workflow — works from the repo dir or from /usr/local/bin/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKFLOW_SRC="$SCRIPT_DIR/quick-action/Copy to TFTP Server.workflow"
if [ ! -d "$WORKFLOW_SRC" ]; then
    WORKFLOW_SRC="/usr/local/share/tftp-manager/quick-action/Copy to TFTP Server.workflow"
fi

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
is_running() {
    sudo launchctl list "$SERVICE" &>/dev/null 2>&1
}

print_status() {
    if is_running; then
        printf "  Status: ${GREEN}● Running${NC}   root: %s\n" "$TFTPBOOT"
    else
        printf "  Status: ${RED}○ Stopped${NC}\n"
    fi
}

print_header() {
    clear
    printf "${BOLD}${CYAN}╔══════════════════════════════════╗${NC}\n"
    printf "${BOLD}${CYAN}║   macOS TFTP Server Manager      ║${NC}\n"
    printf "${BOLD}${CYAN}╚══════════════════════════════════╝${NC}\n"
    printf "\n"
    print_status
}

pause() {
    printf "\n  Press Enter to continue..."
    read -r
}

# ── Actions ───────────────────────────────────────────────────────────────────
start_tftp() {
    if is_running; then
        printf "${YELLOW}→ TFTP is already running.${NC}\n"
        return
    fi
    printf "→ Creating %s ...\n" "$TFTPBOOT"
    sudo mkdir -p "$TFTPBOOT"
    sudo chmod 777 "$TFTPBOOT"
    printf "→ Starting TFTP server...\n"
    if sudo launchctl load -w "$PLIST"; then
        printf "${GREEN}✓ TFTP started.  Root: %s${NC}\n" "$TFTPBOOT"
    else
        printf "${RED}✗ Failed to start TFTP. Check Console.app for launchd errors.${NC}\n"
    fi
}

stop_tftp() {
    if ! is_running; then
        printf "${YELLOW}→ TFTP is not running.${NC}\n"
        return
    fi
    printf "→ Stopping TFTP server...\n"
    if sudo launchctl unload -w "$PLIST"; then
        printf "→ Removing %s ...\n" "$TFTPBOOT"
        sudo rm -rf "$TFTPBOOT"
        printf "${GREEN}✓ TFTP stopped and %s removed.${NC}\n" "$TFTPBOOT"
    else
        printf "${RED}✗ Failed to stop TFTP. Check Console.app for launchd errors.${NC}\n"
    fi
}

install_quick_action() {
    if [ ! -d "$WORKFLOW_SRC" ]; then
        printf "${RED}✗ Workflow not found at:\n  %s${NC}\n" "$WORKFLOW_SRC"
        printf "  Run ./install.sh first, or run this script from the project directory.\n"
        return 1
    fi
    SERVICES_DIR="$HOME/Library/Services"
    mkdir -p "$SERVICES_DIR"
    cp -R "$WORKFLOW_SRC" "$SERVICES_DIR/"
    killall Finder 2>/dev/null || true
    printf "${GREEN}✓ Quick Action installed to ~/Library/Services/${NC}\n"
    printf "  Right-click any file or folder in Finder → Copy to TFTP Server\n"
}

# ── Menu ──────────────────────────────────────────────────────────────────────
show_menu() {
    printf "\n"
    printf "  ${BOLD}1)${NC} Start TFTP Server\n"
    printf "  ${BOLD}2)${NC} Stop TFTP Server\n"
    printf "  ${BOLD}3)${NC} Install Quick Action\n"
    printf "  ${BOLD}4)${NC} Exit\n"
    printf "\n"
    printf "  Enter choice [1-4]: "
}

main() {
    while true; do
        print_header
        show_menu
        read -r choice
        printf "\n"
        case "$choice" in
            1) start_tftp   ;;
            2) stop_tftp    ;;
            3) install_quick_action ;;
            4) printf "Goodbye.\n"; exit 0 ;;
            *) printf "${YELLOW}Invalid option — enter 1, 2, 3, or 4.${NC}\n" ;;
        esac
        pause
    done
}

main
