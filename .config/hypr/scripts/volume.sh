#!/usr/bin/env bash
# Usage: volume.sh up|down|toggle
set -euo pipefail

SINK='@DEFAULT_AUDIO_SINK@'

case "${1:-}" in
    up)     wpctl set-volume --limit 1.0 "$SINK" 5%+ ;;
    down)   wpctl set-volume "$SINK" 5%- ;;
    toggle) wpctl set-mute "$SINK" toggle ;;
    *)      echo "Usage: ${0##*/} up|down|toggle" >&2; exit 2 ;;
esac

STATUS="$(wpctl get-volume "$SINK")"
VOL="$(awk '{print int($2 * 100)}' <<< "$STATUS")"

if [[ "$STATUS" == *MUTED* ]]; then
    ICON="󰝟"; BODY="Muted"
else
    ICON="󰕾"; BODY="$VOL%"
fi

notify-send -t 500 \
    -h int:value:"$VOL" \
    -h string:x-canonical-private-synchronous:volume \
    "$ICON Volume" "$BODY"
