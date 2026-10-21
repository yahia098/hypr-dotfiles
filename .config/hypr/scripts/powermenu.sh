#!/usr/bin/env bash

choice=$(
    printf " Shutdown\n󰜉 Reboot\n󰌾 Lock\n󰤄 Suspend\n Logout\n󰑓 Reload Hyprland\n󰸉 Change wallpaper\n󰩡 Change screen freq" |
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
    "󰩡 Change screen freq")
        freq=$(
            printf "1080p 60 Hz\n1080p 144 Hz" |
            wofi --dmenu --prompt "Screen frequency"
        )

        case "$freq" in
            "1080p 60 Hz")
                echo 'hl.monitor({output = "eDP-1",mode = "1920x1080@60",position = "auto",scale = "1",})' > "$HOME/.config/hypr/modules/monitors.lua"
                hyprctl reload
                ;;
            "1080p 144 Hz")
                echo 'hl.monitor({output = "eDP-1",mode = "1920x1080@144",position = "auto",scale = "1",})' > "$HOME/.config/hypr/modules/monitors.lua"
                hyprctl reload
                ;;
        esac
        ;;
esac
