
#!/usr/bin/env bash
set -euo pipefail

if ! command -v tlpctl >/dev/null 2>&1; then
    notify-send "Power Profile Error" "tlpctl is not installed"
    exit 1
fi

if ! CURRENT="$(tlpctl get)"; then
    notify-send "Power Profile Error" "Could not read the current profile"
    exit 1
fi

case "$CURRENT" in
    performance)
        NEXT="balanced"
        ;;
    balanced)
        NEXT="power-saver"
        ;;
    power-saver)
        NEXT="performance"
        ;;
    *)
        notify-send "Power Profile Error" "Unknown current profile: $CURRENT"
        exit 1
        ;;
esac

if ! tlpctl "$NEXT"; then
    notify-send "Power Profile Error" "Could not switch to $NEXT"
    exit 1
fi

# Wait up to 2 seconds for the new profile to become active.
for _ in {1..40}; do
    if ! CURRENT="$(tlpctl get)"; then
        notify-send "Power Profile Error" "Could not verify the new profile"
        exit 1
    fi

    if [[ "$CURRENT" == "$NEXT" ]]; then
        notify-send "Power Profile" "Profile: $NEXT" -t 2000
        pkill -SIGRTMIN+9 waybar || true
        exit 0
    fi

    sleep 0.05
done

notify-send "Power Profile Error" \
    "Timed out waiting for $NEXT; current profile: $CURRENT"
exit 1

