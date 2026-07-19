#!/usr/bin/env bash

CURRENT=$(tlpctl get)

case "$CURRENT" in
    performance)
        NEXT="balanced"
        ;;
    balanced)
        NEXT="power-saver"
        ;;
    power-saver)
        NEXT="performance"
        ;;
esac

tlpctl $NEXT
notify-send "Power Profile is: " "$NEXT" -t 800
while [ "$(tlpctl get)" != "$NEXT" ]; do
    sleep 0.05
done

pkill -SIGRTMIN+9 waybar
