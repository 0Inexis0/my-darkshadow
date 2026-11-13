#!/usr/bin/env python3
"""Install the reviewed NixOS module without replacing the host hardware configuration."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


def identifier(value, hostname=False):
    pattern = r"[a-zA-Z0-9][a-zA-Z0-9-]{0,62}" if hostname else r"[a-z_][a-z0-9_-]{0,31}"
    if not re.fullmatch(pattern, value) or value in {"root", "nixos", "nobody"} and not hostname:
        raise ValueError("Invalid or reserved account/host name")
    return value


def insert_import(text):
    entry = "./my-darkshadow.nix"
    if entry in text:
        return text
    text, count = re.subn(r"(\bimports\s*=\s*\[)", lambda m: m[1] + " " + entry, text, count=1)
    if count != 1:
        raise ValueError("No imports list found; configuration left unchanged")
    return text


def configure(source, directory, username, profile, new_host=None):
    identifier(username)
    if new_host:
        identifier(new_host, hostname=True)
    if profile not in {"generic", "legion"}:
        raise ValueError("Unknown profile")
    directory.mkdir(parents=True, exist_ok=True)
    configuration = directory / "configuration.nix"
    old = configuration.read_text() if configuration.exists() else ""
    if not new_host and not old:
        raise ValueError("Existing NixOS configuration not found")
    if new_host:
        updated = '''{ pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ./my-darkshadow.nix ];
  system.stateVersion = "26.11";
  networking.hostName = %s;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  users.users.%s = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
  };
  users.users.root.hashedPassword = "!";
  zramSwap.enable = true;
}
''' % (json.dumps(new_host), username)
    else:
        updated = insert_import(old)
    backup = Path(tempfile.mkdtemp(prefix="before-my-darkshadow-", dir=directory))
    for name in ["configuration.nix", "my-darkshadow.nix"]:
        if (directory / name).exists():
            shutil.copy2(directory / name, backup / name)
    destination = directory / "my-darkshadow/source"
    destination.parent.mkdir(parents=True, exist_ok=True)
    staging = Path(tempfile.mkdtemp(prefix=".source-", dir=destination.parent))
    for name in ["nix", "personal", "config", "quickshell", "bin", "lua", "settings", "wallpapers", "sounds", "assets", "docs", "install"]:
        shutil.copytree(source / name, staging / name,
                        ignore=shutil.ignore_patterns("__pycache__", "*.pyc", "*.log", "*.iso", "*.bundle", "dist"))
    for name in ["VERSION", "LICENSE", "flake.nix", "flake.lock", "install.sh", "sync.sh", "GUIDE.md", "README.md"]:
        if (source / name).exists():
            shutil.copy2(source / name, staging / name)
    if destination.exists():
        destination.rename(backup / "source")
    staging.rename(destination)
    (directory / "my-darkshadow.nix").write_text('''{ ... }: {
  imports = [ ./my-darkshadow/source/nix/personal.nix ];
  programs.my-darkshadow = {
    enable = true;
    user = %s;
    profile = %s;
  };
}
''' % (json.dumps(username), json.dumps(profile)))
    configuration.write_text(updated)
    print(f"Configuration backup: {backup}")
    return backup


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--username", required=True)
    parser.add_argument("--profile", choices=["generic", "legion"], default="generic")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    identifier(args.username)
    if args.dry_run:
        print(f"Plan: add my-darkshadow.nix for {args.username}, profile={args.profile}; nixos-rebuild boot")
        return
    if os.geteuid() != 0:
        parser.error("Run with sudo")
    directory = Path("/etc/nixos")
    backup = configure(args.source, directory, args.username, args.profile)
    try:
        subprocess.run(["nix-instantiate", "--parse", str(directory / "configuration.nix")],
                       check=True, stdout=subprocess.DEVNULL)
        subprocess.run(["nixos-rebuild", "boot"], check=True)
    except (subprocess.SubprocessError, OSError):
        for name in ["configuration.nix", "my-darkshadow.nix"]:
            target = directory / name
            if (backup / name).exists():
                shutil.copy2(backup / name, target)
            else:
                target.unlink(missing_ok=True)
        destination = directory / "my-darkshadow/source"
        if destination.exists():
            shutil.rmtree(destination)
        if (backup / "source").exists():
            (backup / "source").rename(destination)
        raise
    print("Boot generation built. Reboot when ready; the current session was not restarted.")


if __name__ == "__main__":
    main()
