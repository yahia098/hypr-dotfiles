# Eww window management and popup orchestration.

close_all() { "$SCRIPT_DIR/cc-close.sh"; }

prime() {
    up control_center_net net_status &
    up control_center_bt bt_status &
    up control_center_audio au_status &
    up control_center_vol_sink au_getvol sink &
    up control_center_vol_source au_getvol source &
    up control_center_sys sys_status &
    up control_center_bright sys_getbright &
    wait
}

# Prints "name x logical_width" of the focused monitor (first one if none is).
focused_monitor() {
    hyprctl monitors -j 2>/dev/null | jq -er '
        (map(select(.focused)) + .)[0]
        | [.name, .x, ((.width / (.scale // 1)) | floor)] | @tsv'
}

menu() {
    local window=$1 expand=$2
    local mon mx mw cx px max_x
    local width=380 wifi=false bluetooth=false audio=false

    # Clicking the same module again closes its popup.
    if eww active-windows 2>/dev/null | grep -q "^${window}:"; then
        close_all
        return
    fi

    read -r mon mx mw < <(focused_monitor) || return 1
    cx=$(hyprctl cursorpos -j 2>/dev/null | jq -er '.x | floor') || return 1
    [[ -n "$mon" && "$mx" =~ ^-?[0-9]+$ && "$mw" =~ ^[0-9]+$ && "$cx" =~ ^-?[0-9]+$ ]] || return 1

    # Logical (scale-corrected) coordinates, local to the focused monitor.
    px=$((cx - mx - width / 2))
    max_x=$((mw - width - 8))
    (( max_x < 8 )) && max_x=8
    (( px > max_x )) && px=$max_x
    (( px < 8 )) && px=8

    case "$window" in
        wifi-menu)      wifi=true ;;
        bluetooth-menu) bluetooth=true ;;
        audio-menu)     audio=true ;;
        *) return 2 ;;
    esac

    close_all
    eww update \
        "control_center_expand=$expand" \
        "wifi_menu_open=$wifi" \
        "bluetooth_menu_open=$bluetooth" \
        "audio_menu_open=$audio" \
        "audio_menu_outputs_open=$audio" \
        "audio_menu_sources_open=$audio"

    # Click-catcher first so the popup sits above it.
    eww open control-center-closer --screen "$mon" || { close_all; return 1; }
    eww open "$window" --screen "$mon" --arg "popup_x=${px}px" || { close_all; return 1; }

    # Hydrate and refresh after the popup is already visible.
    (
        load_cached_state
        case "$window" in
            wifi-menu)
                up control_center_net net_status || true
                net_scan
                ;;
            bluetooth-menu)
                up control_center_bt bt_status || true
                bt_scan
                ;;
            audio-menu)
                up control_center_audio au_status || true
                up control_center_vol_sink au_getvol sink || true
                up control_center_vol_source au_getvol source || true
                ;;
        esac
    ) >/dev/null 2>&1 &
}

win() {
    local e= mon mx mw

    case "$1" in
        close) close_all; return ;;
        audio) menu audio-menu ""; return ;;
        network|bluetooth) e=$1 ;;
    esac

    if eww active-windows 2>/dev/null | grep -q '^control-center:'; then
        close_all
        return
    fi

    read -r mon mx mw < <(focused_monitor) || mon=

    close_all
    eww update control_center_open=true "control_center_expand=$e"

    if [[ -n "$mon" ]]; then
        eww open control-center-closer --screen "$mon"
        eww open control-center --screen "$mon"
    else
        eww open-many control-center-closer control-center
    fi

    (
        load_cached_state
        prime
        [[ "$e" == network ]] && net_scan
        [[ "$e" == bluetooth ]] && bt_scan
    ) >/dev/null 2>&1 &
}
