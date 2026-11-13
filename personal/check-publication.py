#!/usr/bin/env python3
"""Check tracked publication files without printing any possible credential values."""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
RULES = {
    "private key": rb"-----BEGIN (?:OPENSSH |RSA |EC |DSA )?PRIVATE KEY-----",
    "GitHub credential": rb"(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{50,})",
    "OpenAI credential": rb"sk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{40,}",
    "AWS access key": rb"(?:AKIA|ASIA)[A-Z0-9]{16}",
    "Slack credential": rb"xox[baprs]-[A-Za-z0-9-]{20,}",
    "local home path": rb"/home/(?:tyler|shadow)(?:/|\b)",
}
FORBIDDEN = {".git-credentials", ".netrc", "id_rsa", "id_ed25519", "auth.json", "integrity.json", "fish_history"}


def findings(path, content):
    result = []
    if path.name in FORBIDDEN or ".env" == path.name or path.suffix in {".pem", ".key", ".iso", ".bundle"}:
        result.append("private state or build product")
    if any(part in {"system-connections", "browser-data", "secrets", ".ssh", ".gnupg"} for part in path.parts):
        result.append("private directory")
    if b"\0" not in content[:8192]:
        for label, pattern in RULES.items():
            if re.search(pattern, content):
                result.append(label)
    return result


def main():
    tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).split(b"\0")
    problems = []
    count = 0
    for entry in tracked:
        if not entry:
            continue
        rel = Path(entry.decode())
        file = ROOT / rel
        if not file.is_file():
            continue
        count += 1
        for label in findings(rel, file.read_bytes()):
            problems.append(f"{rel}: {label} (value redacted)")
    if problems:
        print("Publication check failed:\n" + "\n".join(problems), file=sys.stderr)
        return 1
    print(f"Publication check passed: {count} reviewed tracked files; no matching credentials or private state.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
