#!/usr/bin/env bash
# Usage: dlvideo.sh <url> [more urls...]
# Optional cookies (not tied to any browser):
#   COOKIES_BROWSER=firefox dlvideo.sh <url>   (or chromium, brave, zen, ...)
#   COOKIES_FILE=~/cookies.txt dlvideo.sh <url>

set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: $0 <url> [url...]" >&2
    exit 1
fi

OUT_DIR="$HOME/Videos"
mkdir -p "$OUT_DIR"

cookie_args=()
if [ -n "${COOKIES_FILE:-}" ]; then
    cookie_args=(--cookies "$COOKIES_FILE")
elif [ -n "${COOKIES_BROWSER:-}" ]; then
    cookie_args=(--cookies-from-browser "$COOKIES_BROWSER")
fi

yt-dlp \
    "${cookie_args[@]}" \
    -f "bv*+ba/b" \
    --merge-output-format mkv \
    --write-subs --write-auto-subs \
    --sub-langs "en.*,en" \
    --embed-subs \
    --embed-metadata \
    -P "$OUT_DIR" \
    -o "%(playlist_title&{}/|)s%(playlist_index&{}_|)s%(uploader)s_%(title)s.%(ext)s" \
    "$@"
