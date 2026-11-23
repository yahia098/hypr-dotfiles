# NetworkManager / Wi-Fi operations, including in-widget password entry and testing.
#
# Networks are identified by a base64 key (not an index, not the raw SSID), so a
# re-sorted list can never connect you to the wrong network, and a hostile SSID
# can never be interpreted by the shell.

b64d() { printf '%s' "$1" | base64 -d 2>/dev/null; }

nm_has_profile() { nmcli -g NAME connection show 2>/dev/null | grep -qxF -- "$1"; }

# wifi_msg TEXT [true|false]  (second arg = is this an error?)
wifi_msg() { ew "wifi_msg=$1" "wifi_msg_err=${2:-false}"; }

wifi_clear_prompt() { ew wifi_pw_ssid= 'wifi_pw_list=[]' wifi_pw_show=false; }

wifi_busy_on() { ew wifi_busy=true "wifi_msg=Connecting to $1…" wifi_msg_err=false; }

net_status() {
    local wifi=false kind=none ssid= signal=0 ip= dev=
    local title sub radio line result conn

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

    dev=$(
        nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null |
            awk -F: '$2 == "wifi" && ($3 == "connected" || $3 ~ /^connected /) { print $1; exit }'
    )

    if [[ -n "$dev" ]]; then
        kind=wifi
        line=$(
            nmcli -t -e no -f IN-USE,SSID,SIGNAL device wifi list 2>/dev/null |
                awk -F: '$1 == "*" { print; exit }'
        )
        if [[ -n "$line" ]]; then
            signal=${line##*:}
            ssid=${line#*:}
            ssid=${ssid%:*}
        else
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

    [[ -n "$dev" ]] && ip=$(nmcli -g IP4.ADDRESS device show "$dev" 2>/dev/null | head -n1 | cut -d/ -f1)

    case "$kind" in
        wifi)
            title=$ssid
            if [[ -n "$ip" ]]; then sub="$ip · ${signal}%"; else sub="Connected · ${signal}%"; fi
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

    # NetworkManager's last known connectivity state (no network traffic).
    if [[ "$kind" != none ]]; then
        conn=$(nmcli -t networking connectivity 2>/dev/null)
        case "$conn" in
            limited) sub+=" · no internet" ;;
            portal)  sub+=" · login required" ;;
        esac
    fi

    result=$(jq -nc --argjson w "$wifi" --arg k "$kind" --arg t "$title" --arg s "$sub" \
        '{wifi:$w,kind:$k,title:$t,sub:$s}') || return 1

    cache_write net-status "$result"
    printf '%s\n' "$result"
}

net_list() {
    local raw result

    raw=$(nmcli -t -e no -f IN-USE,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null) || {
        cache_read wifi && return 0
        printf '%s\n' '{"n":0,"items":[]}'
        return 0
    }

    # Active network first, then strongest signal. Sorting BEFORE unique_by means
    # the active/strongest access point wins when an SSID appears more than once.
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
                signal:((.[2]|tonumber?) // 0),
                secure:(.[3]!="" and .[3]!="--"),
                key:(.[1]|@base64)
            })
            | sort_by([(.active|not), -.signal])
            | unique_by(.ssid)
            | sort_by([(.active|not), -.signal])
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
        enabled)  nmcli radio wifi off || return 1 ;;
        disabled) nmcli radio wifi on  || return 1 ;;
        *)
            nf Wi-Fi "NetworkManager did not return a valid radio state"
            return 1
            ;;
    esac

    sleep 0.5
    up control_center_net net_status
}

# net_test: connectivity check + latency, shown inside the widget.
net_test() {
    local c ms res
    ew "wifi_test=Testing…"

    c=$(timeout 8 nmcli -t networking connectivity check 2>/dev/null) || c=unknown
    case "$c" in
        full|unknown|"")
            ms=$(ping -c1 -W2 1.1.1.1 2>/dev/null | sed -n 's/.*time=\([0-9.]*\) ms.*/\1/p')
            if [[ -n "$ms" ]]; then res="Internet OK · ${ms%.*} ms"; else res="No internet"; fi
            ;;
        limited) res="Connected, no internet" ;;
        portal)  res="Login required (captive portal)" ;;
        none)    res="Not connected" ;;
        *)       res="Test unavailable" ;;
    esac
    ew "wifi_test=$res"
}

