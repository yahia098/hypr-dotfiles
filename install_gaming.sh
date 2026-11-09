#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Do not run this script as root; it uses sudo for pacman." >&2
  exit 1
fi

PACMAN_CONF="/etc/pacman.conf"
if ! awk '
  /^\[multilib\][[:space:]]*$/ { in_multilib=1; next }
  /^\[/ { in_multilib=0 }
  in_multilib && /^[[:space:]]*Include[[:space:]]*=/ { found=1 }
  in_multilib && /^[[:space:]]*Server[[:space:]]*=/ { found=1 }
  END { exit !found }
' "$PACMAN_CONF"; then
  cat >&2 <<'MSG'
The [multilib] repository is not enabled in /etc/pacman.conf.
Enable [multilib], run `sudo pacman -Sy`, then rerun this script.
No gaming packages have been installed.
MSG
  exit 1
fi

packages=(
  gamemode gamescope lib32-gamemode lib32-gcc-libs lib32-mangohud
  lib32-mesa lib32-vkd3d lib32-vulkan-icd-loader mangohud
  protontricks sdl12-compat steam vulkan-tools vkd3d lutris
  wine wine-gecko wine-mono winetricks
)

# Add 32-bit Vulkan userspace for GPU drivers already installed.
if pacman -Qq nvidia-utils >/dev/null 2>&1; then
  packages+=(lib32-nvidia-utils)
fi
if pacman -Qq vulkan-radeon >/dev/null 2>&1; then
  packages+=(lib32-vulkan-radeon)
fi

sudo pacman -Syu --needed "${packages[@]}"

cat <<'MSG'
Gaming stack installed.

Install your GPU driver first with install_drivers.sh so the matching 32-bit
Vulkan/NVIDIA userspace can be selected. Steam and Proton still need their
usual per-game setup.
MSG
