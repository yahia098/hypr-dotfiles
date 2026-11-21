#!/usr/bin/env bash
# Usage: record.sh full|area   (run again to stop the running recording)
set -euo pipefail

DIR="$HOME/Videos/Recordings"
mkdir -p "$DIR"

# A recording is already running: stop it. gpu-screen-recorder finalises
# the file and the original invocation below reports "saved".
if pkill -INT -f '^(.*/)?gpu-screen-recorder([[:space:]]|$)' 2>/dev/null; then
    exit 0
fi

case "${1:-}" in
    full)
        TARGET=(-w screen)
        ;;
    area)
        notify-send "Select an area..." -t 1000
        REGION="$(slurp -f '%wx%h+%x+%y')" || exit 0
        [[ -n "$REGION" ]] || exit 0
        TARGET=(-w region -region "$REGION")
        ;;
    *)
        echo "Usage: ${0##*/} full|area" >&2
        exit 2
        ;;
esac

FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').mp4"

notify-send "Recording started" -t 1000

if gpu-screen-recorder "${TARGET[@]}" -f 60 -a default_output -o "$FILE"; then
    if [[ -s "$FILE" ]]; then
        notify-send "Recording saved" "$FILE" -t 3000
    else
        notify-send "Recording Error" "No recording file was created" -t 3000
        exit 1
    fi
else
    STATUS=$?
    notify-send "Recording Failed" "gpu-screen-recorder exited with status $STATUS" -t 3000
    exit "$STATUS"
fi
