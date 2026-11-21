#!/usr/bin/env bash
# The one entry point for locking: makes sure the blurred background exists,
# then starts hyprlock. Used by the keybind, the power menu and hypridle.
set -euo pipefail

# Already locked.
pidof hyprlock >/dev/null && exit 0

# The blurred background is already refreshed at login and on every wallpaper
# change. Only rebuild it here if it is missing (e.g. /tmp was cleared), so
# locking stays instant, which matters when the lock must be up before suspend.
if [[ ! -s /tmp/hyprlock.png ]]; then
    "$HOME/.config/hypr/scripts/prelock.sh" ||
        printf 'Warning: could not create the lock-screen background.\n' >&2
fi

exec hyprlock
