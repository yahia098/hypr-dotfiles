#!/usr/bin/env bash
# Battery state watcher for Hyprland + Dunst.
set -uo pipefail

POLL_INTERVAL=10

command -v notify-send >/dev/null 2>&1 || {
    echo "battery-watch: install libnotify" >&2
    exit 1
}

command -v flock >/dev/null 2>&1 || {
    echo "battery-watch: flock is missing" >&2
    exit 1
}

# Find the battery.
BATTERY=""
for supply in /sys/class/power_supply/BAT*; do
    [[ -r "$supply/capacity" && -r "$supply/status" ]] || continue
    BATTERY="$supply"
    break
done

if [[ -z "$BATTERY" ]]; then
    echo "battery-watch: no battery found" >&2
    exit 1
fi

# Prevent duplicate watchers after Hyprland reloads.
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
INSTANCE="${HYPRLAND_INSTANCE_SIGNATURE:-${UID:-user}}"

exec 9>"$RUNTIME_DIR/hypr-battery-watch-$INSTANCE.lock"
flock -n 9 || exit 0

# Notification helper.
notify() {
    local urgency="$1"
    local timeout="$2"
    local icon="$3"
    local title="$4"
    local body="$5"

    notify-send \
        --app-name="Battery Watch" \
        --urgency="$urgency" \
        --expire-time="$timeout" \
        --icon="$icon" \
        "$title" "$body" || true
}

# Read battery percentage and status.
read_battery() {
    local capacity status

    IFS= read -r capacity < "$BATTERY/capacity" || return 1
    IFS= read -r status < "$BATTERY/status" || return 1

    [[ "$capacity" =~ ^[0-9]+$ ]] || return 1

    CAPACITY="$capacity"
    STATUS="$status"
}

# Detect AC adapter connection.
read_ac_state() {
    local supply type_name online
    local found=0 connected=0

    for supply in /sys/class/power_supply/*; do
        [[ -r "$supply/type" && -r "$supply/online" ]] || continue

        IFS= read -r type_name < "$supply/type" || continue
        [[ "$type_name" == "Mains" ]] || continue

        found=1
        IFS= read -r online < "$supply/online" || continue

        [[ "$online" == "1" ]] && connected=1
    done

    if (( found )); then
        AC_ONLINE="$connected"
    else
        # Fallback if no Mains device exposes an online attribute.
        case "$STATUS" in
            Charging|Full) AC_ONLINE=1 ;;
            *) AC_ONLINE=0 ;;
        esac
    fi
}

is_full() {
    [[ "$STATUS" == "Full" ]] ||
        { (( AC_ONLINE == 1 && CAPACITY >= 100 )); }
}

# Give Dunst time to start.
sleep 1

LOW15_SENT=0
LOW5_SENT=0
FULL_SENT=0

FIRST_RUN=1
PREV_STATUS=""
PREV_AC=-1

while true; do
    if ! read_battery; then
        sleep "$POLL_INTERVAL"
        continue
    fi

    read_ac_state

    # Initial state when the watcher starts.
    if (( FIRST_RUN )); then
        if (( AC_ONLINE )); then
            if is_full; then
                notify normal 3000 battery-full \
                    "Battery full" "$CAPACITY% • AC power connected"
                FULL_SENT=1

            elif [[ "$STATUS" == "Charging" ]]; then
                notify normal 3000 battery-charging \
                    "Charging" "AC power connected • $CAPACITY%"

            else
                notify normal 3000 battery \
                    "AC power connected" \
                    "Battery is not charging • $CAPACITY% ($STATUS)"
            fi

        elif [[ "$STATUS" == "Full" ]]; then
            notify normal 3000 battery-full \
                "Battery full" "$CAPACITY%"
            FULL_SENT=1
        fi

        FIRST_RUN=0

    else
        # Charger connected or disconnected.
        if (( AC_ONLINE != PREV_AC )); then
            if (( AC_ONLINE )); then
                if is_full; then
                    notify normal 3000 battery-full \
                        "Power connected" "Battery is already full • $CAPACITY%"
                    FULL_SENT=1

                elif [[ "$STATUS" == "Charging" ]]; then
                    notify normal 3000 battery-charging \
                        "Charging started" "AC power connected • $CAPACITY%"

                else
                    notify normal 3000 battery \
                        "Power connected" \
                        "Battery is not charging • $CAPACITY% ($STATUS)"
                fi
            else
                notify normal 3000 battery \
                    "Charger disconnected" \
                    "No longer charging • running on battery ($CAPACITY%)"

                FULL_SENT=0
            fi

        # Battery state changed without an AC connection transition.
        elif [[ "$STATUS" != "$PREV_STATUS" ]]; then
            case "$STATUS" in
                Charging)
                    notify normal 3000 battery-charging \
                        "Charging started" "Battery charging • $CAPACITY%"
                    ;;

                Discharging)
                    if [[ "$PREV_STATUS" == "Charging" ||
                          "$PREV_STATUS" == "Full" ]]; then
                        notify normal 3000 battery \
                            "No longer charging" "Running on battery • $CAPACITY%"
                    fi
                    FULL_SENT=0
                    ;;

                "Not charging")
                    if [[ "$PREV_STATUS" == "Charging" ]]; then
                        notify normal 3000 battery \
                            "Charging paused" \
                            "Power connected, but battery is not charging • $CAPACITY%"
                    fi
                    ;;

                Full)
                    # Handled below.
                    ;;
            esac
        fi
    fi

    # Full notification, only once per full-charge event.
    if is_full; then
        if (( ! FULL_SENT )); then
            notify normal 3000 battery-full \
                "Battery full" "$CAPACITY% • charging complete"
            FULL_SENT=1
        fi
    else
        FULL_SENT=0
    fi

    # Hysteresis prevents repeated warnings around threshold boundaries.
    (( CAPACITY >= 18 )) && LOW15_SENT=0
    (( CAPACITY >= 8 )) && LOW5_SENT=0

    # Critical battery warnings.
    if (( CAPACITY <= 5 && ! LOW5_SENT )); then
        notify critical 0 battery-empty \
            "CRITICAL BATTERY — 5%" \
            "Connect the charger now. Only $CAPACITY% remains."

        LOW5_SENT=1
        LOW15_SENT=1

    elif (( CAPACITY <= 15 && ! LOW15_SENT )); then
        notify critical 0 battery-low \
            "LOW BATTERY — 15%" \
            "Connect your charger soon. $CAPACITY% remaining."

        LOW15_SENT=1
    fi

    PREV_STATUS="$STATUS"
    PREV_AC="$AC_ONLINE"

    sleep "$POLL_INTERVAL"
done
