
#!/usr/bin/env bash
set -euo pipefail

DIR="$HOME/Videos/Recordings"
mkdir -p "$DIR"

# If a recording is already running, stop it.
if pkill -INT -x wf-recorder 2>/dev/null; then
    exit 0
fi

FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').mp4"

notify-send "Recording started" -t 1000

# Record the full screen until wf-recorder is interrupted.
if wf-recorder -f "$FILE"; then
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

