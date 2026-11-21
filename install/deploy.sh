
#!/usr/bin/env bash
set -Eeuo pipefail

# Deploy the .config entries and auxiliary files shipped by this repository.
# Existing managed paths are backed up first.
# Deployment merges directories and never deletes unrelated files.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
HOME_DIR="${HOME:?HOME is not set}"

ASSUME_YES=0
DRY_RUN=0

export LC_ALL=C

log()  { printf '[DEPLOY] %s\n' "$*"; }
warn() { printf '[DEPLOY] WARNING: %s\n' "$*" >&2; }
die()  { printf '[DEPLOY] ERROR: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<USAGE
Usage: $(basename -- "$0") [OPTIONS]

Deploy this repository's configuration into your home directory.

Options:
  -y, --yes       Skip the confirmation prompt. A backup is still created.
  --dry-run       Print the complete deployment plan without changing anything.
  -h, --help      Show this help.

What it deploys:
  .config/*         Every top-level file/directory under repository .config
  .zshrc            Repository zsh configuration, when present
  Codes/            Helper scripts (merged into ~/Codes)
  Pictures/pfp.png  Avatar for Hyprlock/Fastfetch (only if missing)
  Theme             Generates the initial Matugen palette if needed

Safety behavior:
  - Runs backup.sh before copying anything.
  - Verifies backup coverage for existing auxiliary paths.
  - Merges directories without deleting unrelated files.
  - Replaces matching files after creating a backup.
  - Rejects symlinked destination roots and matching nested destinations.
  - Validates destination types before deployment.
  - Does not install packages, enable services, or alter the login manager.
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

# ------------------------------------------------------------
# 1. BASIC VALIDATION
# ------------------------------------------------------------

[[ "$EUID" -ne 0 ]] ||
  die "Do not run this as root. Run it as the desktop user whose HOME should receive the rice."

command -v realpath >/dev/null 2>&1 ||
  die "The realpath command is required."

command -v cp >/dev/null 2>&1 ||
  die "The cp command is required."

command -v grep >/dev/null 2>&1 ||
  die "The grep command is required."

[[ -d "$HOME_DIR" ]] ||
  die "Home directory does not exist: $HOME_DIR"

HOME_DIR="$(realpath -e -- "$HOME_DIR")"
export HOME="$HOME_DIR"

[[ -d "$SCRIPT_DIR/.config" && ! -L "$SCRIPT_DIR/.config" ]] ||
  die "Cannot find a valid repository .config directory: $SCRIPT_DIR/.config"

[[ -f "$SCRIPT_DIR/backup.sh" && ! -L "$SCRIPT_DIR/backup.sh" ]] ||
  die "backup.sh is missing or is a symbolic link."

# Include hidden top-level configuration entries.
shopt -s nullglob dotglob

repo_entries=("$SCRIPT_DIR/.config/"*)

((${#repo_entries[@]} > 0)) ||
  die "No configuration entries were found under $SCRIPT_DIR/.config."

# ------------------------------------------------------------
# 2. SHARED VALIDATION HELPERS
# ------------------------------------------------------------

path_exists() {
  [[ -e "$1" || -L "$1" ]]
}

# Validate an existing directory root before writing into it.
assert_safe_directory() {
  local path="$1"
  local description="$2"

  [[ ! -L "$path" ]] ||
    die "$description is a symbolic link: $path"

  if [[ -e "$path" && ! -d "$path" ]]; then
    die "$description exists but is not a directory: $path"
  fi
}

# Validate every source entry and its matching destination.
# Recursion catches nested type conflicts and destination symlinks
# before cp starts modifying anything.
validate_merge_tree() {
  local source_dir="$1"
  local destination_dir="$2"

  local entry
  local name
  local target

  local -a children=("$source_dir/"*)

  for entry in "${children[@]}"; do
    name="${entry##*/}"
    target="$destination_dir/$name"

    if [[ -L "$target" ]]; then
      die "Destination contains a symbolic link:
  Source:      $entry
  Destination: $target"
    fi

    if [[ -L "$entry" ]]; then
      # Source symlinks are preserved by cp -a.
      if [[ -e "$target" && -d "$target" ]]; then
        die "Cannot deploy a symbolic link over a directory:
  Source:      $entry
  Destination: $target"
      fi

    elif [[ -d "$entry" ]]; then
      if [[ -e "$target" && ! -d "$target" ]]; then
        die "Cannot merge directory into non-directory:
  Source:      $entry
  Destination: $target"
      fi

      validate_merge_tree "$entry" "$target"

    elif [[ -f "$entry" ]]; then
      if [[ -e "$target" && ! -f "$target" ]]; then
        die "Cannot copy file over non-file destination:
  Source:      $entry
  Destination: $target"
      fi

    else
      die "Unsupported source entry type: $entry"
    fi
  done
}

