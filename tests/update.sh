#!/usr/bin/env bash
# Checks for the update guards in install/lib/secure.sh: an update only comes from this project, and a changed
# installer is never started on its own (a non-interactive update, like one from Settings, is refused).
set -Euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

warn() { :; }
fail() { :; }
ROOT="$tmp/repo"
CHECKSUMS="$root/install/checksums.txt"
# shellcheck source=../install/lib/secure.sh
. "$root/install/lib/secure.sh"

n=0
ok() { n=$((n + 1)); printf 'ok %d - %s\n' "$n" "$1"; }
bad() { printf 'not ok %d - %s\n' "$n" "$1"; exit 1; }

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

# update_remote_ok: this project, any fork of it
RICE_UPDATE_REMOTE="git@github.com:notwafel/DarkShadowShell.git" update_remote_ok && ok "accepts the ssh remote" || bad "ssh remote"
RICE_UPDATE_REMOTE="https://github.com/shadowww-dev/DarkShadowShell" update_remote_ok && ok "accepts the https remote" || bad "https remote"
RICE_UPDATE_REMOTE="https://github.com/evil/DarkShadowShell" update_remote_ok && ok "accepts a fork" || bad "fork remote"
RICE_UPDATE_REMOTE="https://example.com/x/DarkShadowShell" update_remote_ok && bad "accepted a foreign host" || ok "refuses a foreign host"
RICE_UPDATE_REMOTE="https://github.com/evil/other" update_remote_ok && bad "accepted another repo" || ok "refuses another repo"

# update_guard: same installer = nothing to ask
update_guard "$old" "$old" && ok "same commit needs no confirmation" || bad "same commit"
update_guard "$new" "$other" </dev/null && ok "an update without a new installer passes" || bad "unchanged install.sh"

# a changed installer: refused without a terminal, trusted only when the user asked for it
if RICE_GUI=1 update_guard "$old" "$new" </dev/null; then bad "started a changed installer from Settings"; fi
ok "refuses a changed installer without a terminal"
out="$(update_guard "$old" "$new" </dev/null 2>&1 || true)"
case "$out" in *"install.sh"*) ok "says which file changed" ;; *) bad "no summary shown" ;; esac
if RICE_TRUST_UPDATE=1 update_guard "$old" "$new" </dev/null; then ok "RICE_TRUST_UPDATE=1 starts it"; else bad "RICE_TRUST_UPDATE ignored"; fi

echo "# $n checks passed"
