#!/usr/bin/env bash

LAYOUT=$(
    hyprctl devices -j |
    jq -r '.keyboards[] | select(.main == true) | .active_keymap'
)

case "$LAYOUT" in
    *Arabic*)
        printf '{"text":"AR","class":"arabic","tooltip":"Arabic"}'
        ;;
    *)
        printf '{"text":"EN","class":"english","tooltip":"English"}'
        ;;
esac
