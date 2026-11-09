#!/usr/bin/env bash
set -Eeuo pipefail

# Deploy the .config entries and .zshrc shipped by this repository.
# Existing managed paths are backed up first. Deployment merges files and
# never deletes files that are not present in the repository.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME:?HOME is not set}"
ASSUME_YES=0
DRY_RUN=0

log()  { printf '[DEPLOY] %s\n' "$*"; }
warn() { printf '[DEPLOY] WARNING: %s\n' "$*" >&2; }
die()  { printf '[DEPLOY] ERROR: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<USAGE
Usage: $(basename -- "$0") [OPTIONS]

Deploy this repository's configuration into your home directory.

Options:
  -y, --yes       Skip the confirmation prompt. A backup is still created.
  --dry-run       Print the deployment plan without changing anything.
  -h, --help      Show this help.

What it deploys:
  .config/*       Every top-level file/directory under the repository .config
  .zshrc          The repository zsh configuration, when present

Safety behavior:
  - Automatically runs backup.sh before copying any files.
  - Merges into existing config directories; it does not delete unrelated files.
  - Existing files with matching names are replaced after the backup.
  - Refuses symlinked destination roots to avoid writing through unexpected paths.
  - Does not install packages, enable services, or alter your boot/login manager.
USAGE
}

while (($#)); do
  case "$1" in
    -y|--yes)
      ASSUME_YES=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1. Use --help for usage."
      ;;
  esac
done

[[ "$EUID" -ne 0 ]] || die "Do not run this as root. Run it as the desktop user whose HOME should receive the rice."
[[ -d "$SCRIPT_DIR/.config" ]] || die "Cannot find the repository .config directory: $SCRIPT_DIR/.config"
[[ -f "$SCRIPT_DIR/backup.sh" ]] || die "backup.sh is missing from the repository."

mapfile -d '' -t repo_entries < <(find "$SCRIPT_DIR/.config" -mindepth 1 -maxdepth 1 -print0 | sort -z)
((${#repo_entries[@]} > 0)) || die "No configuration entries were found under $SCRIPT_DIR/.config."

if [[ -L "$HOME_DIR/.config" ]]; then
  die "$HOME_DIR/.config is a symbolic link. This script refuses to deploy through it. Back it up and resolve the link manually first."
fi

log "============================================================"
log "HYPRLAND RICE DEPLOYMENT PLAN"
log "============================================================"
log "Source repository: $SCRIPT_DIR"
log "Destination HOME:  $HOME_DIR"
log "Config entries:    ${#repo_entries[@]}"
log "Copy strategy:     merge/overwrite matching files; preserve extras"
log "Backup strategy:   timestamped archive before deployment"

for source in "${repo_entries[@]}"; do
  name="${source##*/}"
  destination="$HOME_DIR/.config/$name"
  if [[ -L "$destination" ]]; then
    die "$destination is a symbolic link. Refusing to deploy through it."
  fi
  if [[ -e "$destination" && -d "$source" && ! -d "$destination" ]]; then
    die "Cannot merge directory $source into non-directory destination $destination. Resolve this conflict first."
  fi
  if [[ -e "$destination" && ! -d "$source" && -d "$destination" ]]; then
    die "Cannot copy file $source over directory destination $destination. Resolve this conflict first."
  fi
  log "PLAN   $source  ->  $destination"
done

if [[ -e "$SCRIPT_DIR/.zshrc" || -L "$SCRIPT_DIR/.zshrc" ]]; then
  if [[ -L "$HOME_DIR/.zshrc" ]]; then
    die "$HOME_DIR/.zshrc is a symbolic link. Refusing to replace it."
  fi
  log "PLAN   .zshrc  ->  $HOME_DIR/.zshrc"
else
  warn "No .zshrc exists in the repository; your current shell configuration will be left alone."
fi

if ((DRY_RUN)); then
  log "DRY RUN requested. Checking which existing files would be backed up..."
  bash "$SCRIPT_DIR/backup.sh" --dry-run
  log "DRY RUN COMPLETE. No backup or deployment changes were made."
  exit 0
fi

if ((!ASSUME_YES)); then
  printf '\n'
  warn "Matching files in your home directory may be overwritten."
  warn "A backup will be created first; unrelated files will not be deleted."
  [[ -t 0 ]] || die "No interactive terminal is available. Review the plan and rerun with --yes to proceed."
  read -r -p "Deploy this rice into $HOME_DIR? [y/N] " answer
  case "$answer" in
    y|Y|yes|YES|Yes) ;;
    *) log "Cancelled. No files were changed."; exit 0 ;;
  esac
fi

log "============================================================"
log "STEP 1/3 — BACK UP EXISTING CONFIGURATION"
log "============================================================"
bash "$SCRIPT_DIR/backup.sh"

log "============================================================"
log "STEP 2/3 — DEPLOY CONFIGURATION DIRECTORIES"
log "============================================================"
mkdir -p -- "$HOME_DIR/.config"
for source in "${repo_entries[@]}"; do
  name="${source##*/}"
  destination="$HOME_DIR/.config/$name"
  log "Deploying $name..."
  if [[ -d "$source" && ! -L "$source" ]]; then
    mkdir -p -- "$destination"
    cp -av -- "$source/." "$destination/"
  else
    cp -av -- "$source" "$destination"
  fi
  log "Completed: $destination"
done

log "============================================================"
log "STEP 3/3 — DEPLOY ZSH CONFIGURATION"
log "============================================================"
if [[ -e "$SCRIPT_DIR/.zshrc" || -L "$SCRIPT_DIR/.zshrc" ]]; then
  cp -av -- "$SCRIPT_DIR/.zshrc" "$HOME_DIR/.zshrc"
  log "Completed: $HOME_DIR/.zshrc"
else
  log "Skipped: repository does not contain .zshrc."
fi

log "============================================================"
log "DEPLOYMENT COMPLETE"
log "============================================================"
log "Configuration files have been copied. Untracked files in your config directories were preserved."
log "Log out and select Hyprland from your display manager before testing the session."
log "Review the machine-specific monitor and NVIDIA settings documented in README.md."
log "Generated Matugen colour files are created locally when you apply a wallpaper."