# Validate a top-level repository entry against its destination.
validate_entry() {
  local source="$1"
  local destination="$2"

  if [[ -L "$destination" ]]; then
    die "Destination is a symbolic link: $destination"
  fi

  if [[ -L "$source" ]]; then
    if [[ -e "$destination" && -d "$destination" ]]; then
      die "Cannot deploy a symbolic link over a directory: $destination"
    fi

  elif [[ -d "$source" ]]; then
    if [[ -e "$destination" && ! -d "$destination" ]]; then
      die "Cannot merge directory into non-directory: $destination"
    fi

    validate_merge_tree "$source" "$destination"

  elif [[ -f "$source" ]]; then
    if [[ -e "$destination" && ! -f "$destination" ]]; then
      die "Cannot overwrite non-file destination: $destination"
    fi

  else
    die "Unsupported repository entry type: $source"
  fi
}

# Check a file Matugen might overwrite.
validate_generated_output() {
  local relative_path="$1"
  local target="$HOME_DIR/$relative_path"
  local parent="${target%/*}"

  [[ ! -L "$parent" ]] ||
    die "Matugen output directory is a symbolic link: $parent"

  if [[ -e "$parent" && ! -d "$parent" ]]; then
    die "Matugen output parent is not a directory: $parent"
  fi

  [[ ! -L "$target" ]] ||
    die "Matugen output is a symbolic link: $target"

  if [[ -e "$target" && ! -f "$target" ]]; then
    die "Matugen output exists but is not a regular file: $target"
  fi
}

# Locate a supported wallpaper without following symlinks.
first_supported_wallpaper() {
  local directory="$1"
  local entry
  local extension

  local -a candidates=()

  [[ -d "$directory" && ! -L "$directory" ]] || return 1

  candidates=("$directory/"*)

  for entry in "${candidates[@]}"; do
    [[ -f "$entry" && ! -L "$entry" ]] || continue

    extension="${entry##*.}"
    extension="${extension,,}"

    case "$extension" in
      png|jpg|jpeg|webp)
        printf '%s\n' "$entry"
        return 0
        ;;
    esac
  done

  return 1
}

# Check whether a supported wallpaper exists before deployment.
has_supported_wallpaper() {
  local directory

  for directory in \
    "$SCRIPT_DIR/.config/wallpapers" \
    "$HOME_DIR/.config/wallpapers"; do

    if first_supported_wallpaper "$directory" >/dev/null; then
      return 0
    fi
  done

  return 1
}

# ------------------------------------------------------------
# 3. DISCOVER AUXILIARY FILES
# ------------------------------------------------------------

HAVE_ZSHRC=0
HAVE_CODES=0
HAVE_AVATAR=0

if [[ -e "$SCRIPT_DIR/.zshrc" || -L "$SCRIPT_DIR/.zshrc" ]]; then
  [[ -f "$SCRIPT_DIR/.zshrc" && ! -L "$SCRIPT_DIR/.zshrc" ]] ||
    die "Repository .zshrc must be a regular file."

  HAVE_ZSHRC=1
fi

if [[ -e "$SCRIPT_DIR/Codes" || -L "$SCRIPT_DIR/Codes" ]]; then
  [[ -d "$SCRIPT_DIR/Codes" && ! -L "$SCRIPT_DIR/Codes" ]] ||
    die "Repository Codes must be a real directory."

  HAVE_CODES=1
fi

if [[ -e "$SCRIPT_DIR/Pictures" || -L "$SCRIPT_DIR/Pictures" ]]; then
  [[ -d "$SCRIPT_DIR/Pictures" && ! -L "$SCRIPT_DIR/Pictures" ]] ||
    die "Repository Pictures must be a real directory."
