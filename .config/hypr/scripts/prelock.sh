#!/bin/bash

while true; do
  grim /tmp/hyprlock.png
  magick /tmp/hyprlock.png -blur 0x12 /tmp/hyprlock.png
  sleep 30
done
