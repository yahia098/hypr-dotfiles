# Shared configuration, cache helpers, and utilities.
# (BL_DEVICE and LOCK_CMD now live in config.sh.)

export LC_ALL=C

umask 077
mkdir -p "$D"

# One-time migration of the old session-only cache.
if [[ ! -e "$D/.migrated" ]]; then
    LEGACY_D="${XDG_RUNTIME_DIR:-/tmp}/eww-control-center"
    if [[ -d "$LEGACY_D" && "$LEGACY_D" != "$D" ]]; then
        for name in wifi sinks sources; do
            if [[ ! -s "$D/$name.json" && -s "$LEGACY_D/$name.json" ]]; then
                cp -n -- "$LEGACY_D/$name.json" "$D/$name.json" 2>/dev/null || true
            fi
        done
    fi
    : > "$D/.migrated"
fi

MAC_RE='^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$'

nf() {
    command -v notify-send >/dev/null &&
        notify-send -a "Control Center" "$1" "$2"
}

# ew VAR=VALUE...: quiet eww update
ew() { eww update "$@" >/dev/null 2>&1; }

up() {
    local key=$1 fn=$2 value
    shift 2

    value=$("$fn" "$@") || return 1
    eww update "$key=$value" >/dev/null 2>&1
}

cache_write() {
    local name=$1 value=$2 tmp
    tmp=$(mktemp "$D/.${name}.XXXXXX") || return 1
    if printf '%s\n' "$value" > "$tmp"; then
        mv -f -- "$tmp" "$D/$name.json"
    else
        rm -f -- "$tmp"
        return 1
    fi
}

cache_read() {
    [[ -s "$D/$1.json" ]] || return 1
    cat -- "$D/$1.json"
}

cache_to_eww() {
    local variable=$1 name=$2 value
    value=$(cache_read "$name") || return 1
    eww update "$variable=$value" >/dev/null 2>&1
}

load_cached_state() {
    local audio sink_vol source_vol
    cache_to_eww control_center_net net-status || true
    cache_to_eww control_center_wifi wifi || true
    cache_to_eww control_center_bt bt-status || true
    audio=$(cache_read audio-status) || audio=
    if [[ -n "$audio" ]] && jq -e .sink.vol >/dev/null 2>&1 <<< "$audio"; then
        sink_vol=$(cache_read sink-volume) || sink_vol=$(jq -r '.sink.vol' <<< "$audio")
        source_vol=$(cache_read source-volume) || source_vol=$(jq -r '.source.vol' <<< "$audio")
        eww update "control_center_audio=$audio" >/dev/null 2>&1
        eww update "control_center_vol_sink=$sink_vol" >/dev/null 2>&1
        eww update "control_center_vol_source=$source_vol" >/dev/null 2>&1
    fi
}

pct() {
    local v
    v=$(printf '%.0f' "$1" 2>/dev/null) || v=0
    (( v < 0 )) && v=0
    (( v > 100 )) && v=100
    printf '%s\n' "$v"
}
