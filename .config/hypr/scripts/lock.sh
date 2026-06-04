#!/bin/bash

# if file is too old (>2 min), refresh once
if [ ! -f /tmp/hyprlock.png ] || [ $(find /tmp/hyprlock.png -mmin +2 2>/dev/null) ]; then
  grim /tmp/hyprlock.png
  magick /tmp/hyprlock.png -blur 0x12 /tmp/hyprlock.png
fi

hyprlock
