#!/usr/bin/env bash
# Maintainer tool: pulls your CURRENT setup from this machine into the repo.
# Paths under $HOME become @HOME@ and your username becomes @USER@ so anyone can install it.
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TOOLS=(hypr-set waybar-set waybar-preset waybar-reload waybar-autohide font-set desktop-set rice-settings
       rice-colors rice-welcome rice-wallpaper rice-rofi rice-notify rice-lock rice-fonts rice-hotcorner rice-desktop rice-stats rice-sysline rice-nowplaying rice-weather rice-cava)
CONFIG_DIRS=(hypr waybar swaync rofi)          # folders from ~/.config you want to publish
EXCLUDE=(ui.json 'config.jsonc.save*' '*.bak*' '*.save*' '.first-backup' '*.png' '*.jpg' '*.jpeg' '*.webp' '*.gif')

tmpl() { # tmpl SRC DST
  mkdir -p "$(dirname "$2")"
  if grep -qI . "$1" 2>/dev/null; then
    sed -e "s|$HOME|@HOME@|g" "$1" >"$2"
  else
    cp -f "$1" "$2"
  fi
  [ -x "$1" ] && chmod +x "$2"
  return 0
}

for t in "${TOOLS[@]}"; do [ -f "$HOME/.local/bin/$t" ] && tmpl "$HOME/.local/bin/$t" "$HERE/bin/$t"; done
for q in rice-settings rice-desktop rice-welcome; do
  [ -d "$HOME/.config/quickshell/$q" ] || continue
  for f in "$HOME/.config/quickshell/$q"/*.qml; do [ -f "$f" ] && tmpl "$f" "$HERE/quickshell/$q/$(basename "$f")"; done
done

find_args=()
for e in "${EXCLUDE[@]}"; do find_args+=(! -name "$e"); done
for d in "${CONFIG_DIRS[@]}"; do
  [ -d "$HOME/.config/$d" ] || continue
  rm -rf "${HERE:?}/config/$d"
  while IFS= read -r -d '' f; do
    [ "$(stat -c %s "$f")" -gt 1048576 ] && { echo "skip (>1 MB): $f"; continue; }
    tmpl "$f" "$HERE/config/$d/${f#"$HOME/.config/$d"/}"
  done < <(find "$HOME/.config/$d" -type f "${find_args[@]}" -print0)
done

echo "--- scanning for secrets"
if grep -rIniE '(ghp_[A-Za-z0-9]{20,}|api[_-]?key|secret|passw(or)?d|bearer |token)' \
     "$HERE/bin" "$HERE/config" "$HERE/quickshell" 2>/dev/null | grep -v 'Binary file' | head -20 | grep -q .; then
  echo "WARNING: possible secrets found (listed below). Review them before you commit:"
  grep -rIniE '(ghp_[A-Za-z0-9]{20,}|api[_-]?key|secret|passw(or)?d|bearer |token)' "$HERE/bin" "$HERE/config" "$HERE/quickshell" | head -20
else
  echo "none found"
fi
echo "Synced. Review with:  git status && git diff --stat"
