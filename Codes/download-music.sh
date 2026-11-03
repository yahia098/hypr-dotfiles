#!/usr/bin/env bash
# Usage: dlmusic.sh <url> [more urls...]
# Optional cookies:
#   COOKIES_BROWSER=firefox dlmusic.sh <url>
#   COOKIES_FILE=~/cookies.txt dlmusic.sh <url>

set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: $0 <url> [url...]" >&2
    exit 1
fi

OUT_DIR="$HOME/Music"
mkdir -p "$OUT_DIR"

cookie_args=()
if [ -n "${COOKIES_FILE:-}" ]; then
    cookie_args=(--cookies "$COOKIES_FILE")
elif [ -n "${COOKIES_BROWSER:-}" ]; then
    cookie_args=(--cookies-from-browser "$COOKIES_BROWSER")
fi

yt-dlp \
    "${cookie_args[@]}" \
    -f "ba/b" \
    -x --audio-format best --audio-quality 0 \
    --embed-metadata --embed-thumbnail \
    -P "$OUT_DIR" \
    -o "%(playlist_title&{}/|)s%(playlist_index&{}_|)s%(uploader)s_%(title)s.%(ext)s" \
    "$@"
