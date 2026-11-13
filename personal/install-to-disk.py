#!/usr/bin/env python3
"""Guided UEFI installer for the live ISO. Disk writes always require a typed confirmation."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("configure_system", ROOT / "personal/configure-system.py")
system = importlib.util.module_from_spec(spec)
spec.loader.exec_module(system)


def available_disks(devices):
    def mounted(device):
        return any(device.get("mountpoints") or []) or any(mounted(c) for c in device.get("children", []))
    return [d for d in devices if d.get("type") == "disk" and not d.get("ro") and not mounted(d)]


def partition_name(disk, number):
    return f"{disk}{'p' if disk[-1].isdigit() else ''}{number}"


def partition_plan(disk):
    efi, root = partition_name(disk, 1), partition_name(disk, 2)
    return [
        ["wipefs", "--all", disk],
        ["parted", "--script", disk, "mklabel", "gpt"],
        ["parted", "--script", disk, "mkpart", "ESP", "fat32", "1MiB", "513MiB"],
        ["parted", "--script", disk, "set", "1", "esp", "on"],
        ["parted", "--script", disk, "mkpart", "primary", "ext4", "513MiB", "100%"],
        ["udevadm", "settle"],
        ["mkfs.fat", "-F", "32", "-n", "DS-BOOT", efi],
        ["mkfs.ext4", "-F", "-L", "darkshadow-root", root],
        ["mkdir", "-p", "/mnt"],
        ["mount", root, "/mnt"],
        ["mkdir", "-p", "/mnt/boot"],
        ["mount", efi, "/mnt/boot"],
    ]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--disk", help="Whole disk, e.g. /dev/nvme0n1")
    parser.add_argument("--username")
    parser.add_argument("--hostname", default="darkshadow")
    parser.add_argument("--profile", choices=["generic", "legion"])
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    data = json.loads(subprocess.check_output(
        ["lsblk", "--json", "--paths", "--output", "NAME,PATH,TYPE,SIZE,MOUNTPOINTS,RO,MODEL"], text=True))
    disks = available_disks(data["blockdevices"])
    print("\nmy-darkshadow · NixOS installation\n")
    print("UEFI, GPT, ext4. This installer uses an entire disk. Internet is required for missing packages.")
    for index, disk in enumerate(disks, 1):
        print(f"{index}: {disk['path']} · {disk['size']} · {disk.get('model', '')}")
    if args.disk:
        disk = str(Path(args.disk).resolve())
        if disk not in {d["path"] for d in disks}:
            parser.error("Disk not eligible: it is mounted, read-only, missing, or not a whole disk")
    else:
        if args.dry_run:
            print("Dry run: choose an unmounted disk, an account and a profile, confirm erasure, then install.")
            return
        if not disks:
            parser.error("No unmounted writable disks available")
        try:
            selected = int(input("Disk number: "))
            if not 1 <= selected <= len(disks):
                raise ValueError()
            disk = disks[selected - 1]["path"]
        except (ValueError, IndexError):
            parser.error("Invalid disk selection")
    username = args.username or ("user" if args.dry_run else input("Account name: ").strip())
    system.identifier(username)
    system.identifier(args.hostname, hostname=True)
    profile = args.profile or ("generic" if args.dry_run else input("Hardware profile [generic/legion] (generic): ").strip() or "generic")
    if profile not in {"generic", "legion"}:
        parser.error("Unknown profile")
    commands = partition_plan(disk)
    print(f"\nTarget: {disk}; user={username}; host={args.hostname}; profile={profile}")
    if args.dry_run:
        print(json.dumps(commands, indent=2))
        print("Then: generate hardware config, deploy module, nixos-install, set account password.")
        return
    if os.geteuid() != 0:
        parser.error("Run sudo darkshadow-install")
    if not Path("/sys/firmware/efi").exists():
        parser.error("Reboot this USB in UEFI mode; BIOS installation is not supported")
    if Path("/mnt").exists() and (os.path.ismount("/mnt") or any(Path("/mnt").iterdir())):
        parser.error("/mnt must be empty and unmounted")
    if not sys.stdin.isatty():
        parser.error("Interactive confirmation requires a terminal")
    expected = f"ERASE {disk}"
    print(f"ALL DATA ON {disk} WILL BE ERASED. Type exactly: {expected}")
    if input("> ") != expected:
        print("Cancelled. No disk changes.")
        return
    # Recheck after the user interaction, before the first destructive command.
    current = json.loads(subprocess.check_output(
        ["lsblk", "--json", "--paths", "--output", "NAME,PATH,TYPE,SIZE,MOUNTPOINTS,RO"], text=True))
    if disk not in {d["path"] for d in available_disks(current["blockdevices"])}:
        parser.error("Disk state changed; refusing to erase")
    try:
        for command in commands:
            subprocess.run(command, check=True)
        subprocess.run(["nixos-generate-config", "--root", "/mnt"], check=True)
        system.configure(ROOT, Path("/mnt/etc/nixos"), username, profile, new_host=args.hostname)
        subprocess.run(["nixos-install", "--no-root-passwd"], check=True)
        print("Set the new account password (never stored in this repository):")
        subprocess.run(["nixos-enter", "--root", "/mnt", "--command", f"passwd {username}"], check=True)
    except (OSError, subprocess.SubprocessError) as error:
        print(f"Installation stopped: {error}. The target remains mounted at /mnt for recovery.", file=sys.stderr)
        sys.exit(1)
    print("Installation complete. Reboot, remove the USB drive and log in to Hyprland.")


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        print("\nCancelled.", file=sys.stderr)
        sys.exit(1)
