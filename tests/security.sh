#!/usr/bin/env bash
# Checks for the security helpers in install/lib/secure.sh, the pinned hashes in install/checksums.txt and the
# update guards. Runs anywhere (no Linux, no network) and in CI on every push.
set -Euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

warn() { echo "  warn: $*" >&2; }
fail() { echo "  fail: $*" >&2; }
ROOT="$tmp/repo"
CHECKSUMS="$root/install/checksums.txt"
# shellcheck source=../install/lib/secure.sh
. "$root/install/lib/secure.sh"

n=0
ok() { n=$((n + 1)); printf 'ok %d - %s\n' "$n" "$1"; }
bad() { printf 'not ok %d - %s\n' "$n" "$1"; exit 1; }

# ---- the checksum list: "<64 hex>  <name>", unique names
awk 'NF && $1 !~ /^#/ { print NF, $1, $2 }' "$CHECKSUMS" >"$tmp/list"
[ -s "$tmp/list" ] && ok "checksums.txt has entries" || bad "checksums.txt is empty"
while read -r fields hash name; do
  [ "$fields" = 2 ] || bad "not two fields: $hash $name"
  case "$hash" in *[!0-9a-f]*|"") bad "not a lowercase SHA-256: $hash" ;; esac
  [ "${#hash}" = 64 ] || bad "not 64 characters: $hash"
done <"$tmp/list"
ok "every line is a SHA-256 and a file name"
[ -z "$(cut -d' ' -f3 "$tmp/list" | sort | uniq -d)" ] && ok "no duplicate names" || bad "duplicate names"

# ---- the helpers: pinned name, bad hash, no pin, archive paths
printf payload >"$tmp/f"
[ "$(sha256_of "$tmp/f")" = "$(printf payload | shasum -a 256 | cut -d' ' -f1)" ] && ok "sha256_of" || bad "sha256_of"
printf '%s  known.bin\n' "$(sha256_of "$tmp/f")" >"$tmp/own.txt"
CHECKSUMS="$tmp/own.txt"
[ "$(expected_sha known.bin)" = "$(sha256_of "$tmp/f")" ] && ok "expected_sha finds the pinned hash" || bad "expected_sha"
[ -z "$(expected_sha other.bin)" ] && ok "expected_sha is empty for an unknown file" || bad "expected_sha unknown"
printf 'not the pinned bytes' >"$tmp/bad.bin"
fetch_verified "file://$tmp/bad.bin" "$tmp/dl.bin" known.bin && bad "fetch_verified accepted a bad hash"
[ ! -e "$tmp/dl.bin" ] && ok "fetch_verified refuses a bad hash and deletes it" || bad "fetch_verified left a bad file"
fetch_verified "file://$tmp/f" "$tmp/dl2.bin" other.bin && bad "fetch_verified accepted an unpinned name"
[ ! -e "$tmp/dl2.bin" ] && ok "fetch_verified refuses an unpinned name" || bad "fetch_verified downloaded unpinned"

mkdir -p "$tmp/src/pkg" && echo hi >"$tmp/src/pkg/file"
tar -cf "$tmp/good.tar" -C "$tmp/src" pkg
mkdir -p "$tmp/dest"
extract_verified "$tmp/good.tar" "$tmp/dest" && [ -f "$tmp/dest/pkg/file" ] && ok "extract_verified unpacks a good archive" \
  || bad "extract_verified failed on a good archive"
python3 - "$tmp/evil.tar" "$tmp/abs.tar" <<'PY'
import io, sys, tarfile
for path, name in ((sys.argv[1], "../escaped"), (sys.argv[2], "/tmp/escaped")):
    with tarfile.open(path, "w") as t:
        i = tarfile.TarInfo(name)
        i.size = 1
        t.addfile(i, io.BytesIO(b"x"))
PY
mkdir -p "$tmp/out"
extract_verified "$tmp/evil.tar" "$tmp/out" && bad "extract_verified accepted ../"
[ ! -e "$tmp/escaped" ] && ok "extract_verified refuses ../ (nothing written)" || bad "extract_verified wrote outside"
extract_verified "$tmp/abs.tar" "$tmp/out" && bad "extract_verified accepted an absolute path"
[ ! -e /tmp/escaped ] && ok "extract_verified refuses absolute paths" || { rm -f /tmp/escaped; bad "wrote /tmp/escaped"; }

