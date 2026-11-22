# Session and machine power actions.

pw_do() {
    case "$1" in
        lock|suspend|logout|reboot|shutdown) ;;
        *) return 1 ;;
    esac

    win close
    sleep 0.25

    case "$1" in
        lock)
            sh -c "$LOCK_CMD"
            ;;
        suspend)
            systemctl suspend
            ;;
        logout)
            loginctl terminate-user "$USER"
            ;;
        reboot)
            systemctl reboot
            ;;
        shutdown)
            systemctl poweroff
            ;;
    esac
}
