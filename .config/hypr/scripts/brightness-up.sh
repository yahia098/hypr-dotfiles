#!/usr/bin/env bash

brightnessctl set +5%

LEVEL=$(brightnessctl -m | awk -F, '{print $4}')
PERCENT=${LEVEL%\%}

notify-send \
    -t 500 \
    -h int:value:"$PERCENT" \
    -h string:x-canonical-private-synchronous:brightness \
    "󰃠 Brightness" \
    "$LEVEL"
