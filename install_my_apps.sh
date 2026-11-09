#!/usr/bin/env bash
set -Eeuo pipefail

# Personal applications and development toolchain.
# Rice runtime, GPU drivers, and gaming packages live in their own installers.

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

# Native applications and the user's development toolchain.
sudo pacman -Syu --needed \
  bear bison clang cloc cmake cppcheck ccache dfu-util fd flex fzf gcc gdb git \
  github-cli gperf jdk-openjdk lldb llvm make ncurses neovim neovide ninja \
  nodejs npm python python-black python-debugpy python-pip python-virtualenv \
  ripgrep rust-analyzer rustup sdl3 sdl3_image sdl3_mixer sdl3_ttf shellcheck \
  stylua selene uv wget telegram-desktop flatpak

# Community packages: Vesktop and Espressif's ESP-IDF toolchain package.
"$AUR_HELPER" -S --needed vesktop esp-idf

# Prepare the Rust toolchain used by blink.cmp and Rust projects.
if ! rustup toolchain list | grep -q '^stable'; then
  rustup toolchain install stable
fi
rustup default stable
rustup component add clippy

# Install Whatsie per-user; don't modify the system-wide Flatpak remotes.
if ! flatpak remotes --user --columns=name | grep -Fxq flathub; then
  flatpak remote-add --user --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo
fi
flatpak install --user --assumeyes --noninteractive flathub \
  com.ktechpit.whatsie

# Install the user's Neovim configuration. Never overwrite an existing config.
NVIM_CONFIG="$HOME/.config/nvim"
NVIM_REPO="https://github.com/yahia098/nvim.dots.git"

if [[ -d "$NVIM_CONFIG/.git" ]] && \
   [[ "$(git -C "$NVIM_CONFIG" remote get-url origin 2>/dev/null || true)" == "$NVIM_REPO" ]]; then
  echo "Your nvim.dots repository is already installed; leaving it untouched."
elif [[ -e "$NVIM_CONFIG" || -L "$NVIM_CONFIG" ]]; then
  BACKUP="$HOME/.config/nvim.backup-$(date +%Y%m%d-%H%M%S)"
  echo "Existing Neovim config found. Moving it to: $BACKUP"
  mv -- "$NVIM_CONFIG" "$BACKUP"
  if ! git clone "$NVIM_REPO" "$NVIM_CONFIG"; then
    rm -rf -- "$NVIM_CONFIG"
    mv -- "$BACKUP" "$NVIM_CONFIG"
    echo "Clone failed; restored your previous Neovim config." >&2
    exit 1
  fi
else
  mkdir -p "$HOME/.config"
  git clone "$NVIM_REPO" "$NVIM_CONFIG"
fi

cat <<EOF2

Personal applications and development stack installed.
AUR packages were installed using $AUR_HELPER.
Whatsie was installed from Flathub for the current user.
Neovim configuration: https://github.com/yahia098/nvim.dots

ESP-IDF is installed under /opt/esp-idf by the AUR package. In a zsh session,
run `source /opt/esp-idf/export.sh` to activate its environment. See the README
for a reusable shell function and serial-device permission notes.
EOF2
