#!/usr/bin/env bash
# iconfile.sh NAME...: for each app icon name a line "NAME<TAB>FILE" (a PNG when there is one, else an SVG; empty
# when there is none). Icons.qml draws them as plain pictures, without Qt's icon theme engine: with Qt 6.12 that
# one crashed Quickshell (the bar, the dock and the widgets) on some icons.
theme=""
command -v gsettings >/dev/null 2>&1 && theme="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")"
[ -z "$theme" ] && [ -f "$HOME/.config/gtk-3.0/settings.ini" ] &&
  theme="$(sed -n 's/^gtk-icon-theme-name *= *//p' "$HOME/.config/gtk-3.0/settings.ini" | head -1)"

roots=("$HOME/.local/share/icons" "$HOME/.icons")
IFS=: read -r -a dd <<<"${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
for d in "${dd[@]}" /run/current-system/sw/share "$HOME/.nix-profile/share" /usr/share; do
  [ -n "$d" ] && roots+=("$d/icons")
done
themes=()
# Edit mode > Icons > Icon pack (V4.89): that pack first, then the system's
[ -n "${RICE_ICON_THEME:-}" ] && themes+=("$RICE_ICON_THEME")
# RICE_ICON_ONLY=1: only that pack (its preview in Edit mode), nothing else
if [ "${RICE_ICON_ONLY:-}" = 1 ]; then only=1; else only=0; fi
[ "$only" = 0 ] && [ -n "$theme" ] && themes+=("$theme")
[ "$only" = 0 ] && themes+=(hicolor Papirus Papirus-Dark breeze breeze-dark Adwaita)
sizes=(48x48 64x64 32x32 128x128 256x256 96x96 scalable 512x512 24x24 22x22 16x16)

find_one() {
  local n="$1" ext r t s c d f
  [ -n "$n" ] || return 0
  if [ "${n#/}" != "$n" ]; then [ -f "$n" ] && echo "$n"; return 0; fi
  # NAME|FOLDER: an app's own icon folder first (tray icons: image://icon/NAME?path=FOLDER)
  local own=""
  case "$n" in *"|"*) own="${n#*|}"; n="${n%%|*}" ;; esac
  n="${n%.png}"; n="${n%.svg}"
  if [ -n "$own" ] && [ -d "$own" ]; then
    f="$(find -L "$own" -maxdepth 5 \( -name "$n.png" -o -name "$n.svg" -o -name "$n.xpm" \) 2>/dev/null | sort -r | head -1)"
    [ -n "$f" ] && { echo "$f"; return 0; }
  fi
  # V4.92: the pack comes first, whatever its files are (before, a PNG of the app's own hicolor icon beat the SVGs of
  # the pack you chose, so most packs never showed): pack by pack, then PNG before SVG inside one pack
  for t in "${themes[@]}"; do
    for r in "${roots[@]}"; do
      [ -d "$r/$t" ] || continue
      for s in "${sizes[@]}"; do
        for c in apps applications categories mimetypes places devices status legacy; do
          for ext in png svg; do
            f="$r/$t/$s/$c/$n.$ext"; [ -f "$f" ] && { echo "$f"; return 0; }
            f="$r/$t/$c/${s%%x*}/$n.$ext"; [ -f "$f" ] && { echo "$f"; return 0; }   # breeze: apps/48
          done
        done
      done
    done
  done
  if [ "$only" = 0 ]; then
    for ext in png svg; do
      for d in "${dd[@]}" /usr/share; do
        f="$d/pixmaps/$n.$ext"; [ -f "$f" ] && { echo "$f"; return 0; }
      done
    done
  fi
  # last: any icon theme on this computer (other themes, odd folder layouts)
  [ "$only" = 1 ] && return 0
  for r in "${roots[@]}"; do
    [ -d "$r" ] || continue
    f="$(find -L "$r" -maxdepth 5 \( -name "$n.png" -o -name "$n.svg" \) 2>/dev/null | head -1)"
    [ -n "$f" ] && { echo "$f"; return 0; }
  done
  return 0
}
for a in "$@"; do printf '%s\t%s\n' "$a" "$(find_one "$a")"; done
