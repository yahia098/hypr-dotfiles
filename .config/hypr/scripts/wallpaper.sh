#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/.config/wallpapers"

WALLPAPER=$(
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) |
    sort |
    while IFS= read -r file; do
        printf 'img:%s\n' "$file"
    done |
    wofi --dmenu \
        --prompt "Wallpaper" \
        --allow-images \
        --width 45% \
        --height 80% \
        --columns 2 \
        --define "image_size=400"
)

[[ -n "$WALLPAPER" ]] || exit 0

WALLPAPER="${WALLPAPER#img:}"
"$HOME/.config/hypr/scripts/set-wallpaper.sh" "$WALLPAPER"
