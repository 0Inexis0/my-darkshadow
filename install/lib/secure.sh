# shellcheck shell=bash
# Downloads are data, not instructions: everything the installer fetches is checked against
# install/checksums.txt before it is unpacked, and nothing is unpacked outside its own folder.
# The hashes there are pinned to a release tag, so a new upload to the same URL is not used silently.

CHECKSUMS="${CHECKSUMS:-${ROOT:-.}/install/checksums.txt}"

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

expected_sha() { # expected_sha NAME: the hash pinned in install/checksums.txt (nothing when not pinned)
  [ -f "$CHECKSUMS" ] || return 0
  awk -v n="$1" '$2 == n { print $1; exit }' "$CHECKSUMS"
}

fetch_verified() { # fetch_verified URL DEST NAME: download once, and only keep it when the SHA-256 matches
  local url="$1" dst="$2" name="$3" want got
  want="$(expected_sha "$name")"
  if [ -z "$want" ]; then
    warn "no SHA-256 for $name in install/checksums.txt: not downloading it"
    return 1
  fi
  if ! curl -fsSL --max-time 300 -o "$dst" "$url"; then
    warn "could not download $name"
    return 1
  fi
  got="$(sha256_of "$dst")"
  if [ "$got" != "$want" ]; then
    rm -f "$dst"
    fail "$name does not match its SHA-256 (got $got, expected $want): the download was not used"
    return 1
  fi
  return 0
}

extract_verified() { # extract_verified ARCHIVE DEST: unpack only into DEST, and only paths that stay inside it
  local arc="$1" dst="$2" list
  list="$(tar -tf "$arc" 2>/dev/null)" || { warn "not a readable archive: $arc"; return 1; }
  # absolute paths, ../ and links pointing out of DEST write over files the archive has no business touching
  if printf '%s\n' "$list" | grep -qE '(^/|(^|/)\.\.(/|$)| -> /| -> \.\./| link to /| link to \.\./)'; then
    fail "refusing $arc: it would write outside $dst"
    return 1
  fi
  mkdir -p "$dst" || return 1
  tar -xf "$arc" -C "$dst" 2>/dev/null
}
# an update is code from the network: it may only come from this project (any fork of it), never from an address
# that was edited into the repo
update_remote_ok() {
  local u="${RICE_UPDATE_REMOTE:-$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)}"
  [[ "$u" =~ github\.com[:/][A-Za-z0-9_.-]+/DarkShadowShell(\.git)?/?$ ]]
}

# update_guard OLD NEW: an update can bring a new install.sh, and that script runs with your files and asks for
# sudo. A changed installer is never started on its own: a terminal gets the summary and a question, an update
# from Settings (no terminal) is refused and the user runs rice-update instead.
update_guard() {
  local old="$1" new="$2" a=""
  [ -n "$old" ] && [ -n "$new" ] && [ "$old" != "$new" ] || return 0
  git -C "$ROOT" diff --quiet "$old" "$new" -- install.sh 2>/dev/null && return 0
  if [ "${RICE_TRUST_UPDATE:-0}" = 1 ]; then
    warn "new installer started because RICE_TRUST_UPDATE=1"
    return 0
  fi
  warn "This update changes install.sh, the script that runs with your files and may ask for sudo:"
  git -C "$ROOT" diff --stat "$old" "$new" -- install.sh 2>/dev/null | sed 's/^/      /'
  if [ ! -t 0 ] || [ -n "${RICE_GUI:-}" ]; then
    fail "Not starting it on its own. Run  rice-update  in a terminal to see what changed and apply it."
    return 1
  fi
  printf '  Apply this update? [y/N] '
  read -r a || a=""
  case "$a" in
    y | Y | yes | YES) return 0 ;;
    *) fail "Nothing was changed."; return 1 ;;
  esac
}

