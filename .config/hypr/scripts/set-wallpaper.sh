
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

WALLPAPER="$(realpath -e -- "$WALLPAPER")"

awww img "$WALLPAPER" --resize fit

# Store the selected wallpaper path for the lock screen.
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hypr"
mkdir -p "$CACHE_DIR"

STATE_TMP="$(mktemp "$CACHE_DIR/current-wallpaper.XXXXXX")"
printf '%s\n' "$WALLPAPER" > "$STATE_TMP"
mv -f -- "$STATE_TMP" "$CACHE_DIR/current-wallpaper"

# Refresh the lock background without blocking Matugen on failure.
if ! "$HOME/.config/hypr/scripts/prelock.sh" "$WALLPAPER"; then
    printf 'Warning: could not refresh the lock-screen background.\n' >&2
fi

matugen image "$WALLPAPER" --type scheme-smart --source-color-index "$SOURCE_COLOR_INDEX"
hyprctl reload

