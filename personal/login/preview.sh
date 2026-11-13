#!/usr/bin/env bash
set -euo pipefail
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
preview_dir=$(mktemp -d)
trap 'rm -rf -- "$preview_dir"' EXIT
python3 "$source_dir/sync-scale.py" \
    --settings "$HOME/.config/rice/hypr.json" \
    --theme "$source_dir/theme" --output "$preview_dir/theme"
sddm-greeter-qt6 --test-mode --theme "$preview_dir/theme"
