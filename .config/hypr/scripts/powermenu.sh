#!/usr/bin/env bash

choice=$(
    printf " Shutdown\n󰜉 Reboot\n󰌾 Lock\n󰤄 Suspend\n Logout\n󰑓 Reload Hyprland\n󰸉 Change wallpaper" |
    wofi --dmenu --prompt "Power"
)

case "$choice" in
    " Shutdown")
        systemctl poweroff
        ;;
    "󰜉 Reboot")
        systemctl reboot
        ;;
    "󰌾 Lock")
        hyprlock
        ;;
    "󰤄 Suspend")
        systemctl suspend
        ;;
    " Logout")
        hyprctl dispatch 'hl.dsp.exit()'
        ;;
    "󰑓 Reload Hyprland")
        hyprctl reload
        ;;
    "󰸉 Change wallpaper")
        "$HOME/.config/hypr/scripts/wallpaper.sh"
        ;;
esac
