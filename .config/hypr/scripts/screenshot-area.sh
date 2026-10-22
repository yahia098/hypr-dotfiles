
#!/usr/bin/env bash
set -euo pipefail

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

# Let Escape cancel without saving or changing the clipboard.
if ! REGION="$(slurp)"; then
    exit 0
fi

# Also handle an empty selection.
[[ -n "$REGION" ]] || exit 0

FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

# Stop if the screenshot could not be created.
grim -g "$REGION" "$FILE"

# Copy only a successfully created screenshot.
wl-copy < "$FILE"

notify-send "Screenshot" "Saved as $(basename "$FILE")" -t 300

