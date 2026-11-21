#!/usr/bin/env bash
# The dock keeps its room only while it can be seen, its app menu keeps it out, and a fresh install pins only apps
# that are installed. Reads the QML and Python as text, no Quickshell needed.
# shellcheck disable=SC2015  # ok/bad are if-then-else after a test and both exit
set -Euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dock="$root/quickshell/rice-desktop/Dock.qml"
apps="$root/quickshell/rice-desktop/DockApps.qml"
page="$root/quickshell/rice-settings/InterfacePage.qml"
n=0
ok() { n=$((n + 1)); printf 'ok %d - %s\n' "$n" "$1"; }
bad() { printf 'not ok %d - %s\n' "$n" "$1"; exit 1; }

grep -q 'readonly property bool reserve: on && !autoHide' "$dock" \
  && ok "a dock that hides on hover reserves no room" || bad "the dock still reserves room while it hides"
grep -q 'pinButton\|pinnedStartup\|property bool pinned' "$dock" && bad "the dock still has its hold-open pin" \
  || ok "no hold-open pin: only the pointer keeps the dock out"
grep -q 'hideTimer; interval: 700; onTriggered: if (!dockMouse.containsMouse && !apps.overPanel)' "$dock" \
  && ok "the dock stays while the pointer is on its app menu" || bad "the app menu does not keep the dock out"
grep -q 'property bool overPanel: false' "$apps" && ok "the app menu reports the pointer on its card" || bad "no overPanel"
( grep -q 'DesktopEntries.heuristicLookup(id) === null' "$page" && grep -q 'l.concat(gone)' "$page" ) \
  && ok "the pins list knows the apps that are gone" || bad "no gone pins"

# the default pins: only the apps that have a .desktop file. The script is run (not copied): a NameError at import,
# like desktop_id below DEFAULTS, gives an empty list and used to pass this check.
t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
mkdir -p "$t/a/applications" "$t/b/applications" "$t/home"
: >"$t/a/applications/kitty.desktop"; : >"$t/b/applications/steam.desktop"
if ! out="$(HOME="$t/home" XDG_DATA_DIRS="$t/a:$t/b" XDG_DATA_HOME="$t/none" "$root/bin/desktop-set" state 2>&1)"; then
  bad "desktop-set does not run: $out"
fi
out="$(printf '%s' "$out" | python3 -c 'import json, sys; print(" ".join(json.load(sys.stdin)["dock"]["apps"]))')"
[ "$out" = "kitty steam" ] && ok "a default pin needs its .desktop file" || bad "the default pins are: $out"
