# Eww window management and popup orchestration.

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

close_menus() {
    eww close wifi-menu bluetooth-menu audio-menu 2>/dev/null || true
}

menu() {
    local window=$1
    local expand=$2
    local cursor_x monitor_x monitor_width popup_x
    local wifi=false bluetooth=false audio=false
    local audio_outputs=false audio_sources=false
    local width=380

    # Clicking the same module toggles its popup closed.
    if eww active-windows 2>/dev/null | grep -q "^${window}:"; then
        eww close "$window" control-center-closer 2>/dev/null || true
        eww update \
            control_center_expand= \
            wifi_menu_open=false \
            bluetooth_menu_open=false \
            audio_menu_open=false \
            audio_menu_outputs_open=false \
            audio_menu_sources_open=false
        return
    fi

    # Cursor coordinates are global; convert to monitor-0 local coordinates.
    cursor_x=$(hyprctl cursorpos -j 2>/dev/null | jq -er '.x | floor') || return 1
    read -r monitor_x monitor_width < <(
        hyprctl monitors -j 2>/dev/null |
            jq -er '.[0] | [.x, .width] | @tsv'
    ) || return 1

    [[ "$cursor_x" =~ ^-?[0-9]+$ && "$monitor_x" =~ ^-?[0-9]+$ && "$monitor_width" =~ ^[0-9]+$ ]] || return 1

    popup_x=$((cursor_x - monitor_x - width / 2))
    local max_x=$((monitor_width - width - 8))
    (( max_x < 8 )) && max_x=0
    (( popup_x < 8 )) && popup_x=8
    (( popup_x > max_x )) && popup_x=$max_x

    case "$window" in
        wifi-menu) wifi=true ;;
        bluetooth-menu) bluetooth=true ;;
        audio-menu)
            audio=true
            audio_outputs=true
            audio_sources=true
            ;;
        *) return 2 ;;
    esac

    # Do not do cache I/O or query NetworkManager before showing the window.
    # Those operations can block on D-Bus and were on the critical click path.
    close_menus
    eww close control-center control-center-closer 2>/dev/null || true

    eww update \
        control_center_open=false \
        "control_center_expand=$expand" \
        control_center_confirm= \
        "wifi_menu_open=$wifi" \
        "bluetooth_menu_open=$bluetooth" \
        "audio_menu_open=$audio" \
        "audio_menu_outputs_open=$audio_outputs" \
        "audio_menu_sources_open=$audio_sources"

    # Reuse the full-screen transparent click-catcher already used by the
    # main control center. Open it first so the popup stays above it.
    if ! eww open control-center-closer; then
        eww update \
            control_center_expand= \
            wifi_menu_open=false \
            bluetooth_menu_open=false \
            audio_menu_open=false \
            audio_menu_outputs_open=false \
            audio_menu_sources_open=false
        return 1
    fi

    if ! eww open "$window" --arg "popup_x=${popup_x}px"; then
        eww close control-center-closer 2>/dev/null || true
        eww update \
            control_center_expand= \
            wifi_menu_open=false \
            bluetooth_menu_open=false \
            audio_menu_open=false \
            audio_menu_outputs_open=false \
            audio_menu_sources_open=false
        return 1
    fi

    # Hydrate cached data and refresh the selected subsystem only after the
    # popup is visible. Keep Wi-Fi operations sequential to avoid racing nmcli.
    (
        load_cached_state
        case "$window" in
            wifi-menu)
                up control_center_net net_status || true
                net_scan
                ;;
            bluetooth-menu)
                up control_center_bt bt_status || true
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
    if [[ "$1" == close ]] ||
       eww active-windows 2>/dev/null |
           grep -q '^control-center:'; then

        close_menus
        eww close control-center control-center-closer 2>/dev/null || true
        eww update \
            control_center_open=false \
            control_center_expand= \
            control_center_confirm= \
            wifi_menu_open=false \
            bluetooth_menu_open=false \
            audio_menu_open=false \
            audio_menu_outputs_open=false \
            audio_menu_sources_open=false
        return
    fi

    local e=

    case "$1" in
        network|bluetooth)
            e=$1
            ;;
    esac

    close_menus
    eww close control-center-closer 2>/dev/null || true
    eww update \
        control_center_open=true \
        "control_center_expand=$e" \
        control_center_confirm= \
        wifi_menu_open=false \
        bluetooth_menu_open=false \
        audio_menu_open=false \
        audio_menu_outputs_open=false \
        audio_menu_sources_open=false

    # Show the control center before touching cache files or querying devices.
    eww open-many control-center-closer control-center

    # Cache hydration and live polling happen off the click path.
    (
        load_cached_state
        prime
        [[ "$e" == network ]] && net_scan
    ) >/dev/null 2>&1 &
}
