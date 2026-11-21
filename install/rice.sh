#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

# Runtime dependencies referenced by this Hyprland rice (compositor, bar,
# launcher, theming pipeline, helper scripts, and the tools themed by Matugen).
# General workstation, gaming and driver packages live in their own installers.

require_user
find_aur_helper

sudo pacman -Syu --needed \
  adw-gtk-theme awww bluez bluez-utils brightnessctl cliphist dunst \
  evince ffmpeg ffmpegthumbnailer glib2 grim gpu-screen-recorder \
  gsettings-desktop-schemas hypridle hyprland hyprlock hyprpolkitagent \
  imagemagick jq kitty libnotify matugen nautilus networkmanager \
  papirus-icon-theme pavucontrol pipewire pipewire-alsa pipewire-pulse \
  playerctl python slurp socat ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols \
  tlp-pd waybar wl-clipboard wireplumber wofi xarchiver yazi zathura zathura-pdf-mupdf \
  xdg-desktop-portal xdg-desktop-portal-hyprland xdg-utils xorg-xwayland

"$AUR_HELPER" -S --needed \
  eww bm-sidebar nm-sidebar papirus-folders-git

cat <<EOF2

Hyprland rice runtime packages installed using $AUR_HELPER.

Optional applications launched by the config (Discord, Telegram, Whatsie,
LibreWolf, Helix Notes) are installed by install/apps.sh instead.

The power-profile widget uses tlp-pd's tlpctl command. Review its service
and power-management interaction with any other power-profile daemon.
EOF2
