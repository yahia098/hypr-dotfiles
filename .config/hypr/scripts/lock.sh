
#!/usr/bin/env bash
set -euo pipefail

if ! "$HOME/.config/hypr/scripts/prelock.sh"; then
    printf 'Warning: could not refresh the lock-screen background.\n' >&2
fi

exec hyprlock

