# Brightness reads and TLP power-profile operations.
# (Slider writes live in the fast path in control-center.sh.)

bl() {
    if [[ -n "$BL_DEVICE" ]]; then
        brightnessctl -d "$BL_DEVICE" "$@"
    else
        brightnessctl "$@"
    fi
}

sys_getbright() {
    bl -m 2>/dev/null |
        awk -F, 'NF >= 5 {gsub("%", "", $4); print $4; exit}'
}

sys_status() {
    local b profile

    b=$(sys_getbright)
    # "unknown" highlights nothing instead of pretending to be "balanced".
    profile=$(tlpctl get 2>/dev/null) || profile=unknown

    jq -nc --arg p "$profile" --argjson b "${b:-0}" \
        '{profile:$p,brightness:$b}'
}

sys_prof() {
    case "$1" in
        power-saver|balanced|performance)
            tlpctl  "$1" || return 1
            pkill -RTMIN+9 waybar 2>/dev/null
            up control_center_sys sys_status
            ;;
        *)
            return 1
            ;;
    esac
}
