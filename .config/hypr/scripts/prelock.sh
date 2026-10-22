
#!/usr/bin/env bash
set -euo pipefail
umask 077

STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hypr"
CURRENT_WALLPAPER_FILE="$STATE_DIR/current-wallpaper"
LOCK_IMAGE="/tmp/hyprlock.png"

mkdir -p "$STATE_DIR"

WALLPAPER="${1:-}"

# Discover the active wallpaper when no path was provided.
if [[ -z "$WALLPAPER" ]] && command -v awww >/dev/null 2>&1; then
    WALLPAPER="$(awww query -j 2>/dev/null |
        jq -r '[.. | objects | .displaying? // empty | .image? // empty] | .[0] // empty' 2>/dev/null || true)"
fi

# Fall back to the last wallpaper selected through our wallpaper script.
if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    if [[ -r "$CURRENT_WALLPAPER_FILE" ]]; then
        IFS= read -r WALLPAPER < "$CURRENT_WALLPAPER_FILE" || true
    fi
fi

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    printf 'Error: could not find the current wallpaper.\n' >&2
    exit 1
fi

WALLPAPER="$(realpath -e -- "$WALLPAPER")"

# Save the chosen path atomically for future lock-screen launches.
STATE_TMP="$(mktemp "$STATE_DIR/current-wallpaper.XXXXXX")"
printf '%s\n' "$WALLPAPER" > "$STATE_TMP"
mv -f -- "$STATE_TMP" "$CURRENT_WALLPAPER_FILE"

# Generate the background in /tmp so the final move is atomic.
WORK_DIR="$(mktemp -d /tmp/hyprlock.XXXXXX)"
trap 'rm -rf -- "$WORK_DIR"' EXIT

magick "$WALLPAPER" -blur 0x12 "$WORK_DIR/background.png"
chmod 600 "$WORK_DIR/background.png"
mv -f -- "$WORK_DIR/background.png" "$LOCK_IMAGE"

