#!/usr/bin/env bash

choice=$(
    printf " Shutdown\n󰜉 Reboot\n󰌾 Lock\n󰤄 Suspend\n Logout" |
    fuzzel --dmenu --prompt "Power"
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
esac
