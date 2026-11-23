#!/usr/bin/env bash
# Infinite Desktop's Lua config, with a fake Hyprland (tests/rice-infinite.lua): the two screen modes, a new window on
# the second screen and turning it off. Needs lua (Arch: lua; Debian: lua5.4); skipped when it is not there.
set -Euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v lua >/dev/null || { echo "lua is not installed: skipped"; exit 0; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
HOME="$tmp" lua "$root/tests/rice-infinite.lua" "$root/lua/rice-infinite.lua"
