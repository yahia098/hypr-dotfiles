#!/usr/bin/env bash

CONF="$HOME/.config/hypr/modules/monitors.lua"
STATE="$HOME/.config/hypr/monitors.state"   # lines: name|mode|position|disabled|scale
INTERNAL="eDP-1"
FALLBACK_MODE="1920x1080@144"

mkdir -p "$(dirname "$STATE")"
touch "$STATE"

declare -A MODE POS DIS SCALE

monitors_json() { hyprctl monitors all -j; }

load_state() {
    while IFS='|' read -r n m p d s; do
        [ -z "$n" ] && continue
        MODE[$n]=$m; POS[$n]=$p; DIS[$n]=$d; SCALE[$n]=${s:-1}
    done < "$STATE"
}

save_state() {
    : > "$STATE"
    for n in "${!MODE[@]}"; do
        echo "$n|${MODE[$n]}|${POS[$n]}|${DIS[$n]}|${SCALE[$n]:-1}" >> "$STATE"
    done
}

# every connected monitor gets an entry (internal panel defaults to 1080p 144)
ensure_entries() {
    local n
    for n in $(monitors_json | jq -r '.[].name'); do
        [ -n "${MODE[$n]}" ] && continue
        if [ "$n" = "$INTERNAL" ]; then MODE[$n]=$FALLBACK_MODE; else MODE[$n]=preferred; fi
        POS[$n]=auto
        DIS[$n]=0
        SCALE[$n]=1
    done
}

generate() {
    ensure_entries
    mapfile -t connected < <(monitors_json | jq -r '.[].name')

    local external=0 active=0 n
    for n in "${connected[@]}"; do
        [ "$n" != "$INTERNAL" ] && external=1
        [ "${DIS[$n]}" != 1 ] && active=$((active + 1))
    done

    # no external monitor (or nothing left enabled): internal panel comes back
    if [ "$external" -eq 0 ] || [ "$active" -eq 0 ]; then
        if [ "${DIS[$INTERNAL]}" = 1 ]; then
            DIS[$INTERNAL]=0
            MODE[$INTERNAL]=$FALLBACK_MODE
        fi
    fi

    local new
    new=$(
        for n in $(printf '%s\n' "${!MODE[@]}" | LC_ALL=C sort); do
            if [ "${DIS[$n]}" = 1 ]; then
                echo "hl.monitor({ output = \"$n\", disabled = true })"
            else
                echo "hl.monitor({ output = \"$n\", mode = \"${MODE[$n]}\", position = \"${POS[$n]}\", scale = \"${SCALE[$n]:-1}\" })"
            fi
        done
        # any monitor without its own rule
        echo 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "1" })'
    )

    # skip if nothing changed (prevents reload loops in --watch mode)
    [ "$new" = "$(cat "$CONF" 2>/dev/null)" ] && return
    echo "$new" > "$CONF"
    hyprctl reload
}

modes_for() {
    monitors_json |
    jq -r --arg m "$1" '.[] | select(.name == $m) | .availableModes[]' |
    awk -F'[@H]' '{printf "%s@%d\n", $1, $2 + 0.5}' |
    awk '!seen[$0]++'
}

others_enabled() {
    monitors_json |
    jq -r --arg m "$1" '[.[] | select(.name != $m and (.disabled | not))] | length'
}

menu() {
    local sel name action m p s
    sel=$(
        {
            monitors_json | jq -r '.[] | "\(.name)  \(.width)x\(.height)@\(.refreshRate | round)  " + (if .disabled then "OFF" else "ON" end)'
            echo "Reset to defaults"
        } | wofi --dmenu --prompt "Monitor"
    )
    [ -z "$sel" ] && return

    if [ "$sel" = "Reset to defaults" ]; then
        : > "$STATE"
        MODE=(); POS=(); DIS=(); SCALE=()
        generate
        return
    fi

    name=${sel%% *}
    local toggle="Disable"
    [ "${DIS[$name]}" = 1 ] && toggle="Enable"

    action=$(printf "Set mode\nSet scale\nSet position\n%s" "$toggle" | wofi --dmenu --prompt "$name")

    case "$action" in
        "Set mode")
            m=$(modes_for "$name" | wofi --dmenu --prompt "$name mode")
            [ -z "$m" ] && return
            MODE[$name]=$m
            DIS[$name]=0
            ;;
        "Set scale")
            s=$(printf "auto\n1\n1.25\n1.5\n2\n2.5\n3" | wofi --dmenu --prompt "$name scale")
            [ -z "$s" ] && return
            SCALE[$name]=$s
            ;;
        "Set position")
            p=$(printf "auto\nauto-left\nauto-right\nauto-up\nauto-down" | wofi --dmenu --prompt "$name position")
            [ -z "$p" ] && return
            POS[$name]=$p
            ;;
        Disable)
            if [ "$(others_enabled "$name")" -eq 0 ]; then
                notify-send "Monitors" "Can't disable the only active monitor"
                return
            fi
            DIS[$name]=1
            ;;
        Enable)
            DIS[$name]=0
            ;;
        *) return ;;
    esac

    save_state
    generate
}

load_state
ensure_entries

case "$1" in
    --auto)
        generate
        ;;
    --watch)
        generate
        socat -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - |
        while read -r line; do
            case "$line" in
                monitoradded*|monitorremoved*)
                    sleep 0.5
                    load_state
                    generate
                    ;;
            esac
        done
        ;;
    *)
        menu
        ;;
esac
