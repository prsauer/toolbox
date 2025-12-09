#!/bin/bash

# Bootstrap: jq is required to parse the manifest
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: brew install jq"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFEST_PATH="$SCRIPT_DIR/manifest.json"

# Check requirements from manifest
failed=0
while IFS= read -r req; do
    if ! eval "$req" &> /dev/null; then
        echo "Requirement failed: $req"
        failed=1
    fi
done < <(jq -r '.macos.requirements[]' "$MANIFEST_PATH" 2>/dev/null)

if [ "$failed" -eq 1 ]; then
    echo "Install missing requirements and try again."
    exit 1
fi

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
