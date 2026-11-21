#!/usr/bin/env bash
# Usage: screenshot.sh full|area
set -euo pipefail

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

case "${1:-}" in
    full)
        GRIM_ARGS=()
        ;;
    area)
        # Escape or an empty selection cancels without touching the clipboard.
        REGION="$(slurp)" || exit 0
        [[ -n "$REGION" ]] || exit 0
        GRIM_ARGS=(-g "$REGION")
        ;;
    *)
        echo "Usage: ${0##*/} full|area" >&2
        exit 2
        ;;
esac

FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

grim "${GRIM_ARGS[@]}" "$FILE"
wl-copy < "$FILE"

notify-send "Screenshot" "Saved as ${FILE##*/}" -t 3000
