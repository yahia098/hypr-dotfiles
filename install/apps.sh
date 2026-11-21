#!/usr/bin/env bash
set -Eeuo pipefail

# Personal applications and development toolchain.
# Rice runtime, GPU drivers, and gaming packages live in their own installers.

source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

require_user
find_aur_helper
# Native applications and the user's development toolchain.
echo "Installing official repository packages with pacman..."
sudo "$PACMAN_BIN" -Syu --needed \
  bear bison clang cloc cmake cppcheck ccache dfu-util discord fd flex fzf gcc gdb git \
  github-cli gperf jdk-openjdk lldb llvm make ncurses neovim neovide ninja \
  nodejs npm python python-black python-debugpy python-pip python-virtualenv \
  ripgrep rust-analyzer rustup sdl3 sdl3_image sdl3_mixer sdl3_ttf shellcheck \
  stylua selene uv wget telegram-desktop flatpak zsh lsd yt-dlp
# Community packages: apps launched by the rice, plus the ESP-IDF toolchain.
echo "Installing AUR packages with $AUR_HELPER..."
"$AUR_HELPER" -S --needed whatsie helixnotes-bin librewolf-bin esp-idf

# Prepare the Rust toolchain used by blink.cmp and Rust projects.
if ! rustup toolchain list | grep -q '^stable'; then
  rustup toolchain install stable
fi
rustup default stable
rustup component add clippy
# Install the user's Neovim configuration. Never overwrite an existing config.
NVIM_CONFIG="$HOME/.config/nvim"
NVIM_REPO="https://github.com/yahia098/nvim.dots.git"
if [[ -d "$NVIM_CONFIG/.git" ]] && \
   [[ "$(git -C "$NVIM_CONFIG" remote get-url origin 2>/dev/null || true)" == "$NVIM_REPO" ]]; then
  echo "Your nvim.dots repository is already installed; leaving it untouched."
elif [[ -e "$NVIM_CONFIG" || -L "$NVIM_CONFIG" ]]; then
  BACKUP="$HOME/.config/nvim.backup-$(date +%Y%m%d-%H%M%S)"
  if [[ -e "$BACKUP" || -L "$BACKUP" ]]; then
    echo "Backup path already exists: $BACKUP" >&2
    echo "Refusing to overwrite it; move it aside and rerun this script." >&2
    exit 1
  fi
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
  if ! git clone "$NVIM_REPO" "$NVIM_CONFIG"; then
    rm -rf -- "$NVIM_CONFIG"
    echo "Clone failed; removed the incomplete Neovim config directory." >&2
    exit 1
  fi
fi
cat <<EOF2

Personal applications and development stack installed.
AUR packages were installed using $AUR_HELPER.
Neovim configuration: https://github.com/yahia098/nvim.dots

ESP-IDF is installed under /opt/esp-idf by the AUR package. In a zsh session,
run "esp" (defined in the repository .zshrc) to activate its environment. See the
README for serial-device permission notes.

oh-my-zsh is not packaged here; install it from https://ohmyz.sh if you use the
repository .zshrc.
EOF2
