#!/usr/bin/env bash
# Shared helpers for the installers. Source this file; do not execute it.

require_user() {
  if [[ $EUID -eq 0 ]]; then
    echo "Do not run this script as root; it uses sudo for pacman." >&2
    exit 1
  fi

  if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo was not found. Install sudo and rerun this script." >&2
    exit 1
  fi

  PACMAN_BIN="$(command -v pacman || true)"
  PACMAN_CONF_BIN="$(command -v pacman-conf || true)"

  if [[ -z "$PACMAN_BIN" || ! -x "$PACMAN_BIN" ]]; then
    echo "pacman was not found. These installers are intended for Arch Linux." >&2
    exit 1
  fi
  if [[ -z "$PACMAN_CONF_BIN" || ! -x "$PACMAN_CONF_BIN" ]]; then
    echo "pacman-conf was not found; verify that the pacman package is installed." >&2
    exit 1
  fi

  local root dbpath
  if ! root="$("$PACMAN_CONF_BIN" RootDir 2>/dev/null)" || \
     ! dbpath="$("$PACMAN_CONF_BIN" DBPath 2>/dev/null)"; then
    echo "Pacman could not parse /etc/pacman.conf. Fix that configuration before installing packages." >&2
    exit 1
  fi

  # DBPath must be absolute. Catch malformed settings such as `DBPath = in`
  # here, rather than letting libalpm fail later with an opaque initialization error.
  if [[ "$dbpath" != /* ]]; then
    printf 'Invalid Pacman DBPath: %q (RootDir: %q).\n' "$dbpath" "$root" >&2
    echo "DBPath in /etc/pacman.conf must be an absolute path; the normal Arch default is /var/lib/pacman/." >&2
    exit 1
  fi

  if [[ "$root" == "/" && ! -d "$dbpath" ]]; then
    printf 'Pacman database directory does not exist: %q\n' "$dbpath" >&2
    echo "Check the DBPath setting in /etc/pacman.conf before rerunning this installer." >&2
    exit 1
  fi
}

# Sets AUR_HELPER to the executable path of yay or paru, or exits before
# anything is installed.
find_aur_helper() {
  AUR_HELPER=""

  local candidate
  for candidate in yay paru; do
    if command -v "$candidate" >/dev/null 2>&1; then
      candidate="$(command -v "$candidate")"
      if [[ -x "$candidate" ]]; then
        AUR_HELPER="$candidate"
        break
      fi
    fi
  done

  if [[ -z "$AUR_HELPER" ]]; then
    cat >&2 <<'MSG'
No supported AUR helper was found.
Install yay or paru first, then rerun this script.
Nothing has been installed.
MSG
    exit 1
  fi
}
