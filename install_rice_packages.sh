#!/usr/bin/env bash
set -Eeuo pipefail

# Runtime dependencies referenced by this Hyprland rice.
# This intentionally does not install general workstation or gaming software.

if [[ $EUID -eq 0 ]]; then
  echo "Do not run this script as root; it uses sudo for pacman." >&2
  exit 1
fi

AUR_HELPER=""
if command -v yay >/dev/null 2>&1; then
  AUR_HELPER="yay"
elif command -v paru >/dev/null 2>&1; then
  AUR_HELPER="paru"
else
  cat >&2 <<'MSG'
No supported AUR helper was found.
Install yay or paru first, then rerun this script.
Nothing has been installed.
MSG
  exit 1
fi

sudo pacman -Syu --needed \
  adw-gtk-theme awww bluez bluez-utils brightnessctl cliphist dunst \
  evince ffmpeg ffmpegthumbnailer glib2 grim gpu-screen-recorder \
  gsettings-desktop-schemas hypridle hyprland hyprlock hyprpolkitagent \
  imagemagick jq kitty libnotify matugen nautilus networkmanager \
  papirus-icon-theme pavucontrol pipewire pipewire-alsa pipewire-pulse \
  playerctl slurp socat ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols \
  tlp-pd waybar wl-clipboard wireplumber wofi \
  xdg-desktop-portal xdg-desktop-portal-hyprland xdg-utils xorg-xwayland

"$AUR_HELPER" -S --needed \
  eww bm-sidebar nm-sidebar papirus-folders-git

cat <<EOF2

Hyprland rice runtime packages installed using $AUR_HELPER.

Optional applications launched by the config (Telegram, Vesktop and Whatsie)
are intentionally not included. Install those separately if you use them.

The power-profile widget uses tlp-pd's tlpctl command. Review its service
and power-management interaction with any other power-profile daemon.
EOF2
