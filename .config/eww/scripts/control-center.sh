#!/usr/bin/env bash
# Eww control-center entry point. Public CLI is unchanged:
#   win [network|bluetooth|audio|close]
#   wifi|bluetooth|audio
#   net|bt|au|sys|pw <command> [arguments]

export LC_ALL=C
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$SCRIPT_DIR/control-center"
D="${XDG_CACHE_HOME:-$HOME/.cache}/eww-control-center"
source "$MODULE_DIR/config.sh"

# ------------------------------------------------------------------
# Fast paths: sliders and their polls must not load any module.
# ------------------------------------------------------------------
now_us() { local t=${EPOCHREALTIME/./}; printf '%s' "$t"; }

# recent KEY: true if the user moved that slider in the last 1.5 s.
recent() {
    local t
    [[ -r "$D/touch-$1" ]] || return 1
    t=$(<"$D/touch-$1")
    [[ "$t" =~ ^[0-9]+$ ]] || return 1
    (( $(now_us) - t < 1500000 ))
}

# coalesce KEY VALUE CMD [ARGS...]: while a slider is dragged, only the newest
# value is applied, by a single worker, instead of one process per event.
coalesce() {
    local key=$1 val=$2
    shift 2
    mkdir -p "$D"
    printf '%s' "$val" > "$D/pending-$key"
    now_us > "$D/touch-$key"
    (
        flock -n 9 || exit 0
        last=
        while cur=$(<"$D/pending-$key"); [[ "$cur" != "$last" ]]; do
            last=$cur
            "$@" "$cur"
        done
    ) 9>"$D/lock-$key" >/dev/null 2>&1 &
}

wp_target() { [[ "$1" == source ]] && echo '@DEFAULT_AUDIO_SOURCE@' || echo '@DEFAULT_AUDIO_SINK@'; }

clamp() { # VALUE MIN
    local v
    printf -v v '%.0f' "$1" 2>/dev/null || v=0
    (( v < $2 )) && v=$2
    (( v > 100 )) && v=100
    printf '%s' "$v"
}

apply_vol() { # KIND VALUE
    # eww var first so the % label follows the drag immediately, then the hardware
    eww update "control_center_vol_$1=$2" >/dev/null 2>&1
    wpctl set-volume -l 1.0 "$(wp_target "$1")" "$2%"
    printf '%s\n' "$2" > "$D/$1-volume.json"
}

apply_bright() { # VALUE
    eww update "control_center_bright=$1" >/dev/null 2>&1
    if [[ -n "$BL_DEVICE" ]]; then
        brightnessctl -q -d "$BL_DEVICE" set "$1%"
    else
        brightnessctl -q set "$1%"
    fi
}

case "${1:-}:${2:-}" in
    au:vol)
        [[ "${3:-}" == sink || "${3:-}" == source ]] || exit 1
        [[ "${4:-}" =~ ^[0-9]+([.][0-9]+)?$ ]] || exit 1
        coalesce "vol-$3" "$(clamp "$4" 0)" apply_vol "$3"
        exit 0
        ;;
    au:getvol)
        [[ "${3:-}" == sink || "${3:-}" == source ]] || exit 1
        if recent "vol-$3"; then printf '%s\n' "$(<"$D/pending-vol-$3")"; exit 0; fi
        o=$(wpctl get-volume "$(wp_target "$3")" 2>/dev/null) || { echo 0; exit 0; }
        awk '{v=int($2*100+0.5); if (v>100) v=100; print v}' <<< "$o"
        exit 0
        ;;
    sys:bright)
        [[ "${3:-}" =~ ^[0-9]+([.][0-9]+)?$ ]] || exit 1
        coalesce bright "$(clamp "$3" 1)" apply_bright
        exit 0
        ;;
    sys:getbright)
        if recent bright; then printf '%s\n' "$(<"$D/pending-bright")"; exit 0; fi
        args=(); [[ -n "$BL_DEVICE" ]] && args=(-d "$BL_DEVICE")
        brightnessctl "${args[@]}" -m 2>/dev/null |
            awk -F, 'NF >= 5 {gsub("%", "", $4); print $4; exit}'
        exit 0
        ;;
    win:close)
        exec "$SCRIPT_DIR/cc-close.sh"
        ;;
esac

# ------------------------------------------------------------------
# Eww kills any onclick/onaccept command still running after 200 ms (its default
# :timeout). Re-launch user actions in their own session and return at once, so
# slow ones (power, connect, password, test...) are never killed half way.
# Output goes to $D/actions.log, which is the place to look when something fails.
# ------------------------------------------------------------------
if [[ -z "${CC_DETACHED:-}" ]]; then
    case "${1:-}:${2:-}" in
        win:*|wifi:*|bluetooth:*|audio:*|pw:do|net:toggle|net:connect|net:pwsubmit|net:pwcancel|net:test|net:scan|bt:power|bt:device|bt:scan|bt:pair|au:mute|au:set|sys:prof)
            mkdir -p "$D"
            # The Wi-Fi password arrives on stdin (a quoted here-doc from eww), so it is
            # never parsed by a shell or shown in a command line. Read it here, before
            # detaching, and hand it over through the environment.
            if [[ "${1:-}:${2:-}" == net:pwsubmit && -z "${3:-}" ]]; then
                IFS= read -r CC_PW || true
                export CC_PW
            fi
            CC_DETACHED=1 setsid -f "$SCRIPT_DIR/control-center.sh" "$@" \
                >>"$D/actions.log" 2>&1 </dev/null
            exit 0
            ;;
    esac
fi

# ------------------------------------------------------------------
# Everything else: load only the modules the command needs.
# ------------------------------------------------------------------
source "$MODULE_DIR/common.sh"

case "${1:-}" in
    win|wifi|bluetooth|audio)
        for m in windows network bluetooth audio system power; do
            source "$MODULE_DIR/$m.sh"
        done
        ;;
    net) source "$MODULE_DIR/network.sh" ;;
    bt)  source "$MODULE_DIR/bluetooth.sh" ;;
    au)  source "$MODULE_DIR/audio.sh" ;;
    sys) source "$MODULE_DIR/system.sh" ;;
    pw)  source "$MODULE_DIR/power.sh" ;;
    *)   exit 0 ;;
esac

# Only these commands can be reached from eww.
declare -A ALLOW=(
    [net]="status list scan toggle connect pwsubmit pwcancel test"
    [bt]="status power device scan pair"
    [au]="status mute set getvol"
    [sys]="status prof"
    [pw]="do"
)

case "$1" in
    win)       win "${2:-}" ;;
    wifi)      menu wifi-menu network ;;
    bluetooth) menu bluetooth-menu bluetooth ;;
    audio)     menu audio-menu "" ;;
    net|bt|au|sys|pw)
        [[ " ${ALLOW[$1]} " == *" ${2:-} "* ]] || exit 1
        "${1}_${2}" "${@:3}"
        ;;
esac
