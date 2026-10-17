#!/usr/bin/env bash

set -euo pipefail

download_dir="$HOME/Videos"
archive_dir="$HOME/.local/share/yt-dlp"
archive_file="$archive_dir/archive-video.txt"

for cmd in yt-dlp ffmpeg fd; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Error: '$cmd' is not installed." >&2
        exit 1
    }
done

mkdir -p "$download_dir"
mkdir -p "$archive_dir"

if [[ $# -eq 0 ]]; then
    echo "Usage: $(basename "$0") <URL> [URL ...]" >&2
    exit 1
fi

cookies_db="$(fd '^cookies\.sqlite$' "$HOME/.config/zen" | head -n1)"

if [[ -z "$cookies_db" ]]; then
    echo "Error: Could not find Zen cookies.sqlite." >&2
    exit 1
fi

profile_dir="$(dirname "$cookies_db")"

echo "Using Zen profile:"
echo "  $profile_dir"

for url in "$@"; do
    dest_dir="$download_dir"

    playlist_title="$(
        yt-dlp \
            --cookies-from-browser "firefox:$profile_dir" \
            --skip-download \
            --playlist-items 1 \
            --print playlist_title \
            -- \
            "$url" 2>/dev/null | head -n1
    )"

    if [[ -n "$playlist_title" && "$playlist_title" != "NA" ]]; then
        dest_dir="$download_dir/$playlist_title"
        mkdir -p "$dest_dir"
        echo "Playlist: $playlist_title"
    fi

    yt-dlp \
        --cookies-from-browser "firefox:$profile_dir" \
        -f "bestvideo+bestaudio/best" \
        --merge-output-format mkv \
        --embed-metadata \
        --embed-thumbnail \
        --convert-thumbnails jpg \
        --embed-chapters \
        --write-playlist-metafiles \
        --write-subs \
        --sub-langs "en,ja,ru" \
        --sub-format "vtt/best" \
        --download-archive "$archive_file" \
        --ignore-errors \
        --no-overwrites \
        --newline \
        --retries 10 \
        --fragment-retries 10 \
        -P "$dest_dir" \
        -o "%(playlist_index&{}_|)02d%(uploader)s_%(title)s.%(ext)s" \
        -- \
        "$url"
done
