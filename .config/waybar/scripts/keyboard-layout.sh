#!/usr/bin/env bash

LAYOUT=$(
    hyprctl devices -j |
    jq -r '.keyboards[] | select(.main == true) | .active_keymap'
)

case "$LAYOUT" in
    *Arabic*)
        printf '{"text":"عر","class":"arabic","tooltip":"العربية"}'
        ;;
    *Russian*)
        printf '{"text":"Ру","class":"russian","tooltip":"Русский"}'
        ;;
    *)
        printf '{"text":"EN","class":"english","tooltip":"English"}'
        ;;
esac
