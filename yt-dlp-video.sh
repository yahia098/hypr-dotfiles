#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename "$0") <YouTube URL or Video ID>"
    exit 1
fi

DOWNLOAD_DIR="$HOME/Downloads/Videos"

mkdir -p "$DOWNLOAD_DIR"

if [[ "$1" == *"list="* ]]; then
    OUTPUT="$DOWNLOAD_DIR/%(channel)s_%(playlist_title|playlist)s/%(playlist_index)02d_%(title)s.%(ext)s"
else
    OUTPUT="$DOWNLOAD_DIR/%(channel)s_%(title)s.%(ext)s"
fi

yt-dlp \
    -f "bv*[height<=1080]+ba/b[height<=1080]" \
    --merge-output-format mkv \
    --write-subs \
    --write-auto-subs \
    --sub-langs "en,en-orig" \
    --write-description \
    --write-thumbnail \
    --embed-metadata \
    --restrict-filenames \
    -o "$OUTPUT" \
    "$1"
