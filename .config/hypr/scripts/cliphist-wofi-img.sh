
#!/usr/bin/env bash

# Wofi clipboard picker with image and local-video thumbnails.
# Outputs the selected original clipboard item to stdout.

set -o pipefail

thumb_dir="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbs"
mkdir -p "$thumb_dir" || exit 1

# Use only ID and preview: format/MIME metadata may be unavailable.
cliphist_list="$(cliphist list -fields id,preview)" || exit 1

menu_file="$(mktemp)" || exit 1
trap 'rm -f "$menu_file"' EXIT

add_text() {
    printf '%s\t%s\n' "$1" "$2" >> "$menu_file"
}

add_image() {
    printf 'img:%s:text:%s\n' "$1" "$2" >> "$menu_file"
}

# Clean cached thumbnails for removed history entries.
for thumb in "$thumb_dir"/*; do
    [[ -f "$thumb" ]] || continue
    id="${thumb##*/}"
    id="${id%%.*}"

    if ! grep -qE "^${id}[[:space:]]" <<< "$cliphist_list"; then
        rm -f -- "$thumb"
    fi
done

# Extract the first local file:// URI, if the item is a file selection.
uri_to_path() {
    python3 -c '
import sys
from urllib.parse import urlparse, unquote

for line in sys.stdin:
    uri = urlparse(line.strip())
    if uri.scheme == "file" and uri.netloc in ("", "localhost"):
        print(unquote(uri.path))
        break
' 2>/dev/null
}

while IFS=$'\t' read -r id preview; do
    [[ "$id" =~ ^[0-9]+$ ]] || continue

    lower="${preview,,}"

    # Skip HTML metadata noise.
    [[ "$lower" == '<meta http-equiv='* ]] && continue

    # Local file selections: show an image or video preview while
    # preserving the original URI when the item is selected.
    if [[ "$lower" == *"file://"* ]]; then
        local_path="$(cliphist decode "$id" | uri_to_path)"

        if [[ -f "$local_path" ]]; then
            name="$(basename "$local_path")"
            ext="${local_path##*.}"
            ext="${ext,,}"

            case "$ext" in
                png|jpg|jpeg|gif|bmp|tif|tiff|webp)
                    thumb="$thumb_dir/$id.file.png"
                    if [[ ! -s "$thumb" ]]; then
                        magick "$local_path" -thumbnail '256x256>' "$thumb" 2>/dev/null ||
                            rm -f -- "$thumb"
                    fi
                    if [[ -s "$thumb" ]]; then
                        add_image "$thumb" "Image: $name"
                    else
                        add_text "$id" "Image file: $name"
                    fi
                    continue
                    ;;
                mp4|mkv|webm|mov|avi|m4v|ogv|mpeg|mpg|wmv|flv)
                    thumb="$thumb_dir/$id.video.jpg"
                    if [[ ! -s "$thumb" ]]; then
                        ffmpeg -hide_banner -loglevel error -y \
                            -i "$local_path" -frames:v 1 \
                            -vf 'scale=256:256:force_original_aspect_ratio=decrease' \
                            "$thumb" </dev/null 2>/dev/null ||
                            rm -f -- "$thumb"
                    fi
                    if [[ -s "$thumb" ]]; then
                        add_image "$thumb" "Video: $name"
                    else
                        add_text "$id" "Video file: $name"
                    fi
                    continue
                    ;;
            esac
        fi
    fi

    # Detect cliphist image previews:
    # [[ binary data 506 KiB png 1920x1080 ]]
    image_re='\[\[[[:space:]]binary data .*([[:space:]])(png|jpeg|jpg|gif|bmp|tiff|tif|webp)[[:space:]]+[0-9]+x[0-9]+[[:space:]]+\]\]'

    if [[ "$lower" =~ $image_re ]]; then
        format="${BASH_REMATCH[2]}"
        [[ "$format" == "jpeg" ]] && format="jpg"

        thumb="$thumb_dir/$id.$format"

        if [[ ! -s "$thumb" ]]; then
            cliphist decode "$id" |
                magick - -thumbnail '256x256>' "$thumb" 2>/dev/null ||
                rm -f -- "$thumb"
        fi

        if [[ -s "$thumb" ]]; then
            add_image "$thumb" "Image #$id"
        else
            add_text "$id" "Image #$id (thumbnail unavailable)"
        fi
        continue
    fi

    # Ordinary text remains readable; other binary content gets a label.
    if [[ "$lower" == *"binary data"* ]]; then
        add_text "$id" "Binary clipboard item #$id"
    else
        add_text "$id" "$preview"
    fi
done <<< "$cliphist_list"

choice="$(
    wofi --allow-images --dmenu \
        --cache-file=/dev/null \
        --prompt="Clipboard" \
        -I -Dimage_size=128 -Ddynamic_lines=true \
        < "$menu_file"
)"

# Cancel leaves the current clipboard alone.
[[ -n "$choice" ]] || exit 0

# Recover the original clipboard ID from the chosen row.
if [[ "$choice" == img:* ]]; then
    image_path="${choice#img:}"
    image_path="${image_path%%:text:*}"
    filename="${image_path##*/}"
    id="${filename%%.*}"
else
    id="${choice%%$'\t'*}"
fi

[[ "$id" =~ ^[0-9]+$ ]] || exit 1

cliphist decode "$id"

