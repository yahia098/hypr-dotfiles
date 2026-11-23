# PipeWire / PulseAudio-compatible audio operations.

tgt() {
    [[ "$1" == source ]] &&
        printf '%s\n' '@DEFAULT_AUDIO_SOURCE@' ||
        printf '%s\n' '@DEFAULT_AUDIO_SINK@'
}

au_get() {
    local o v m

    o=$(wpctl get-volume "$(tgt "$1")" 2>/dev/null) ||
        { echo "0 false"; return; }

    v=$(awk '{printf "%d",$2*100+0.5}' <<< "$o")
    (( v > 100 )) && v=100

    [[ "$o" == *MUTED* ]] && m=true || m=false

    echo "$v $m"
}

au_getvol() {
    au_get "$1" | cut -d' ' -f1
}

au_list() {
    local k=$1 def o

    def=$(pactl "get-default-${k%s}" 2>/dev/null) || def=
    o=$(
        pactl -f json list "$k" 2>/dev/null |
            jq -c --arg d "$def" '
                [
                    .[]
                    | select(.name | endswith(".monitor") | not)
                    | {
                        name:.name,
                        desc:.description,
                        active:(.name==$d)
                    }
                ]
                | to_entries
                | map(.value+{idx:.key})
            '
    )

    if [[ -z "$o" ]]; then
        cache_read "$k" && return 0
        o='[]'
    fi

    cache_write "$k" "$o"
    printf '%s\n' "$o"
}

au_status() {
    local ov om iv im sinks sources result

    if ! wpctl status >/dev/null 2>&1; then
        cache_read audio-status && return 0
        printf '%s\n' '{"sink":{"vol":0,"muted":false},"source":{"vol":0,"muted":false},"sinks":[],"sources":[]}'
        return 0
    fi

    read -r ov om <<< "$(au_get sink)"
    read -r iv im <<< "$(au_get source)"

    sinks=$(au_list sinks)
    sources=$(au_list sources)

    result=$(jq -nc \
        --argjson ov "$ov" \
        --argjson om "$om" \
        --argjson iv "$iv" \
        --argjson im "$im" \
        --argjson s "$sinks" \
        --argjson r "$sources" '
        {
            sink:{vol:$ov,muted:$om},
            source:{vol:$iv,muted:$im},
            sinks:$s,
            sources:$r
        }') || return 1

    cache_write audio-status "$result"
    cache_write sink-volume "$ov"
    cache_write source-volume "$iv"
    printf '%s\n' "$result"
}

au_vol() {
    [[ "$1" == sink || "$1" == source ]] || return 1
    [[ "$2" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1

    local value
    value=$(pct "$2")

    wpctl set-volume -l 1.0 "$(tgt "$1")" "${value}%" ||
        return 1

    cache_write "$1-volume" "$value"
    eww update "control_center_vol_$1=$value" \
        >/dev/null 2>&1
}

au_mute() {
    [[ "$1" == sink || "$1" == source ]] || return 1

    wpctl set-mute "$(tgt "$1")" toggle
    up control_center_audio au_status
}

au_set() {
    [[ "$1" == sink || "$1" == source ]] || return 1
    [[ "$2" =~ ^[0-9]+$ ]] || return 1

    local n
    n=$(jq -r --argjson i "$2" \
        '.[$i].name // empty' "$D/${1}s.json" 2>/dev/null)

    [[ -n "$n" ]] || return 1

    pactl "set-default-$1" "$n" || return 1
    up control_center_audio au_status
}
