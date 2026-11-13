#!/usr/bin/env bash
set -euo pipefail
profile="${1:-generic}"
case "$profile" in generic) output=iso ;; legion) output="iso-legion" ;; *) echo 'Use generic or legion' >&2; exit 2 ;; esac
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
python3 personal/check-publication.py
nix build ".#$output" --out-link "result-$profile" --print-build-logs
mkdir -p dist
for iso in "result-$profile"/iso/*.iso; do cp -L -- "$iso" dist/; done
cd dist
sha256sum my-darkshadow-*"$profile"-x86_64.iso > "SHA256SUMS-$profile"
for iso in my-darkshadow-*"$profile"-x86_64.iso; do
  python3 "$root/personal/package-release.py" --iso "$iso" --output release
done
echo "Built image and checksum in $root/dist"
