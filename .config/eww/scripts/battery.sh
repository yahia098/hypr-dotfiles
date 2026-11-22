#!/usr/bin/env bash
# Prints battery percentage, or 0 if there is no battery.
f=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)
echo "${f:-0}"
