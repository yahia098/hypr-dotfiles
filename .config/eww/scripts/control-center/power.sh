# Session and machine power actions.

pw_do() {
    case "$1" in
        lock|suspend|logout|reboot|shutdown) ;;
        *) return 1 ;;
    esac

    "$SCRIPT_DIR/cc-close.sh"
    sleep 0.15

    case "$1" in
        lock)
            sh -c "$LOCK_CMD"
            ;;
        suspend)
            # Lock first so the session never wakes up unlocked.
            sh -c "$LOCK_CMD" >/dev/null 2>&1 &
            sleep 0.6
            systemctl suspend
            ;;
        logout)
            # Same dispatcher as hypr/scripts/powermenu.sh (Hyprland 0.57 Lua API);
            # only fall back to the hammer if Hyprland refuses.
            hyprctl dispatch 'hl.dsp.exit()' >/dev/null 2>&1 ||
                hyprctl dispatch exit >/dev/null 2>&1 ||
                loginctl terminate-user "$USER"
            ;;
        reboot)   systemctl reboot ;;
        shutdown) systemctl poweroff ;;
    esac
}
