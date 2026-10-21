#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="$HOME/.config/wallpapers"
SET_WALLPAPER="$HOME/.config/hypr/scripts/set-wallpaper.sh"

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

mapfile -t COLORS < <(
    matugen image --show-source-colors "$WALLPAPER"
)

((${#COLORS[@]} > 0)) || {
    printf 'Error: Matugen could not extract source colors.\n' >&2
    exit 1
}

COLOR_OPTIONS=""

for i in "${!COLORS[@]}"; do
    COLOR="${COLORS[$i]}"

    if [[ "$COLOR" =~ ^#[[:xdigit:]]{6}$ ]]; then
        COLOR_OPTIONS+="<span background=\"$COLOR\">　　　　　　　　　</span>  $i"$'\n'
    fi
done

SELECTION=$(
    printf '%s' "$COLOR_OPTIONS" |
    wofi --dmenu \
        --prompt "Choose a color" \
        --allow-markup \
        --width 8% \
        --height 15%
)

[[ -n "$SELECTION" ]] || exit 0

SOURCE_COLOR_INDEX="${SELECTION##* }"

"$SET_WALLPAPER" "$WALLPAPER" "$SOURCE_COLOR_INDEX"
