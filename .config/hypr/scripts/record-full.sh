#!/usr/bin/env bash

DIR="$HOME/Videos/Recordings"
mkdir -p "$DIR"

FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').mp4"

pkill -INT wf-recorder 2>/dev/null && exit 0

notify-send "Recording started"

wf-recorder -f "$FILE"

notify-send "Recording saved" "$FILE"