fi

if [[ -e "$SCRIPT_DIR/Pictures/pfp.png" || -L "$SCRIPT_DIR/Pictures/pfp.png" ]]; then
  [[ -f "$SCRIPT_DIR/Pictures/pfp.png" && ! -L "$SCRIPT_DIR/Pictures/pfp.png" ]] ||
    die "Repository Pictures/pfp.png must be a regular file."

  HAVE_AVATAR=1
fi

# ------------------------------------------------------------
# 4. VALIDATE CONFIG DESTINATIONS
# ------------------------------------------------------------

assert_safe_directory "$HOME_DIR/.config" "Configuration root"

log "Checking repository configuration entries..."

for source in "${repo_entries[@]}"; do
  name="${source##*/}"
  destination="$HOME_DIR/.config/$name"

  validate_entry "$source" "$destination"

  log "VALID  $source -> $destination"
done

# ------------------------------------------------------------
# 5. VALIDATE ZSH DESTINATION
# ------------------------------------------------------------

if ((HAVE_ZSHRC)); then
  destination="$HOME_DIR/.zshrc"

  [[ ! -L "$destination" ]] ||
    die "$destination is a symbolic link. Resolve it manually first."

  if [[ -e "$destination" && ! -f "$destination" ]]; then
    die "$destination exists but is not a regular file."
  fi

  log "VALID  .zshrc -> $destination"
else
  warn "No repository .zshrc exists. Current shell configuration will be left alone."
fi

# ------------------------------------------------------------
# 6. VALIDATE CODES DESTINATION
# ------------------------------------------------------------

if ((HAVE_CODES)); then
  destination="$HOME_DIR/Codes"

  assert_safe_directory "$destination" "Codes destination"

  if [[ -d "$destination" ]]; then
    validate_merge_tree "$SCRIPT_DIR/Codes" "$destination"
  fi

  log "VALID  Codes -> $destination"
fi

# ------------------------------------------------------------
# 7. VALIDATE AVATAR DESTINATION
# ------------------------------------------------------------

AVATAR_ACTION="skip"

if ((HAVE_AVATAR)); then
  assert_safe_directory "$HOME_DIR/Pictures" "Pictures destination"

  avatar_destination="$HOME_DIR/Pictures/pfp.png"

  [[ ! -L "$avatar_destination" ]] ||
    die "Avatar destination is a symbolic link: $avatar_destination"

  if [[ -e "$avatar_destination" ]]; then
    [[ -f "$avatar_destination" ]] ||
      die "Avatar destination exists but is not a regular file."

    AVATAR_ACTION="keep"
  else
    AVATAR_ACTION="copy"
  fi
fi

# ------------------------------------------------------------
# 8. DETERMINE MATUGEN ACTION
# ------------------------------------------------------------

THEME_DIR="$HOME_DIR/.config/theme"
THEME_CSS="$THEME_DIR/colors.css"

MATUGEN_ACTION="skip"

# Reject unexpected output paths even when the palette already exists.
[[ ! -L "$THEME_DIR" ]] ||
  die "Matugen theme directory is a symbolic link: $THEME_DIR"

[[ ! -L "$THEME_CSS" ]] ||
  die "Matugen colors.css is a symbolic link: $THEME_CSS"

if [[ -e "$THEME_DIR" && ! -d "$THEME_DIR" ]]; then
  die "Matugen theme path is not a directory: $THEME_DIR"
fi

if [[ -e "$THEME_CSS" && ! -f "$THEME_CSS" ]]; then
  die "Matugen colors.css exists but is not a regular file."
fi

if [[ -f "$THEME_CSS" ]]; then
  MATUGEN_ACTION="existing"

elif ! command -v matugen >/dev/null 2>&1; then
  MATUGEN_ACTION="missing"

elif has_supported_wallpaper; then
  MATUGEN_ACTION="generate"

else
  MATUGEN_ACTION="no_wallpaper"
fi

