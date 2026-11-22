# NetworkManager / Wi-Fi operations.

net_status() {
    local wifi=false
    local kind=none
    local ssid=
    local signal=0
    local ip=
    local dev=
    local title sub radio line result

    # `nmcli radio wifi` reports enabled/disabled. If NetworkManager is not
    # answering, preserve the last valid status instead of inventing "off".
    radio=$(nmcli -t radio wifi 2>/dev/null) || radio=
    case "$radio" in
        enabled) wifi=true ;;
        disabled) wifi=false ;;
        *)
            cache_read net-status && return 0
            printf '%s\n' '{"wifi":false,"kind":"none","title":"Wi-Fi","sub":"Unavailable"}'
            return 0
            ;;
    esac

    # Look for an actually connected Wi-Fi interface first. Do not infer a
    # connection from the radio being enabled or from a scan result existing.
    dev=$(
        nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null |
            awk -F: '$2 == "wifi" && ($3 == "connected" || $3 ~ /^connected /) { print $1; exit }'
    )

    if [[ -n "$dev" ]]; then
        kind=wifi

        # The AP list's active marker is IN-USE="*" (not ACTIVE="yes").
        # With --escape no, reconstruct SSIDs containing colons safely by
        # removing only the first and final colon-delimited fields.
        line=$(
            nmcli -t -e no -f IN-USE,SSID,SIGNAL device wifi list 2>/dev/null |
                awk -F: '$1 == "*" { print; exit }'
        )

        if [[ -n "$line" ]]; then
            signal=${line##*:}
            ssid=${line#*:}
            ssid=${ssid%:*}
        else
            # During startup/resume the AP list may not yet have its active
            # marker. The active connection name is a useful temporary label.
            ssid=$(nmcli -g GENERAL.CONNECTION device show "$dev" 2>/dev/null | head -n1)
            signal=0
        fi

        [[ -n "$ssid" ]] || ssid="Connected Wi-Fi"
    else
        dev=$(
            nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null |
                awk -F: '$2 == "ethernet" && ($3 == "connected" || $3 ~ /^connected /) { print $1; exit }'
        )
        [[ -n "$dev" ]] && kind=ethernet
    fi

    if [[ -n "$dev" ]]; then
        ip=$(nmcli -g IP4.ADDRESS device show "$dev" 2>/dev/null |
            head -n1 | cut -d/ -f1)
    fi

    case "$kind" in
        wifi)
            title=$ssid
            if [[ -n "$ip" ]]; then
                sub="$ip · ${signal}%"
            else
                sub="Connected · ${signal}%"
            fi
            ;;
        ethernet)
            title=Ethernet
            sub=${ip:-Connected}
            ;;
        *)
            title=Wi-Fi
            if $wifi; then sub="Not connected"; else sub=Off; fi
            ;;
    esac

    result=$(jq -nc \
        --argjson w "$wifi" \
        --arg k "$kind" \
        --arg t "$title" \
        --arg s "$sub" \
        '{wifi:$w,kind:$k,title:$t,sub:$s}') || return 1

    cache_write net-status "$result"
    printf '%s\n' "$result"
}

net_list() {
    local raw result

    raw=$(nmcli -t -e no \
        -f IN-USE,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null) || {
        cache_read wifi && return 0
        printf '%s\n' '{"n":0,"items":[]}'
        return 0
    }

    result=$(awk -F: '{
        n=NF
        active=$1
        s=$2
        for(i=3;i<=n-2;i++) s=s ":" $i
        if(s!="") printf "%s\t%s\t%s\t%s\n",active,s,$(n-1),$n
    }' <<< "$raw" |
        jq -Rsc '
            split("\n")
            | map(select(length>0) | split("\t"))
            | map({
                active:(.[0]=="*"),
                ssid:.[1],
                signal:(.[2]|tonumber),
                secure:(.[3]!="" and .[3]!="--")
            })
            | unique_by(.ssid)
            | sort_by(-.signal)
            | .[0:8]
            | to_entries
            | map(.value+{idx:.key})
            | {n:length,items:.}
        ') || return 1

    cache_write wifi "$result"
    printf '%s\n' "$result"
}

net_scan() {
    local now last age radio
    now=$(date +%s)

    radio=$(nmcli -t radio wifi 2>/dev/null) || radio=
    if [[ "$radio" != enabled ]]; then
        up control_center_wifi net_list
        return
    fi

    # Avoid repeatedly triggering a radio scan when the popup is reopened.
    # The cached SSID list remains available immediately between scans.
    if [[ -r "$D/wifi-scan.timestamp" ]]; then
        last=$(<"$D/wifi-scan.timestamp")
        if [[ "$last" =~ ^[0-9]+$ ]]; then
            age=$((now - last))
            if (( age >= 0 && age < 30 )); then
                up control_center_wifi net_list
                return
            fi
        fi
    fi

    if nmcli dev wifi rescan >/dev/null 2>&1; then
        sleep 2
        printf '%s\n' "$now" > "$D/wifi-scan.timestamp"
    fi
    up control_center_wifi net_list
}

net_toggle() {
    local state
    state=$(nmcli -t radio wifi 2>/dev/null) || state=

    case "$state" in
        enabled)
            nmcli radio wifi off || return 1
            ;;
        disabled)
            nmcli radio wifi on || return 1
            ;;
        *)
            nf Wi-Fi "NetworkManager did not return a valid radio state"
            return 1
            ;;
    esac

    sleep 0.5
    up control_center_net net_status
}

net_connect() {
    local i=$1 ssid sec pw

    [[ "$i" =~ ^[0-9]+$ ]] || return 1
    [[ -r "$D/wifi.json" ]] || return 1

    ssid=$(jq -r --argjson i "$i" \
        '.items[$i].ssid // empty' "$D/wifi.json" 2>/dev/null)

    [[ -n "$ssid" ]] || return 1

    sec=$(jq -r --argjson i "$i" \
        '.items[$i].secure' "$D/wifi.json" 2>/dev/null)

    if nmcli -t -f NAME connection show |
        grep -qxF "$ssid"; then

        nmcli connection up id "$ssid" >/dev/null 2>&1 ||
            nf Wi-Fi "Could not connect to $ssid"

    elif [[ "$sec" == true ]]; then

        pw=$(
            wofi --dmenu --password \
                --cache-file /dev/null \
                --prompt "Password for $ssid" </dev/null
        ) || return 0

        [[ -n "$pw" ]] || return 0

        nmcli dev wifi connect "$ssid" password "$pw" \
            >/dev/null 2>&1 ||
            nf Wi-Fi "Could not connect to $ssid"

    else
        nmcli dev wifi connect "$ssid" >/dev/null 2>&1 ||
            nf Wi-Fi "Could not connect to $ssid"
    fi

    up control_center_net net_status
}
