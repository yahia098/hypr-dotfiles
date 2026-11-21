#!/usr/bin/env bash
# Usage: brightness.sh up|down
set -euo pipefail

case "${1:-}" in
    up)   brightnessctl set +5% >/dev/null ;;
    down) brightnessctl set 5%- >/dev/null ;;
    *)    echo "Usage: ${0##*/} up|down" >&2; exit 2 ;;
esac

LEVEL="$(brightnessctl -m | awk -F, '{print $4}')"

notify-send -t 500 \
    -h int:value:"${LEVEL%\%}" \
    -h string:x-canonical-private-synchronous:brightness \
    "󰃠 Brightness" "$LEVEL"
