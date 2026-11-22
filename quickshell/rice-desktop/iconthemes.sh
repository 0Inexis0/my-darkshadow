#!/usr/bin/env bash
# iconthemes.sh: the icon packs on this computer, for Edit mode > Icons > Icon pack (V4.89). One line per pack:
#   FOLDER<TAB>NAME<TAB>browser<TAB>files<TAB>terminal<TAB>settings   (picture files of four apps, from that pack only)
# Cursor themes and packs without app icons are left out.
here="$(cd "$(dirname "$0")" && pwd)"
roots=("$HOME/.local/share/icons" "$HOME/.icons")
IFS=: read -r -a dd <<<"${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
for d in "${dd[@]}" /run/current-system/sw/share "$HOME/.nix-profile/share" /usr/share; do
  [ -n "$d" ] && roots+=("$d/icons")
done
declare -A seen
for r in "${roots[@]}"; do
  [ -d "$r" ] || continue
  for t in "$r"/*/; do
    t="${t%/}"; b="$(basename "$t")"
    [ -n "${seen[$b]:-}" ] && continue
    case "$b" in hicolor|default|locolor) continue ;; esac
    [ -f "$t/index.theme" ] || continue
    # app icons somewhere in it (not only a cursor theme)
    find -L "$t" -maxdepth 3 -type d -name apps -print -quit 2>/dev/null | grep -q . || continue
    seen[$b]=1
    name="$(sed -n 's/^Name *= *//p' "$t/index.theme" | head -1)"
    [ -z "$name" ] && name="$b"
    mapfile -t f < <(RICE_ICON_THEME="$b" RICE_ICON_ONLY=1 bash "$here/iconfile.sh" \
      firefox system-file-manager utilities-terminal preferences-system | cut -f2)
    # a pack that has none of these four is not much of an app icon pack
    [ -z "${f[0]}${f[1]}${f[2]}${f[3]}" ] && continue
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$b" "$name" "${f[0]}" "${f[1]}" "${f[2]}" "${f[3]}"
  done
done
