#!/usr/bin/env bash
set -Eeuo pipefail

# Back up only the paths managed by this repository. The archive can be
# extracted directly into $HOME to restore the previous configuration.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME:?HOME is not set}"
OUTPUT_DIR="${XDG_STATE_HOME:-$HOME_DIR/.local/state}/hypr-dotfiles/backups"
DRY_RUN=0

log()  { printf '[BACKUP] %s\n' "$*"; }
warn() { printf '[BACKUP] WARNING: %s\n' "$*" >&2; }
die()  { printf '[BACKUP] ERROR: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<USAGE
Usage: $(basename -- "$0") [OPTIONS]

Create a timestamped archive of the configuration paths deployed by this
repository. Existing files are read only; nothing in HOME is changed.

Options:
  --output-dir DIR  Store the archive and manifest in DIR.
                    Default: \$XDG_STATE_HOME/hypr-dotfiles/backups or
                             ~/.local/state/hypr-dotfiles/backups
  --dry-run         Show what would be backed up without creating files.
  -h, --help        Show this help.

The archive contains paths relative to HOME (for example .config/hypr and
.zshrc), so it can be restored with: tar -xzvf ARCHIVE -C "$HOME_DIR"
USAGE
}

while (($#)); do
  case "$1" in
    --output-dir)
      (($# >= 2)) || die "--output-dir requires a directory."
      OUTPUT_DIR="$2"
      shift 2
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

[[ "$EUID" -ne 0 ]] || die "Do not run this as root. Run it as the desktop user whose files you want to back up."
[[ -d "$SCRIPT_DIR/.config" ]] || die "Cannot find the repository .config directory: $SCRIPT_DIR/.config"
command -v tar >/dev/null 2>&1 || die "The tar command is required."

# Build the managed-path list from this repository so new top-level config
# directories are automatically included in future backups and deployments.
mapfile -d '' -t repo_entries < <(find "$SCRIPT_DIR/.config" -mindepth 1 -maxdepth 1 -print0 | sort -z)
((${#repo_entries[@]} > 0)) || die "No configuration entries were found under $SCRIPT_DIR/.config."

managed_paths=()
for entry in "${repo_entries[@]}"; do
  managed_paths+=(".config/${entry##*/}")
done
if [[ -e "$SCRIPT_DIR/.zshrc" || -L "$SCRIPT_DIR/.zshrc" ]]; then
  managed_paths+=(".zshrc")
fi

existing_paths=()
log "Repository: $SCRIPT_DIR"
log "Home directory: $HOME_DIR"
log "Checking ${#managed_paths[@]} managed path(s) in your home directory..."
for relative_path in "${managed_paths[@]}"; do
  if [[ -e "$HOME_DIR/$relative_path" || -L "$HOME_DIR/$relative_path" ]]; then
    log "FOUND  $HOME_DIR/$relative_path"
    existing_paths+=("$relative_path")
  else
    log "SKIP   $HOME_DIR/$relative_path (does not exist)"
  fi
done

if ((${#existing_paths[@]} == 0)); then
  log "Nothing to back up. None of the rice's managed paths currently exist in HOME."
  exit 0
fi

if [[ "$OUTPUT_DIR" != /* ]]; then
  OUTPUT_DIR="$PWD/$OUTPUT_DIR"
fi

stamp="$(date '+%Y%m%d-%H%M%S')"
base="hypr-rice-backup-$stamp"
archive="$OUTPUT_DIR/$base.tar.gz"
suffix=1
while [[ -e "$archive" ]]; do
  archive="$OUTPUT_DIR/$base-$suffix.tar.gz"
  ((suffix += 1))
done
manifest="${archive%.tar.gz}.manifest.txt"

log "The following ${#existing_paths[@]} path(s) will be archived:"
for relative_path in "${existing_paths[@]}"; do
  printf '  - %s\n' "$relative_path"
done
log "Archive destination: $archive"
log "Manifest destination: $manifest"

if ((DRY_RUN)); then
  log "DRY RUN: no directories or files were created, and nothing was read into an archive."
  exit 0
fi

mkdir -p -- "$OUTPUT_DIR"
tmp_archive="$(mktemp "$OUTPUT_DIR/.${base}.XXXXXX.tar.gz")"
tmp_manifest="$(mktemp "$OUTPUT_DIR/.${base}.XXXXXX.manifest")"
cleanup() {
  [[ -z "${tmp_archive:-}" ]] || rm -f -- "$tmp_archive"
  [[ -z "${tmp_manifest:-}" ]] || rm -f -- "$tmp_manifest"
}
trap cleanup EXIT

log "Creating compressed backup..."
tar -czvf "$tmp_archive" -C "$HOME_DIR" -- "${existing_paths[@]}"

{
  printf 'Hyprland rice backup\n'
  printf 'Created: %s\n' "$(date --iso-8601=seconds)"
  printf 'Host: %s\n' "$(hostname 2>/dev/null || printf 'unknown')"
  printf 'Source repository: %s\n' "$SCRIPT_DIR"
  printf 'Home directory: %s\n\n' "$HOME_DIR"
  printf 'Archived paths (relative to HOME):\n'
  printf '  %s\n' "${existing_paths[@]}"
  printf '\nRestore command:\n  tar -xzvf %q -C %q\n' "$archive" "$HOME_DIR"
} > "$tmp_manifest"

mv -- "$tmp_archive" "$archive"
tmp_archive=""
mv -- "$tmp_manifest" "$manifest"
tmp_manifest=""
trap - EXIT

log "BACKUP COMPLETE."
log "Archive:  $archive"
log "Manifest: $manifest"
log "To restore, inspect the archive first, then extract it into HOME:"
printf '  tar -tzvf %q\n' "$archive"
printf '  tar -xzvf %q -C %q\n' "$archive" "$HOME_DIR"
