#!/usr/bin/env bash

for z in /sys/class/thermal/thermal_zone*; do
    [[ -r "$z/type" && -r "$z/temp" ]] || continue

    IFS= read -r type < "$z/type"

    case "$type" in
        x86_pkg_temp|k10temp|cpu*|coretemp)
            IFS= read -r temp < "$z/temp"
            if [[ "$temp" =~ ^[0-9]+$ ]]; then
                printf '%s\n' "$((temp / 1000))"
                exit 0
            fi
            ;;
    esac
done

if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
    IFS= read -r temp < /sys/class/thermal/thermal_zone0/temp
elif [[ -r /sys/class/hwmon/hwmon0/temp1_input ]]; then
    IFS= read -r temp < /sys/class/hwmon/hwmon0/temp1_input
else
    printf '0\n'
    exit 0
fi

if [[ "$temp" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$((temp / 1000))"
else
    printf '0\n'
fi
