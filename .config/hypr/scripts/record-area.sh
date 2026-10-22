
#!/usr/bin/env bash
set -euo pipefail

DIR="$HOME/Videos/Recordings"
mkdir -p "$DIR"

# If a recording is already running, stop it.
if pkill -INT -x wf-recorder 2>/dev/null; then
    exit 0
fi

# Ask the user to select the recording area.
notify-send "Select an area..." -t 1000

if ! REGION="$(slurp)"; then
    exit 0
fi

# Escape or an empty selection means cancellation.
[[ -n "$REGION" ]] || exit 0

FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').mp4"

# Record until wf-recorder is interrupted.
if wf-recorder -g "$REGION" -f "$FILE"; then
    if [[ -s "$FILE" ]]; then
        notify-send "Recording saved" "$FILE" -t 3000
    else
        notify-send "Recording Error" "No recording file was created" -t 3000
        exit 1
    fi
else
    STATUS=$?
    notify-send "Recording Failed" "wf-recorder exited with status $STATUS" -t 3000
    exit "$STATUS"
fi