# Validate every configured Matugen output before generating a palette.
# Most of these locations are already covered by .config backups.
if [[ "$MATUGEN_ACTION" == "generate" ]]; then

  matugen_outputs=(
    ".config/kitty/matugen-colors.conf"
    ".config/theme/colors.css"
    ".config/yazi/theme.toml"
    ".config/hypr/matugen-lock.conf"
    ".config/mako/config"
    ".config/gtk-3.0/colors.css"
    ".config/gtk-4.0/colors.css"
    ".config/matugen/templates/colors-nvim.json"
    ".config/dunst/dunstrc"
    ".config/eww/colors.scss"
  )

  for relative_path in "${matugen_outputs[@]}"; do
    validate_generated_output "$relative_path"
  done
fi

# ------------------------------------------------------------
# 9. VERIFY BACKUP COVERAGE
# ------------------------------------------------------------

log "Checking backup script and backup coverage..."

BACKUP_PREVIEW="$(bash "$SCRIPT_DIR/backup.sh" --dry-run)" ||
  die "backup.sh failed its dry-run check. Resolve the problem before deploying."

# The backup script must explicitly report existing paths that this
# deployment or Matugen may overwrite outside normal repository entries.
require_backup_coverage() {
  local relative_path="$1"
  local expected="[BACKUP] FOUND  $HOME_DIR/$relative_path"

  if ! grep -Fq -- "$expected" <<< "$BACKUP_PREVIEW"; then
    die "Existing path is not covered by backup.sh:
  $HOME_DIR/$relative_path

Update backup.sh to include this path before deploying."
  fi

  log "BACKUP OK  $HOME_DIR/$relative_path"
}

# Codes is merged and matching files can be overwritten.
if ((HAVE_CODES)) && path_exists "$HOME_DIR/Codes"; then
  require_backup_coverage "Codes"
fi

# Matugen can overwrite the existing Dunst configuration.
# It is not shipped as a repository .config entry.
if [[ "$MATUGEN_ACTION" == "generate" ]] &&
   [[ -f "$HOME_DIR/.config/dunst/dunstrc" ]]; then
  require_backup_coverage ".config/dunst"
fi

# ------------------------------------------------------------
# 10. DISPLAY COMPLETE DEPLOYMENT PLAN
# ------------------------------------------------------------

log "============================================================"
log "HYPRLAND RICE DEPLOYMENT PLAN"
log "============================================================"

log "Repository:     $SCRIPT_DIR"
log "Destination:    $HOME_DIR"
log "Config entries: ${#repo_entries[@]}"
log "Copy strategy:  merge and overwrite matching files"
log "Backup:         verified before deployment"

printf '\n'

for source in "${repo_entries[@]}"; do
  name="${source##*/}"
  log "PLAN  $source -> $HOME_DIR/.config/$name"
done

if ((HAVE_ZSHRC)); then
  log "PLAN  .zshrc -> $HOME_DIR/.zshrc"
fi

if ((HAVE_CODES)); then
  log "PLAN  Codes/ -> $HOME_DIR/Codes/"
fi

case "$AVATAR_ACTION" in
  copy)
    log "PLAN  Pictures/pfp.png -> $HOME_DIR/Pictures/pfp.png"
    ;;
  keep)
    log "KEEP  Existing avatar: $HOME_DIR/Pictures/pfp.png"
    ;;
  skip)
    log "SKIP  No repository avatar found."
    ;;
esac

case "$MATUGEN_ACTION" in
  generate)
    log "PLAN  Generate initial Matugen palette from the first supported wallpaper."
    ;;
  existing)
    log "KEEP  Existing Matugen palette: $THEME_CSS"
    ;;
  missing)
    warn "Matugen is not installed. Palette generation will be skipped."
    ;;
  no_wallpaper)
    warn "No supported wallpaper found. Apply one after deployment."
    ;;
esac

printf '\n'

if ((DRY_RUN)); then
  log "============================================================"
  log "BACKUP DRY RUN"
  log "============================================================"

  printf '%s\n' "$BACKUP_PREVIEW"

  log "============================================================"
  log "DRY RUN COMPLETE"
  log "============================================================"
  log "No backup, configuration, or destination files were created or modified."

  exit 0
fi

# ------------------------------------------------------------
# 11. CONFIRMATION
# ------------------------------------------------------------

