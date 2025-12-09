#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFEST_PATH="$SCRIPT_DIR/manifest.json"

copy_pairs=$(jq -r '.macos.copy[] | @json' "$MANIFEST_PATH")

while IFS= read -r pair; do
    src=$(echo "$pair" | jq -r '.[0]')
    dst=$(echo "$pair" | jq -r '.[1]')
    
    dst="${dst/#\~/$HOME}"
    
    dst_dir=$(dirname "$dst")
    mkdir -p "$dst_dir"
    
    cp "$SCRIPT_DIR/$src" "$dst"
    chmod +x "$dst"
    echo "Copied $src -> $dst"
done <<< "$copy_pairs"

aliases=$(jq -r '.macos.alias[]' "$MANIFEST_PATH" 2>/dev/null)

if [ -n "$aliases" ]; then
    while IFS= read -r alias_entry; do
        echo "Alias: $alias_entry"
    done <<< "$aliases"
fi

echo "Done!"
