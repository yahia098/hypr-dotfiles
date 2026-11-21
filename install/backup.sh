
#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
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

# Return success if a path is equal to or contained within another path.
# Both arguments must be absolute, canonical paths.
path_is_same_or_below() {
  local candidate="$1"
  local parent="$2"

  if [[ "$parent" == "/" ]]; then
    [[ "$candidate" == /* ]]
  else
    [[ "$candidate" == "$parent" || "$candidate" == "$parent/"* ]]
  fi
}

while (($#)); do
  case "$1" in
    --output-dir)
      (($# >= 2)) || die "--output-dir requires a directory."
      [[ -n "$2" ]] || die "--output-dir cannot be empty."
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

# Basic validation.
[[ "$EUID" -ne 0 ]] ||
  die "Do not run this as root. Run it as the desktop user whose files you want to back up."

[[ "$HOME_DIR" == /* ]] ||
  die "HOME must be an absolute path."

[[ -d "$HOME_DIR" ]] ||
  die "Home directory does not exist: $HOME_DIR"

[[ -d "$SCRIPT_DIR/.config" ]] ||
  die "Cannot find the repository .config directory: $SCRIPT_DIR/.config"

command -v tar >/dev/null 2>&1 ||
  die "The tar command is required."

command -v realpath >/dev/null 2>&1 ||
  die "The realpath command is required."

command -v mktemp >/dev/null 2>&1 ||
  die "The mktemp command is required."

# Build the managed-path list from the repository.
# nullglob prevents an unmatched pattern from being returned literally.
# dotglob includes hidden top-level configuration directories.
shopt -s nullglob dotglob
repo_entries=("$SCRIPT_DIR/.config/"*)
shopt -u nullglob dotglob

((${#repo_entries[@]} > 0)) ||
  die "No configuration entries were found under $SCRIPT_DIR/.config."

managed_paths=()

for entry in "${repo_entries[@]}"; do
  managed_paths+=(".config/${entry##*/}")
done

if [[ -e "$SCRIPT_DIR/.zshrc" || -L "$SCRIPT_DIR/.zshrc" ]]; then
  managed_paths+=(".zshrc")
fi

# Identify which managed paths currently exist in HOME.
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

# Resolve the output directory without creating it.
if [[ "$OUTPUT_DIR" != /* ]]; then
  OUTPUT_DIR="$PWD/$OUTPUT_DIR"
fi

OUTPUT_DIR="$(realpath -m -- "$OUTPUT_DIR")" ||
  die "Could not resolve the output directory."

HOME_REAL="$(realpath -m -- "$HOME_DIR")" ||
  die "Could not resolve the home directory."

# Reject an existing non-directory destination.
if [[ -e "$OUTPUT_DIR" && ! -d "$OUTPUT_DIR" ]]; then
  die "Output destination exists but is not a directory: $OUTPUT_DIR"
fi

# Prevent the backup from being written inside a managed path.
# Check all managed paths, including those that do not exist yet.
# This prevents future backups from accidentally including previous backups.
for relative_path in "${managed_paths[@]}"; do
  managed_real="$(realpath -m -- "$HOME_REAL/$relative_path")" ||
    die "Could not resolve managed path: $relative_path"

  if path_is_same_or_below "$OUTPUT_DIR" "$managed_real"; then
    die "Output directory is inside a managed path:
  Managed path: $HOME_DIR/$relative_path
  Output path:  $OUTPUT_DIR

Choose a destination outside the configuration paths being backed up."
  fi
done

# Generate a unique archive and manifest name.
stamp="$(date '+%Y%m%d-%H%M%S')"
base="hypr-rice-backup-$stamp"
suffix=1

archive="$OUTPUT_DIR/$base.tar.gz"
manifest="$OUTPUT_DIR/$base.manifest.txt"

while [[ -e "$archive" || -L "$archive" ||
         -e "$manifest" || -L "$manifest" ]]; do
  base="hypr-rice-backup-$stamp-$suffix"

  archive="$OUTPUT_DIR/$base.tar.gz"
  manifest="$OUTPUT_DIR/$base.manifest.txt"

  suffix=$((suffix + 1))
done

# Display the backup plan.
log "The following ${#existing_paths[@]} path(s) will be archived:"

for relative_path in "${existing_paths[@]}"; do
  printf '  - %s\n' "$relative_path"
done

log "Archive destination: $archive"
log "Manifest destination: $manifest"

# Dry-run must not create directories or temporary files.
if ((DRY_RUN)); then
  log "DRY RUN: no directories or files were created, and nothing was read into an archive."
  exit 0
fi

# Create the destination directory.
mkdir -p -- "$OUTPUT_DIR"

# Use one isolated temporary directory for both files.
tmp_dir="$(mktemp -d "$OUTPUT_DIR/.${base}.XXXXXX")"
tmp_archive="$tmp_dir/backup.tar.gz"
tmp_manifest="$tmp_dir/backup.manifest.txt"

# Track whether the archive has been moved into its final location.
# If manifest creation or installation fails, remove the incomplete archive.
archive_committed=0

cleanup() {
  local status=$?

  if ((archive_committed)); then
    rm -f -- "$archive" ||
      warn "Could not remove incomplete archive: $archive"
  fi

  if [[ -n "${tmp_dir:-}" && -d "$tmp_dir" ]]; then
    rm -rf -- "$tmp_dir" ||
      warn "Could not remove temporary directory: $tmp_dir"
  fi

  return "$status"
}

trap cleanup EXIT

# Create the archive.
log "Creating compressed backup..."

tar -czvf "$tmp_archive" -C "$HOME_DIR" -- "${existing_paths[@]}"

# Create the manifest.
{
  printf 'Hyprland rice backup\n'
  printf 'Created: %s\n' "$(date --iso-8601=seconds)"
  printf 'Host: %s\n' "$(hostname 2>/dev/null || printf 'unknown')"
  printf 'Source repository: %s\n' "$SCRIPT_DIR"
  printf 'Home directory: %s\n\n' "$HOME_DIR"

  printf 'Archived paths (relative to HOME):\n'
  printf '  %s\n' "${existing_paths[@]}"

  printf '\nRestore command:\n'
  printf '  tar -xzvf %q -C %q\n' "$archive" "$HOME_DIR"
} > "$tmp_manifest"

# Move the completed files into their final locations.
# -n prevents overwriting files created by another process.
# -T treats the destination as an exact filename.
mv -nT -- "$tmp_archive" "$archive"

# GNU mv -n can return success without moving anything.
# Verify that the temporary source no longer exists.
[[ ! -e "$tmp_archive" && ! -L "$tmp_archive" ]] ||
  die "Archive destination appeared during backup. Refusing to overwrite it."

archive_committed=1

mv -nT -- "$tmp_manifest" "$manifest"

[[ ! -e "$tmp_manifest" && ! -L "$tmp_manifest" ]] ||
  die "Manifest destination appeared during backup. Refusing to overwrite it."

# Both files are now committed.
archive_committed=0

log "BACKUP COMPLETE."
log "Archive:  $archive"
log "Manifest: $manifest"

log "To restore, inspect the archive first, then extract it into HOME:"
printf '  tar -tzvf %q\n' "$archive"
printf '  tar -xzvf %q -C %q\n' "$archive" "$HOME_DIR"

