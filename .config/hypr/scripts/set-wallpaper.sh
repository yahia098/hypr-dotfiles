#!/usr/bin/env bash
set -euo pipefail

WALLPAPER="${1:?Usage: set-wallpaper.sh /path/to/image [source-color-index]}"
SOURCE_COLOR_INDEX="${2:-1}"

[[ -f "$WALLPAPER" ]] || {
    printf 'Error: wallpaper not found: %s\n' "$WALLPAPER" >&2
    exit 1
}

[[ "$SOURCE_COLOR_INDEX" =~ ^[0-4]$ ]] || {
    printf 'Error: source-color index must be between 0 and 4\n' >&2
    exit 1
}

awww img "$WALLPAPER" --resize fit
matugen image "$WALLPAPER" --type scheme-smart --source-color-index "$SOURCE_COLOR_INDEX"
hyprctl reload
