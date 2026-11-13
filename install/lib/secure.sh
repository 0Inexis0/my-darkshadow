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
