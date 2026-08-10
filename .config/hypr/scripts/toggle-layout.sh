#!/usr/bin/env bash

hyprctl switchxkblayout all next

LAYOUT=$(hyprctl devices -j | jq -r '.keyboards[0].active_keymap')

case "$LAYOUT" in
    *Arabic*)
        ICON="󰌌"
        TEXT="العربية"
        ;;
    *Russian*)
        ICON="󰌌"
        TEXT="Русский"
        ;;
    *)
        ICON="󰌌"
        TEXT="English"
        ;;
esac

notify-send \
    -t 500 \
    -h string:x-canonical-private-synchronous:keyboard \
    "$ICON Keyboard" \
    "$TEXT"

pkill -RTMIN+8 waybar
