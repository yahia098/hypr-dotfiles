#!/usr/bin/env bash

CURRENT=$(tlpctl get)

case "$CURRENT" in
    performance)
        echo '{"text":"󰓅","class":"performance","tooltip":"Performance"}'
        ;;
    balanced)
        echo '{"text":"","class":"balanced","tooltip":"Balanced"}'
        ;;
    power-saver)
        echo '{"text":"","class":"power-saver","tooltip":"Power Saver"}'
        ;;
esac
