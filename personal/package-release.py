#!/usr/bin/env python3
"""Split a large ISO into GitHub release assets and generate a checksum-verifying assembler."""
import argparse
import hashlib
from pathlib import Path
import re


def package(iso, output, chunk_size=1900 * 1024 * 1024):
    if chunk_size <= 0:
        raise ValueError("Chunk size must be positive")
    match = re.fullmatch(r"my-darkshadow-[0-9.]+-(generic|legion)-x86_64\.iso", iso.name)
    if not match:
        raise ValueError("Unexpected ISO filename")
    profile = match[1]
    output.mkdir(parents=True, exist_ok=True)
    complete = hashlib.sha256()
    parts = []
    with iso.open("rb") as source:
        index = 0
        while True:
            data = source.read(min(chunk_size, 8 * 1024 * 1024))
            if not data:
                break
            target = output / f"{iso.name}.part-{index:03d}"
            checksum = hashlib.sha256()
            written = 0
            with target.open("wb") as stream:
                while data:
                    stream.write(data)
                    complete.update(data)
                    checksum.update(data)
                    written += len(data)
                    remaining = chunk_size - written
                    if not remaining:
                        break
                    data = source.read(min(remaining, 8 * 1024 * 1024))
            parts.append((target.name, checksum.hexdigest()))
            index += 1
    if not parts:
        raise ValueError("Empty ISO")
    (output / f"PARTSUMS-{profile}").write_text("".join(f"{sha}  {name}\n" for name, sha in parts))
    (output / f"SHA256SUMS-{profile}").write_text(f"{complete.hexdigest()}  {iso.name}\n")
    script = output / f"assemble-{profile}.sh"
    script.write_text('''#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
output='%s'
[[ ! -e "$output" && ! -e "$output.tmp" ]] || { echo 'Output already exists; leaving it unchanged.' >&2; exit 1; }
sha256sum --check 'PARTSUMS-%s'
trap 'rm -f -- "$output.tmp"' EXIT
cat %s > "$output.tmp"
printf '%%s  %%s\\n' '%s' "$output.tmp" | sha256sum --check -
mv -- "$output.tmp" "$output"
trap - EXIT
echo "Ready to write to USB: $output"
''' % (iso.name, profile, " ".join("'" + name + "'" for name, _ in parts), complete.hexdigest()))
    script.chmod(0o755)
    print(f"Packaged {iso.name}: {len(parts)} parts; SHA-256 {complete.hexdigest()}")
    return parts


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--iso", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    package(args.iso, args.output)
