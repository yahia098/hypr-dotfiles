#!/usr/bin/env bash
ws=$(hyprctl activeworkspace -j | jq -r '.id')
count=$(hyprctl clients -j | jq --arg n "special:floating-$ws" \
  '[.[] | select(.workspace.name == $n)] | length')

if grep -qx "$ws" /tmp/hypr-floating-parking 2>/dev/null; then
  echo "{\"text\":\"󰖲 on\",\"class\":\"on\",\"tooltip\":\"Parking floating windows ($count parked)\"}"
else
  echo "{\"text\":\"󰖲 off\",\"class\":\"off\",\"tooltip\":\"Floating windows visible\"}"
fi
