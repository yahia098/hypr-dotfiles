#!/usr/bin/env bash
wpctl set-volume --limit 1.0 @DEFAULT_AUDIO_SINK@ 5%+

VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')

notify-send \
    -t 500 \
    -h int:value:$VOL \
    -h string:x-canonical-private-synchronous:volume \
    "Volume" \
    "$VOL%"
