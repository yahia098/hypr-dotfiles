#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename "$0") <YouTube URL or Video ID>"
    exit 1
fi

DOWNLOAD_DIR="$HOME/Downloads/Music"

mkdir -p "$DOWNLOAD_DIR"

yt-dlp \
    -f "bestaudio/best" \
    --write-subs \
    --write-auto-subs \
    --sub-langs "en,en-orig" \
    --write-description \
    --write-thumbnail \
    --embed-metadata \
    --restrict-filenames \
    -o "$DOWNLOAD_DIR/%(channel)s_%(title)s.%(ext)s" \
    "$1"
