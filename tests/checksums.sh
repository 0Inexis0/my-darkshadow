#!/usr/bin/env bash
# Checks for install/checksums.txt: one list for every pinned download, readable by install.sh and by the scripts
# that fetch things later (rice-cursor). Adding a line is all it takes to allow a new file.
set -Euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

n=0
ok() { n=$((n + 1)); printf 'ok %d - %s\n' "$n" "$1"; }
bad() { printf 'not ok %d - %s\n' "$n" "$1"; exit 1; }

# every line is "<64 hex>  <name>", names are unique
awk 'NF && $1 !~ /^#/ { print NF, $1, $2 }' "$root/install/checksums.txt" >"$tmp/parsed"
[ -s "$tmp/parsed" ] && ok "the list has entries" || bad "checksums.txt is empty"
while read -r fields hash name; do
  [ "$fields" = 2 ] || bad "not two fields: $hash $name"
  case "$hash" in *[!0-9a-f]*|"") bad "not a lowercase SHA-256: $hash" ;; esac
  [ "${#hash}" = 64 ] || bad "not 64 characters: $hash"
done <"$tmp/parsed"
ok "every line is a SHA-256 and a file name"
dup="$(cut -d' ' -f3 "$tmp/parsed" | sort | uniq -d)"
[ -z "$dup" ] && ok "no duplicate names" || bad "duplicate names: $dup"

# rice-cursor reads the same list, and refuses what is not in it
cp "$root/install/checksums.txt" "$tmp/list"
printf '%s  local.bin\n' "$(printf 'x' | shasum -a 256 | cut -d' ' -f1)" >>"$tmp/list"
HOME="$tmp/home" RICE_CHECKSUMS="$tmp/list" python3 - "$root" <<'PY'
import importlib.machinery, importlib.util, os, sys
root = sys.argv[1]
loader = importlib.machinery.SourceFileLoader("rice_cursor_test", os.path.join(root, "bin", "rice-cursor"))
spec = importlib.util.spec_from_loader("rice_cursor_test", loader)
m = importlib.util.module_from_spec(spec)
loader.exec_module(m)
assert m.checksum_file() != "", "checksum_file found nothing"
assert m.expected_sha("local.bin"), "expected_sha did not read the pinned entry"
assert m.expected_sha("Bibata-Modern-Ice.tar.xz"), "expected_sha missed a shipped entry"
assert m.expected_sha("nothing-here.bin") == "", "expected_sha invented a hash"
assert m.get_bibata("Bibata-Modern-Amber") is False, "downloaded a theme with no pinned hash"
PY
[ $? = 0 ] && ok "rice-cursor uses the list and refuses unpinned files" || bad "rice-cursor checksum lookup"

# a broken line is ignored instead of turning into an empty hash
printf 'not-a-hash  broken.bin\n' >"$tmp/bad"
HOME="$tmp/home" RICE_CHECKSUMS="$tmp/bad" python3 - "$root" <<'PY' && ok "a malformed line is ignored" || bad "malformed line accepted"
import importlib.machinery, importlib.util, os, sys
root = sys.argv[1]
loader = importlib.machinery.SourceFileLoader("rice_cursor_bad", os.path.join(root, "bin", "rice-cursor"))
spec = importlib.util.spec_from_loader("rice_cursor_bad", loader)
m = importlib.util.module_from_spec(spec)
loader.exec_module(m)
assert m.expected_sha("broken.bin") == ""
PY

echo "# $n checks passed"
