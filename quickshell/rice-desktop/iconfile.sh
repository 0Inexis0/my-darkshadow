#!/usr/bin/env bash
# iconfile.sh NAME: the file of an app icon (a PNG when there is one, else an SVG), or nothing.
# The bar draws it as a plain picture, without Qt's icon theme engine (that one can crash on some SVG icons).
n="${1:-}"
[ -n "$n" ] || exit 0
if [ "${n#/}" != "$n" ]; then [ -f "$n" ] && echo "$n"; exit 0; fi
n="${n%.png}"; n="${n%.svg}"

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
[ -n "$theme" ] && themes+=("$theme")
themes+=(hicolor Papirus Papirus-Dark breeze breeze-dark Adwaita)
sizes=(48x48 64x64 32x32 128x128 256x256 96x96 scalable 512x512 24x24 22x22 16x16)

for ext in png svg; do
  for r in "${roots[@]}"; do
    [ -d "$r" ] || continue
    for t in "${themes[@]}"; do
      [ -d "$r/$t" ] || continue
      for s in "${sizes[@]}"; do
        for c in apps applications; do
          f="$r/$t/$s/$c/$n.$ext"; [ -f "$f" ] && { echo "$f"; exit 0; }
          f="$r/$t/$c/${s%%x*}/$n.$ext"; [ -f "$f" ] && { echo "$f"; exit 0; }   # breeze: apps/48
        done
      done
    done
  done
  for d in "${dd[@]}" /usr/share; do
    f="$d/pixmaps/$n.$ext"; [ -f "$f" ] && { echo "$f"; exit 0; }
  done
done
exit 0