net_ok() {
    ew wifi_busy=false
    wifi_clear_prompt
    wifi_msg "Connected" false
    up control_center_net net_status
    up control_center_wifi net_list
    net_test
}

net_fail() { # EXIT_CODE OUTPUT
    local rc=$1 out=$2 m
    ew wifi_busy=false
    if (( rc == 124 )); then
        m="Timed out"
    elif [[ "$out" == *"Secrets were required"* || "$out" == *"4-way"* ]]; then
        m="Wrong password"
    elif [[ "$out" == *"property is invalid"* ]]; then
        m="Invalid password"
    elif [[ "$out" == *"No network with SSID"* ]]; then
        m="Network not found"
    else
        m="Could not connect"
    fi
    wifi_msg "$m" true
    nf Wi-Fi "$m"
}

net_prompt() { # SSID NOTE
    ew "wifi_pw_ssid=$1" 'wifi_pw_list=[1]' wifi_pw_show=false wifi_busy=false
    wifi_msg "$2" true
}

# net_connect KEY: KEY is the base64 SSID from the list.
net_connect() {
    local ssid sec out rc
    ssid=$(b64d "${1:-}")
    [[ -n "$ssid" ]] || return 1
    [[ $(eww get wifi_busy 2>/dev/null) == true ]] && return 0

    sec=$(jq -r --arg s "$ssid" \
        '[.items[] | select(.ssid == $s)][0].secure // false' "$D/wifi.json" 2>/dev/null)

    wifi_clear_prompt
    ew wifi_test=

    if nm_has_profile "$ssid"; then
        wifi_busy_on "$ssid"
        out=$(timeout 25 nmcli connection up id "$ssid" 2>&1); rc=$?
        if (( rc == 0 )); then net_ok; return 0; fi
        if [[ "$out" == *"Secrets were required"* || "$out" == *"assword"* ]]; then
            net_prompt "$ssid" "Saved password was rejected"
            return 0
        fi
        net_fail "$rc" "$out"
    elif [[ "$sec" == true ]]; then
        net_prompt "$ssid" ""
    else
        wifi_busy_on "$ssid"
        out=$(timeout 25 nmcli dev wifi connect "$ssid" 2>&1); rc=$?
        if (( rc == 0 )); then net_ok; else net_fail "$rc" "$out"; fi
    fi
}

# net_pwsubmit PASSWORD: called by the widget's input on Enter.
net_pwsubmit() {
    local pw=${CC_PW:-${1-}} ssid out rc
    unset CC_PW
    ssid=$(eww get wifi_pw_ssid 2>/dev/null)
    [[ -n "$ssid" && -n "$pw" ]] || return 0
    [[ $(eww get wifi_busy 2>/dev/null) == true ]] && return 0

    wifi_busy_on "$ssid"

    # We only get here for a new network or a rejected saved password, so drop any
    # stale profile and create a fresh one.
    nm_has_profile "$ssid" && nmcli connection delete id "$ssid" >/dev/null 2>&1

    if [[ "${WIFI_PW_MODE:-ask}" == argv ]]; then
        # fallback if your nmcli cannot read the password from stdin (visible in `ps`)
        out=$(timeout 30 nmcli dev wifi connect "$ssid" password "$pw" 2>&1); rc=$?
    else
        # --ask reads the password from stdin, so it never appears in nmcli's argv.
        out=$(printf '%s\n' "$pw" | timeout 30 nmcli --ask dev wifi connect "$ssid" 2>&1); rc=$?
    fi

    if (( rc == 0 )); then
        net_ok
    else
        # A failed attempt can leave a half-made profile behind that would hijack
        # the next click. Remove it, then keep the prompt open for another try.
        nm_has_profile "$ssid" && nmcli connection delete id "$ssid" >/dev/null 2>&1
        net_fail "$rc" "$out"
        ew "wifi_pw_ssid=$ssid" 'wifi_pw_list=[1]'
    fi
}

net_pwcancel() {
    wifi_clear_prompt
    wifi_msg "" false
}
