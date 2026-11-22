#!/usr/bin/env bash

for f in /sys/class/power_supply/BAT*/capacity; do
    if [[ -r "$f" ]]; then
        IFS= read -r capacity < "$f"
        [[ "$capacity" =~ ^[0-9]+$ ]] && {
            printf '%s\n' "$capacity"
            exit 0
        }
    fi
done

printf '0\n'

