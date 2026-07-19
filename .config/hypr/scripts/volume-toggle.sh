#!/usr/bin/env bash

wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

STATUS=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)

if echo "$STATUS" | grep -q MUTED; then
    notify-send \
        -t 500 \
        -h string:x-canonical-private-synchronous:volume \
        "󰝟 Volume" \
        "Muted"
else
    VOL=$(awk '{print int($2*100)}' <<< "$STATUS")
    notify-send \
        -t 500 \
        -h int:value:$VOL \
        -h string:x-canonical-private-synchronous:volume \
        "󰕾 Volume" \
        "$VOL%"
fi
