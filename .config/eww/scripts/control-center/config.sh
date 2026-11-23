# User-editable settings for the control center.

# Backlight device. Empty = brightnessctl's default, the same one your
# brightness keybinds (hypr/scripts/brightness.sh) use.
BL_DEVICE=""

# Your single lock entry point (skips if already locked, builds the blur if missing).
LOCK_CMD='"$HOME/.config/hypr/scripts/lock.sh"'

# How the Wi-Fi password is given to nmcli: "ask" (stdin, not visible in `ps`) or
# "argv" (fallback if `printf 'pw\n' | nmcli --ask dev wifi connect SSID` fails for you).
WIFI_PW_MODE="ask"
