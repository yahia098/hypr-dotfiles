#!/usr/bin/env bash
# Fast close: no module loading. Used by the click-catcher and the power actions.
eww close wifi-menu bluetooth-menu audio-menu control-center control-center-closer >/dev/null 2>&1
eww update \
    control_center_open=false control_center_expand= control_center_confirm= \
    wifi_menu_open=false bluetooth_menu_open=false audio_menu_open=false \
    audio_menu_outputs_open=false audio_menu_sources_open=false \
    wifi_pw_ssid= 'wifi_pw_list=[]' wifi_pw_show=false \
    wifi_busy=false wifi_msg= wifi_msg_err=false wifi_test= bt_msg= bt_msg_err=false >/dev/null 2>&1
exit 0