if ((!ASSUME_YES)); then
  warn "Matching configuration files may be overwritten."
  warn "A backup will be created first."
  warn "Unrelated files will not be deleted."

  [[ -t 0 ]] ||
    die "No interactive terminal is available. Review the plan and rerun with --yes."

  printf '\n'

  read -r -p "Deploy this rice into $HOME_DIR? [y/N] " answer

  case "$answer" in
    y|Y|yes|YES|Yes)
      ;;
    *)
      log "Cancelled. No files were changed."
      exit 0
      ;;
  esac
fi

# ------------------------------------------------------------
# 12. BACKUP
# ------------------------------------------------------------

log "============================================================"
log "STEP 1/5 — BACK UP EXISTING CONFIGURATION"
log "============================================================"

bash "$SCRIPT_DIR/backup.sh"

log "Backup completed. Starting deployment."

# ------------------------------------------------------------
# 13. DEPLOY CONFIGURATION DIRECTORIES
# ------------------------------------------------------------

log "============================================================"
log "STEP 2/5 — DEPLOY CONFIGURATION DIRECTORIES"
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

# ------------------------------------------------------------
# 14. DEPLOY ZSH
# ------------------------------------------------------------

log "============================================================"
log "STEP 3/5 — DEPLOY ZSH CONFIGURATION"
log "============================================================"

if ((HAVE_ZSHRC)); then
  cp -av -- "$SCRIPT_DIR/.zshrc" "$HOME_DIR/.zshrc"
  log "Completed: $HOME_DIR/.zshrc"
else
  log "Skipped: repository does not contain .zshrc."
fi

# ------------------------------------------------------------
# 15. DEPLOY AUXILIARY FILES
# ------------------------------------------------------------

log "============================================================"
log "STEP 4/5 — DEPLOY HELPER SCRIPTS AND AVATAR"
log "============================================================"

if ((HAVE_CODES)); then
  mkdir -p -- "$HOME_DIR/Codes"
  cp -av -- "$SCRIPT_DIR/Codes/." "$HOME_DIR/Codes/"
  log "Completed: $HOME_DIR/Codes"
fi

if [[ "$AVATAR_ACTION" == "copy" ]]; then
  mkdir -p -- "$HOME_DIR/Pictures"

  cp -av -- \
    "$SCRIPT_DIR/Pictures/pfp.png" \
    "$HOME_DIR/Pictures/pfp.png"

  log "Completed: $HOME_DIR/Pictures/pfp.png"

elif [[ "$AVATAR_ACTION" == "keep" ]]; then
  log "Existing avatar preserved."
fi

# ------------------------------------------------------------
# 16. INITIALIZE MATUGEN
# ------------------------------------------------------------

log "============================================================"
log "STEP 5/5 — INITIALIZE MATUGEN THEME"
log "============================================================"

case "$MATUGEN_ACTION" in
  generate)
    first_wallpaper="$(
      first_supported_wallpaper "$HOME_DIR/.config/wallpapers" || true
    )"

    if [[ -n "$first_wallpaper" ]]; then
      log "Initial wallpaper: $first_wallpaper"
      log "Generating Matugen palette..."

      matugen image "$first_wallpaper" \
        --type scheme-smart \
        --source-color-index 1 ||
        warn "Matugen failed. Apply a wallpaper manually after login."

    else
      warn "No supported wallpaper found after deployment."
      warn "Apply a wallpaper manually to generate the initial palette."
    fi
    ;;

  existing)
    log "Matugen outputs already exist. Leaving them untouched."
    ;;

  missing)
    warn "matugen is not installed. Run install/rice.sh, then apply a wallpaper."
    ;;

  no_wallpaper)
    warn "No supported wallpapers found. Apply one after login."
    ;;
esac

# ------------------------------------------------------------
# 17. COMPLETION
# ------------------------------------------------------------

log "============================================================"
log "DEPLOYMENT COMPLETE"
log "============================================================"

log "Configuration files have been copied."
log "Untracked files in configuration directories were preserved."

log "Log out and select Hyprland from your display manager before testing."
log "Review the machine-specific monitor and NVIDIA settings in README.md."

log "Matugen colour files are regenerated whenever you apply a wallpaper."

