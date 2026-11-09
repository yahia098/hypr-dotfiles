#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Do not run this script as root; it uses sudo for pacman." >&2
  exit 1
fi

install_nvidia=0
install_amd=0

for arg in "$@"; do
  case "$arg" in
    --nvidia) install_nvidia=1 ;;
    --amd) install_amd=1 ;;
    -h|--help)
      printf 'Usage: %s [--nvidia] [--amd]\n' "$0"
      printf 'Select one or both GPU driver stacks.\n'
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

if (( ! install_nvidia && ! install_amd )); then
  echo "Choose at least one driver: --nvidia, --amd, or both." >&2
  exit 2
fi

packages=()
if (( install_nvidia )); then
  packages+=(nvidia-open nvidia-prime nvidia-utils)
fi
if (( install_amd )); then
  packages+=(mesa vulkan-radeon vulkan-mesa-layers)
fi

sudo pacman -Syu --needed "${packages[@]}"

cat <<'MSG'
Selected GPU driver packages installed.
Reboot before testing the new kernel driver. For Steam/Proton, run
install_gaming.sh after enabling [multilib] to add the relevant 32-bit stack.
MSG
