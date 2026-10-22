
#!/usr/bin/env bash

if ! command -v tlpctl >/dev/null 2>&1; then
    printf '%s\n' '{"text":"?","class":"unknown","tooltip":"tlpctl is not installed"}'
    exit 0
fi

if ! CURRENT="$(tlpctl get 2>/dev/null)"; then
    printf '%s\n' '{"text":"?","class":"unknown","tooltip":"Could not read TLP profile"}'
    exit 0
fi

case "$CURRENT" in
    performance)
        printf '%s\n' '{"text":"󰓅","class":"performance","tooltip":"Performance"}'
        ;;
    balanced)
        printf '%s\n' '{"text":"","class":"balanced","tooltip":"Balanced"}'
        ;;
    power-saver)
        printf '%s\n' '{"text":"","class":"power-saver","tooltip":"Power Saver"}'
        ;;
    *)
        printf '%s\n' '{"text":"?","class":"unknown","tooltip":"Unknown TLP profile"}'
        ;;
esac