# ---- the update guards: remote allowlist, changed installer
mkdir -p "$ROOT"
git -C "$ROOT" init -q
printf 'echo old\n' >"$ROOT/install.sh"
git -C "$ROOT" add install.sh
git -C "$ROOT" -c user.name=t -c user.email=t@t commit -qm old
old="$(git -C "$ROOT" rev-parse HEAD)"
printf 'echo new\n' >"$ROOT/install.sh"
git -C "$ROOT" -c user.name=t -c user.email=t@t commit -qam new
new="$(git -C "$ROOT" rev-parse HEAD)"
printf 'readme\n' >"$ROOT/README.md"
git -C "$ROOT" add README.md
git -C "$ROOT" -c user.name=t -c user.email=t@t commit -qm other
other="$(git -C "$ROOT" rev-parse HEAD)"

remote() { git -C "$ROOT" remote remove origin 2>/dev/null; git -C "$ROOT" remote add origin "$1"; update_remote_ok; }
remote "git@github.com:notwafel/DarkShadowShell.git" && ok "accepts the ssh remote" || bad "ssh remote"
remote "https://github.com/shadowww-dev/DarkShadowShell" && ok "accepts the https remote" || bad "https remote"
remote "https://github.com/evil/DarkShadowShell" && ok "accepts a fork" || bad "fork remote"
remote "https://example.com/x/DarkShadowShell" && bad "accepted a foreign host" || ok "refuses a foreign host"
remote "https://github.com/evil/other" && bad "accepted another repo" || ok "refuses another repo"

update_guard "$old" "$old" && ok "same commit needs no confirmation" || bad "same commit"
update_guard "$new" "$other" </dev/null && ok "an update without a new installer passes" || bad "unchanged install.sh"
RICE_GUI=1 update_guard "$old" "$new" </dev/null && bad "started a changed installer from Settings"
ok "refuses a changed installer without a terminal"
out="$(update_guard "$old" "$new" </dev/null 2>&1 || true)"
case "$out" in *"install.sh"*) ok "says which file changed" ;; *) bad "no summary shown" ;; esac
RICE_TRUST_UPDATE=1 update_guard "$old" "$new" </dev/null && ok "RICE_TRUST_UPDATE=1 starts it" || bad "RICE_TRUST_UPDATE ignored"

# ---- rice-cursor reads the same list (installed copy) and refuses unpinned files
mkdir -p "$tmp/home/.local/bin" "$tmp/home/.local/share/rice"
cp "$root/bin/rice-cursor" "$tmp/home/.local/bin/"
cp "$root/install/checksums.txt" "$tmp/home/.local/share/rice/checksums.txt"
printf '%s  local.bin\nnot-a-hash  broken.bin\n' "$(sha256_of "$tmp/f")" >>"$tmp/home/.local/share/rice/checksums.txt"
HOME="$tmp/home" python3 - "$tmp/home" <<'PY' && ok "rice-cursor uses the list, ignores a bad line, refuses unpinned" || bad "rice-cursor checksums"
import importlib.machinery, importlib.util, os, sys
home = sys.argv[1]
loader = importlib.machinery.SourceFileLoader("rc_test", home + "/.local/bin/rice-cursor")
spec = importlib.util.spec_from_loader("rc_test", loader)
m = importlib.util.module_from_spec(spec)
loader.exec_module(m)
assert m.checksum_file() == home + "/.local/share/rice/checksums.txt"
assert m.expected_sha("local.bin")
assert m.expected_sha("Bibata-Modern-Ice.tar.xz")
assert m.expected_sha("nothing-here.bin") == ""
assert m.expected_sha("broken.bin") == ""
assert m.get_bibata("Bibata-Modern-Amber") is False
PY

bash -n "$root/install.sh" && ok "install.sh parses" || bad "install.sh syntax"
echo "# $n checks passed"
