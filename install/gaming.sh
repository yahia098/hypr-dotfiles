#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

require_user
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
Enable [multilib], run `sudo pacman -Syu`, then rerun this script.
No gaming packages have been installed.
MSG
  exit 1
fi

# Check this before installing repository packages; otherwise a missing AUR
# helper leaves the gaming stack only partially installed.
find_aur_helper

packages=(
  gamemode gamescope lib32-gamemode lib32-gcc-libs lib32-mangohud
  lib32-mesa lib32-vkd3d lib32-vulkan-icd-loader mangohud
  protontricks sdl12-compat steam vulkan-tools vkd3d lutris
  wine wine-gecko wine-mono winetricks
)
# Add 32-bit Vulkan userspace for GPU drivers already installed.
if "$PACMAN_BIN" -Qq nvidia-utils >/dev/null 2>&1; then
  packages+=(lib32-nvidia-utils)
fi
if "$PACMAN_BIN" -Qq vulkan-radeon >/dev/null 2>&1; then
  packages+=(lib32-vulkan-radeon)
fi

sudo "$PACMAN_BIN" -Syu --needed "${packages[@]}"
# DXVK (Direct3D-to-Vulkan) from the AUR.
"$AUR_HELPER" -S --needed dxvk-bin

cat <<'MSG'
Gaming stack installed.

Install your GPU driver first with install/drivers.sh so the matching 32-bit
Vulkan/NVIDIA userspace can be selected. Steam and Proton still need their
usual per-game setup.
MSG
