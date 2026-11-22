# Brightness and TLP power-profile operations.

bl() {
    if [[ -n "$BL_DEVICE" ]]; then
        brightnessctl -d "$BL_DEVICE" "$@"
    else
        brightnessctl "$@"
    fi
}

sys_getbright() {
    # brightnessctl -m fields: device,class,current,max,percentage
    bl -m 2>/dev/null |
        awk -F, 'NF >= 5 {gsub("%", "", $5); print $5; exit}'
}

sys_status() {
    local b profile

    b=$(sys_getbright)
    profile=$(tlpctl get 2>/dev/null || echo balanced)

    jq -nc \
        --arg p "$profile" \
        --argjson b "${b:-0}" \
        '{profile:$p,brightness:$b}'
}

sys_bright() {
    [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1

    local v
    v=$(printf '%.0f' "$1" 2>/dev/null) || return 1

    (( v < 1 )) && v=1
    (( v > 100 )) && v=100

    bl -q set "${v}%"

    eww update "control_center_bright=$v" \
        >/dev/null 2>&1
}

sys_prof() {
    case "$1" in
        power-saver|balanced|performance)
            tlpctl set "$1" || return 1
            pkill -RTMIN+9 waybar 2>/dev/null
            up control_center_sys sys_status
            ;;
        *)
            return 1
            ;;
    esac
}
