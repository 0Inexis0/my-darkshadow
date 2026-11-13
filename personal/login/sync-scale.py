#!/usr/bin/env python3
"""Export DarkShadow monitor scales for SDDM, without exposing the home folder."""
import argparse
import fcntl
import json
import math
from pathlib import Path
import re
import sys


def read_scales(settings):
    try:
        data = json.loads(Path(settings).read_text())
        monitors = data.get("monitors", {})
        if not isinstance(monitors, dict):
            return {}
    except (OSError, ValueError, AttributeError):
        print("DarkShadow: Keine gültigen Monitorwerte; verwende Qt-Skalierung.", file=sys.stderr)
        return {}
    result = {}
    for name, monitor in monitors.items():
        if not re.fullmatch(r"[A-Za-z0-9_.:-]{1,128}", name):
            continue
        if not isinstance(monitor, dict) or monitor.get("disabled") is True:
            continue
        scale = monitor.get("scale")
        if isinstance(scale, (int, float)) and not isinstance(scale, bool):
            if math.isfinite(scale) and 0.5 <= scale <= 4:
                result[name] = scale
    return result


def prepare_theme(settings, theme, output):
    theme, output = Path(theme).resolve(), Path(output)
    output.mkdir(parents=True, exist_ok=True, mode=0o755)
    with (output.parent / ".scale-sync.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        _update_theme(settings, theme, output)


def _update_theme(settings, theme, output):
    for entry in theme.iterdir():
        if entry.name == "theme.conf.user":
            continue
        target = output / entry.name
        link = output / ("." + entry.name + ".link")
        if link.is_symlink():
            link.unlink()
        link.symlink_to(entry, target_is_directory=entry.is_dir())
        link.replace(target)
    scales = json.dumps(read_scales(settings), separators=(",", ":"))
    temporary = output / ".theme.conf.user.tmp"
    # QSettings treats unquoted commas as a string list. Quote and escape the
    # whole JSON string so SDDM exposes one intact value to QML.
    temporary.write_text("[General]\nmonitorScales=" + json.dumps(scales) + "\n")
    temporary.chmod(0o644)
    temporary.replace(output / "theme.conf.user")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--settings", required=True)
    parser.add_argument("--theme", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    prepare_theme(args.settings, args.theme, args.output)
