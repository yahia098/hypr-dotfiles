
#!/usr/bin/env bash
set -euo pipefail

# Read the main keyboard's active layout.
if ! LAYOUT="$(hyprctl devices -j | jq -er '.keyboards[] | select(.main == true) | .active_keymap')"; then
    printf '%s\n' '{"text":"?","class":"unknown","tooltip":"Could not read keyboard layout"}'
    exit 0
fi

case "$LAYOUT" in
    *Arabic*)
        printf '%s\n' '{"text":"عر","class":"arabic","tooltip":"العربية"}'
        ;;
    *Russian*)
        printf '%s\n' '{"text":"Ру","class":"russian","tooltip":"Русский"}'
        ;;
    *)
        printf '%s\n' '{"text":"EN","class":"english","tooltip":"English"}'
        ;;
esac

