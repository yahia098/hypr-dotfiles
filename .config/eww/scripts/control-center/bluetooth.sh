# Bluetooth adapter and paired-device operations.

bt_status() {
    local on=false
    local devs='[]'
    local found='[]'
    local adapter result paired

    adapter=$(bluetoothctl show 2>/dev/null) || {
        cache_read bt-status && return 0
        printf '%s\n' '{"powered":false,"count":0,"summary":"Unavailable","devices":[],"found":[]}'
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

        # Discovered but not paired yet. bluez keeps these cached for a few minutes
        # after a scan. Unnamed devices (name is just the MAC) are hidden as noise.
        paired=$(bluetoothctl devices Paired 2>/dev/null | awk '$1=="Device"{print $2}')
        found=$(
            bluetoothctl devices 2>/dev/null |
                awk -v paired="$paired" '
                    BEGIN { n = split(paired, a, "\n"); for (i = 1; i <= n; i++) p[a[i]] = 1 }
                    $1 == "Device" && !($2 in p) {
                        mac = $2; $1 = ""; $2 = ""; sub(/^ +/, ""); name = $0
                        if (name == "" || name ~ /^([0-9A-Fa-f][0-9A-Fa-f][-:]){5}[0-9A-Fa-f][0-9A-Fa-f]$/) next
                        printf "%s\t%s\n", mac, name
                    }' |
                jq -Rsc '
                    split("\n")
                    | map(select(length>0) | split("\t"))
                    | map({mac:.[0], name:.[1]})
                    | .[0:8]
                '
        )
        [[ -n "$found" ]] || found='[]'
    fi

    result=$(jq -nc \
        --argjson on "$on" \
        --argjson d "$devs" \
        --argjson f "$found" '
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
            devices:$d,
            found:$f
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

# bt_scan: discover nearby devices for 8 s, refreshing the list while it runs.
bt_scan() {
    bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' || {
        ew "bt_msg=Turn Bluetooth on first" bt_msg_err=true
        return 0
    }
    [[ $(eww get bt_scanning 2>/dev/null) == true ]] && return 0

    ew bt_scanning=true "bt_msg=" bt_msg_err=false
    ( for _ in 1 2 3 4; do sleep 2; up control_center_bt bt_status; done ) &
    timeout 12 bluetoothctl --timeout 8 scan on >/dev/null 2>&1
    wait
    ew bt_scanning=false
    up control_center_bt bt_status
}

# bt_pair MAC: pair, trust and connect a discovered device ("just works" devices:
# headphones, speakers, mice. Devices that need a PIN must be paired elsewhere).
bt_pair() {
    local mac=$1 name out why

    [[ "$mac" =~ $MAC_RE ]] || return 1
    [[ $(eww get bt_pairing 2>/dev/null) == true ]] && return 0

    name=$(bluetoothctl devices 2>/dev/null |
        awk -v m="$mac" '$1=="Device" && $2==m { $1=""; $2=""; sub(/^ +/, ""); print; exit }')
    ew bt_pairing=true "bt_msg=Pairing with ${name:-$mac}…" bt_msg_err=false

    out=$(timeout 40 bluetoothctl --agent NoInputNoOutput pair "$mac" 2>&1)
    # older bluetoothctl has no --agent option: retry plainly
    if [[ "$out" == *"nrecognized"* || "$out" == *"Usage"* ]]; then
        out=$(timeout 40 bluetoothctl pair "$mac" 2>&1)
    fi

    if [[ "$out" == *"Pairing successful"* || "$out" == *"Paired: yes"* || "$out" == *"AlreadyExists"* ]]; then
        bluetoothctl trust "$mac" >/dev/null 2>&1
        if timeout 15 bluetoothctl connect "$mac" >/dev/null 2>&1; then
            ew "bt_msg=Connected to ${name:-$mac}" bt_msg_err=false
        else
            ew "bt_msg=Paired, but could not connect" bt_msg_err=true
        fi
    else
        why=$(sed -n 's/.*Failed to pair: *//p' <<< "$out" | head -n1)
        why=${why#org.bluez.Error.}
        ew "bt_msg=Pairing failed${why:+: $why}" bt_msg_err=true
        nf Bluetooth "Pairing failed${why:+: $why}"
    fi

    ew bt_pairing=false
    up control_center_bt bt_status
}
