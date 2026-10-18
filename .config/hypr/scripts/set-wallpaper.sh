#!/usr/bin/env bash
set -euo pipefail

WALLPAPER="${1:?Usage: set-wallpaper.sh /path/to/image}"

awww img "$WALLPAPER" --resize fit ;
matugen image "$WALLPAPER" --source-color-index 1 &
sleep 0.1 ;
hyprctl reload ;

