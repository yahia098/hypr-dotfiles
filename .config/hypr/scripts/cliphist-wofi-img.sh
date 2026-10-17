
#!/usr/bin/env bash

# Clipboard history for Wofi with image thumbnails.
# Selected content is written to stdout; pipe this script to wl-copy.

set -o pipefail

thumb_dir="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbs"
mkdir -p "$thumb_dir" || exit 1

cliphist_list="$(cliphist list -fields id,format,preview)" || exit 1

# Remove cached thumbnails whose clipboard entries no longer exist.
for thumb in "$thumb_dir"/*; do
    [[ -f "$thumb" ]] || continue

    clip_id="${thumb##*/}"
    clip_id="${clip_id%.*}"

    if ! grep -qE "^${clip_id}[[:space:]]" <<< "$cliphist_list"; then
        rm -f -- "$thumb"
    fi
done

menu_file="$(mktemp)" || exit 1
trap 'rm -f "$menu_file"' EXIT

# Build the menu, preserving the empty format field for text entries.
while IFS= read -r line; do
    [[ -n "$line" && "$line" == *$'\t'* ]] || continue

    id="${line%%$'\t'*}"
    rest="${line#*$'\t'}"
    format="${rest%%$'\t'*}"
    preview="${rest#*$'\t'}"

    [[ "$id" =~ ^[0-9]+$ ]] || continue

    # Skip unwanted HTML metadata entries.
    [[ "$preview" == '<meta http-equiv='* ]] && continue

    if [[ -n "$format" ]]; then
        image="$thumb_dir/$id.$format"

        # Generate the thumbnail if it doesn't exist or is empty.
        if [[ ! -s "$image" ]]; then
            if ! cliphist decode "$id" |
                magick - -thumbnail '256x256>' "$image"; then
                rm -f -- "$image"
                printf '%s\tImage #%s (thumbnail unavailable)\n' \
                    "$id" "$id" >> "$menu_file"
                continue
            fi
        fi

        # Wofi needs a visible text label alongside the image.
        printf 'img:%s:text:Image #%s\n' "$image" "$id" >> "$menu_file"
    else
        # Keep the ID so cliphist can restore the exact original text.
        printf '%s\t%s\n' "$id" "$preview" >> "$menu_file"
    fi
done <<< "$cliphist_list"

# Show the picker. The long option avoids the previous -Dynamic_lines typo.
choice="$(
    wofi --allow-images --dmenu \
        --cache-file=/dev/null \
        --prompt="Clipboard" \
        --define=image_size=128 \
        < "$menu_file"
)"

# Exit cleanly if Wofi was cancelled.
[[ -n "$choice" ]] || exit 0

if [[ "$choice" == img:* ]]; then
    # Extract the thumbnail path, then recover its clipboard ID.
    image_path="${choice#img:}"
    image_path="${image_path%%:text:*}"
    filename="${image_path##*/}"
    clip_id="${filename%.*}"

    cliphist decode "$clip_id"
else
    cliphist decode <<< "$choice"
fi

