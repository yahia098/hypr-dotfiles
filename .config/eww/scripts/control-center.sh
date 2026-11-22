#!/usr/bin/env bash
# Eww control-center entry point. Public CLI remains unchanged:
#   win [network|bluetooth|audio|close]
#   wifi|bluetooth|audio
#   net|bt|au|sys|pw <command> [arguments]

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$SCRIPT_DIR/control-center"

# Shared state/helpers first; window functions can call domain functions
# because the dispatcher runs only after every module has been sourced.
source "$MODULE_DIR/common.sh"
source "$MODULE_DIR/windows.sh"
source "$MODULE_DIR/network.sh"
source "$MODULE_DIR/bluetooth.sh"
source "$MODULE_DIR/audio.sh"
source "$MODULE_DIR/system.sh"
source "$MODULE_DIR/power.sh"

case "${1:-}" in
    win)
        win "${2:-}"
        ;;
    wifi)
        menu wifi-menu network
        ;;
    bluetooth)
        menu bluetooth-menu bluetooth
        ;;
    audio)
        menu audio-menu ""
        ;;
    net|bt|au|sys|pw)
        f="${1}_${2:-}"
        if declare -F "$f" >/dev/null; then
            "$f" "${@:3}"
        fi
        ;;
esac
