#!/usr/bin/env bash
# Shared helpers for the installers. Source this file; do not execute it.

require_user() {
  if [[ $EUID -eq 0 ]]; then
    echo "Do not run this script as root; it uses sudo for pacman." >&2
    exit 1
  fi
}

# Sets AUR_HELPER to yay or paru, or exits before anything is installed.
find_aur_helper() {
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
}
