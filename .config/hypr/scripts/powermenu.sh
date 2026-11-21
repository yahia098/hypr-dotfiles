#!/usr/bin/env bash
set -euo pipefail

SCRIPTS="$HOME/.config/hypr/scripts"

choice="$(
    printf '%s\n' \
        " Shutdown" \
        "󰜉 Reboot" \
        "󰌾 Lock" \
        "󰤄 Suspend" \
        " Logout" \
        "󰑓 Reload Hyprland" \
        "󰸉 Change wallpaper" \
        "󰩡 Displays" |
    wofi --dmenu --prompt "Power"
)" || exit 0

case "$choice" in
    *Shutdown)         systemctl poweroff ;;
    *Reboot)           systemctl reboot ;;
    *Lock)             exec "$SCRIPTS/lock.sh" ;;
    *Suspend)          systemctl suspend ;;
    *Logout)           hyprctl dispatch 'hl.dsp.exit()' ;;
    *"Reload Hyprland") hyprctl reload ;;
    *"Change wallpaper") exec "$SCRIPTS/wallpaper-picker.sh" ;;
    *Displays)         exec "$SCRIPTS/displays.sh" ;;
esac
