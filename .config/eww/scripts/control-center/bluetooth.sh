# Bluetooth adapter and paired-device operations.

bt_status() {
    local on=false
    local devs='[]'
    local adapter result

    adapter=$(bluetoothctl show 2>/dev/null) || {
        cache_read bt-status && return 0
        printf '%s\n' '{"powered":false,"count":0,"summary":"Unavailable","devices":[]}'
        return 0
    }
    grep -q 'Powered: yes' <<< "$adapter" && on=true

    if $on; then
        devs=$(
            bluetoothctl devices Paired 2>/dev/null |
                while IFS= read -r line; do

                    [[ "$line" =~ ^Device[[:space:]]+(([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2})[[:space:]]+(.*)$ ]] ||
                        continue

                    local mac=${BASH_REMATCH[1]}
                    local name=${BASH_REMATCH[3]}
                    local info connected=false battery=

                    info=$(bluetoothctl info "$mac" 2>/dev/null)

                    grep -q 'Connected: yes' <<< "$info" &&
                        connected=true

                    battery=$(
                        sed -n \
                            's/.*Battery Percentage: .*(\([0-9]*\)).*/\1/p' \
                            <<< "$info"
                    )

                    printf '%s\t%s\t%s\t%s\n' \
                        "$mac" "$name" "$connected" "${battery:--1}"
                done |
                jq -Rsc '
                    split("\n")
                    | map(select(length>0) | split("\t"))
                    | map({
                        mac:.[0],
                        name:.[1],
                        connected:(.[2]=="true"),
                        battery:(.[3]|tonumber)
                    })
                    | sort_by(.connected|not)
                '
        )

        [[ -n "$devs" ]] || devs='[]'
    fi

    result=$(jq -nc \
        --argjson on "$on" \
        --argjson d "$devs" '
        ([$d[] | select(.connected) | .name]) as $c
        | {
            powered:$on,
            count:($d|length),
            summary:(
                if ($on|not) then "Off"
                elif ($c|length)>0 then ($c|join(", "))
                else "Not connected"
                end
            ),
            devices:$d
        }') || return 1
    cache_write bt-status "$result"
    printf '%s\n' "$result"
}

bt_power() {
    if bluetoothctl show 2>/dev/null |
        grep -q 'Powered: yes'; then

        bluetoothctl power off >/dev/null
    else
        rfkill unblock bluetooth 2>/dev/null
        bluetoothctl power on >/dev/null
    fi

    sleep 0.4
    up control_center_bt bt_status
}

bt_device() {
    [[ "$1" =~ $MAC_RE ]] || return 1

    if bluetoothctl info "$1" 2>/dev/null |
        grep -q 'Connected: yes'; then

        bluetoothctl disconnect "$1" >/dev/null
    else
        timeout 15 bluetoothctl connect "$1" \
            >/dev/null 2>&1 ||
            nf Bluetooth "Could not connect"
    fi

    up control_center_bt bt_status
}
