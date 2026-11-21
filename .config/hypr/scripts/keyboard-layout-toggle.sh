
#!/usr/bin/env bash
set -euo pipefail

# Switch every keyboard to its next configured layout.
if ! hyprctl switchxkblayout all next; then
    notify-send "Keyboard Error" "Could not switch keyboard layout"
    exit 1
fi

# Read the same main keyboard that Waybar uses.
if ! LAYOUT="$(hyprctl devices -j | jq -er '.keyboards[] | select(.main == true) | .active_keymap')"; then
    notify-send "Keyboard Error" "Could not read the active keyboard layout"
    exit 1
fi

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

# Refresh Waybar's custom/keyboard module (signal 8).
pkill -RTMIN+8 waybar || true

