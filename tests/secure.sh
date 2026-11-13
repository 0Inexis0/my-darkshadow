#!/usr/bin/env bash
# Checks for install/lib/secure.sh: a download is used only when its SHA-256 matches the pinned one, and an
# archive cannot write outside the folder it is unpacked into. Runs anywhere (no Linux needed).
set -Euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

warn() { echo "  warn: $*" >&2; }
fail() { echo "  fail: $*" >&2; }
CHECKSUMS="$tmp/checksums.txt"
ROOT="$root"
# shellcheck source=../install/lib/secure.sh
. "$root/install/lib/secure.sh"

n=0
ok() { n=$((n + 1)); printf 'ok %d - %s\n' "$n" "$1"; }
bad() { printf 'not ok %d - %s\n' "$n" "$1"; exit 1; }

# sha256_of: same answer as the system tool
printf payload >"$tmp/f"
[ "$(sha256_of "$tmp/f")" = "$(shasum -a 256 "$tmp/f" | cut -d' ' -f1)" ] && ok "sha256_of" || bad "sha256_of"

# expected_sha: reads the pinned hash, and nothing for an unknown file
printf '%s  known.bin\n' "$(sha256_of "$tmp/f")" >"$CHECKSUMS"
[ "$(expected_sha known.bin)" = "$(sha256_of "$tmp/f")" ] && ok "expected_sha finds the pinned hash" || bad "expected_sha"
[ -z "$(expected_sha other.bin)" ] && ok "expected_sha is empty for an unknown file" || bad "expected_sha unknown"

# fetch_verified: a corrupted download is refused and deleted
printf 'not the pinned bytes' >"$tmp/bad.bin"
if fetch_verified "file://$tmp/bad.bin" "$tmp/dl.bin" known.bin; then bad "fetch_verified accepted a bad hash"; fi
[ ! -e "$tmp/dl.bin" ] && ok "fetch_verified refuses a bad hash and deletes it" || bad "fetch_verified left a bad file"

# fetch_verified: an unpinned name is never downloaded
if fetch_verified "file://$tmp/f" "$tmp/dl2.bin" other.bin; then bad "fetch_verified accepted an unpinned name"; fi
[ ! -e "$tmp/dl2.bin" ] && ok "fetch_verified refuses an unpinned name" || bad "fetch_verified downloaded unpinned"

# extract_verified: a normal archive lands inside DEST
mkdir -p "$tmp/src/pkg" && echo hi >"$tmp/src/pkg/file"
tar -cf "$tmp/good.tar" -C "$tmp/src" pkg
mkdir -p "$tmp/dest"
extract_verified "$tmp/good.tar" "$tmp/dest" && [ -f "$tmp/dest/pkg/file" ] && ok "extract_verified unpacks a good archive" \
  || bad "extract_verified failed on a good archive"

# extract_verified: ../ and absolute paths are refused
python3 - "$tmp/evil.tar" "$tmp/abs.tar" <<'PY'
import io, sys, tarfile
for path, name in ((sys.argv[1], "../escaped"), (sys.argv[2], "/tmp/escaped")):
    with tarfile.open(path, "w") as t:
        i = tarfile.TarInfo(name)
        i.size = 1
        t.addfile(i, io.BytesIO(b"x"))
PY
mkdir -p "$tmp/out"
if extract_verified "$tmp/evil.tar" "$tmp/out"; then bad "extract_verified accepted ../"; fi
[ ! -e "$tmp/escaped" ] && ok "extract_verified refuses ../ (nothing written)" || bad "extract_verified wrote outside"
if extract_verified "$tmp/abs.tar" "$tmp/out"; then bad "extract_verified accepted an absolute path"; fi
[ ! -e /tmp/escaped ] && ok "extract_verified refuses absolute paths" || { rm -f /tmp/escaped; bad "extract_verified wrote /tmp/escaped"; }

# install.sh stays parseable
bash -n "$root/install.sh" && ok "install.sh parses" || bad "install.sh syntax"

echo "# $n checks passed"
