#!/usr/bin/env bash

hyprctl dispatch 'hl.dsp.submap("󰀻 apps")'
 
notify-send \
    "󰀻 Apps" \
    "$(cat ~/.config/hypr/resources/apps.txt)" \
    -t 5000

