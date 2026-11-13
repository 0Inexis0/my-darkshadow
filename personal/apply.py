#!/usr/bin/env python3
"""Deploy only the reviewed repository files, with backups and local-edit protection."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def inventory(source, profile="generic", extras=False):
    result = {}
    groups = [
        ("personal/login/theme/fonts", ".local/share/fonts/shadows-shell"),
    ]
    if not extras:
        groups += [("config", ".config"), ("quickshell", ".config/quickshell"),
                   ("bin", ".local/bin"), ("lua", ".config/hypr"),
                   ("settings", ".config"), ("wallpapers", "Wallpapers"),
                   ("sounds", ".local/share/rice/sounds")]
    for folder, target in groups:
        for file in sorted((source / folder).rglob("*")):
            if file.is_file() and not file.is_symlink() and "__pycache__" not in file.parts:
                result[Path(target) / file.relative_to(source / folder)] = file
    if profile == "legion" and not extras:
        for name, target in [("hypr.json", ".config/rice/hypr.json"),
                             ("rice-settings.lua", ".config/hypr/rice-settings.lua"),
                             ("rice-gpu.lua", ".config/hypr/rice-gpu.lua")]:
            result[Path(target)] = source / "personal/profiles/legion" / name
    if not extras:
        result[Path(".local/share/rice/icon.png")] = source / "assets/icon.png"
    return result


def render(content, home, user):
    return content.replace(b"@HOME@", os.fsencode(home)).replace(b"@USER@", user.encode())


def digest(content):
    return hashlib.sha256(content).hexdigest()


def deploy(source, home, user, profile="generic", dry_run=False, force=False,
           extras=False, managed=False, revision="unknown"):
    home = home.absolute()
    state = home / ".local/state/my-darkshadow/installed.json"
    try:
        previous = json.loads(state.read_text())
    except (OSError, ValueError):
        previous = {}
    files = {str(rel): (render(src.read_bytes(), home, user), os.access(src, os.X_OK))
             for rel, src in inventory(source, profile, extras).items()}
    if not extras:
        files.update({
            ".config/rice/repo": (f"{source}\n".encode(), False),
            ".config/rice/version": ((source / "VERSION").read_bytes(), False),
            ".config/rice/wm": (b"hyprland\n", False),
            ".config/rice/personal-profile": ((profile + "\n").encode(), False),
        })
    files[".config/rice/fork-version"] = ((source / "personal/FORK_VERSION").read_bytes(), False)
    if managed:
        files[".config/rice/managed-by-nixos"] = (b"Update through the NixOS configuration; see GUIDE.md.\n", False)
        files[".config/rice/fork-revision"] = ((revision + "\n").encode(), False)
    wall = home / ".cache/hyprquickpaper-current"
    if not wall.exists():
        files[".cache/hyprquickpaper-current"] = (f"{home}/Wallpapers/mono-peaks.jpg\n".encode(), False)
    backup = None
    counts = {"written": 0, "unchanged": 0, "kept": 0}

    def mkdir(path):
        missing = []
        while not path.exists() and path != home.parent:
            missing.append(path)
            path = path.parent
        for directory in reversed(missing):
            directory.mkdir(exist_ok=True)

    for rel, (content, executable) in files.items():
        target = home / rel
        # Never follow a configuration directory out of the user's home.
        if not target.parent.resolve().is_relative_to(home.resolve()):
            raise ValueError(f"Refusing configuration path outside home: {rel}")
        current = target.read_bytes() if target.is_file() else None
        if current == content:
            previous[rel] = digest(content)
            counts["unchanged"] += 1
            continue
        if current is not None and rel in previous and digest(current) != previous[rel] and not force:
            counts["kept"] += 1
            print(f"Kept local edit: {rel}")
            continue
        counts["written"] += 1
        if dry_run:
            continue
        if target.exists() or target.is_symlink():
            if backup is None:
                base = home / ".local/state/my-darkshadow/backups"
                mkdir(base)
                backup = Path(tempfile.mkdtemp(prefix="before-install-", dir=base))
            saved = backup / rel
            mkdir(saved.parent)
            shutil.copy2(target, saved, follow_symlinks=False)
            if target.is_symlink():
                target.unlink()
        mkdir(target.parent)
        with tempfile.NamedTemporaryFile(dir=target.parent, delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(content)
        temporary.chmod(0o755 if executable else 0o644)
        temporary.replace(target)
        previous[rel] = digest(content)
    if not dry_run:
        mkdir(state.parent)
        temporary = state.with_suffix(".tmp")
        temporary.write_text(json.dumps(previous, indent=2) + "\n")
        temporary.replace(state)
    print(f"{'Plan' if dry_run else 'Installed'}: {counts}; profile={profile}")
    if backup:
        print(f"Backup: {backup}")
    return counts


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=ROOT)
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument("--user", default=os.environ.get("USER", "user"))
    parser.add_argument("--profile", choices=["generic", "legion"], default="generic")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--force", action="store_true", help="Replace edited files, retaining backups")
    parser.add_argument("--extras", action="store_true", help="Fonts and initial wallpaper only")
    parser.add_argument("--managed-nixos", action="store_true")
    parser.add_argument("--revision", default="unknown")
    args = parser.parse_args()
    if os.geteuid() == 0:
        parser.error("Run the deployer as the desktop account; system activation drops privileges first")
    deploy(args.source.resolve(), args.home, args.user, args.profile, args.dry_run,
           args.force, args.extras, args.managed_nixos, args.revision)


if __name__ == "__main__":
    main()
