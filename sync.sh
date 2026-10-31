#!/usr/bin/env bash
# Maintainer tool: copies your CURRENT setup from this computer into the repo.
# Paths under $HOME become @HOME@, so anyone can install it. Symlinks are followed
# (their real content is copied), so generated files like hyprland-gui.lua are not lost.
set -Euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TOOLS=(hypr-set waybar-set waybar-preset waybar-reload waybar-autohide font-set desktop-set rice-settings
       rice-colors rice-welcome rice-wallpaper rice-rofi rice-notify rice-lock rice-fonts rice-hotcorner
       rice-desktop rice-stats rice-sysline rice-nowplaying rice-weather rice-cava logout)
CONFIG_DIRS=(hypr waybar swaync rofi matugen kitty)    # folders from ~/.config to publish
SKIP_QS=(cache thumbs)                                  # quickshell folders that are not apps
EXCLUDE=(ui.json 'config.jsonc.save*' '*.bak*' '*.save*' '.first-backup' '*.png' '*.jpg' '*.jpeg' '*.webp'
         '*.gif' '*.qslog' '*.log' 'rice-gaming.lua' 'rice-lock.conf' 'hyprland.lua.save')

tmpl() { # tmpl SRC DST: follow symlinks, replace your home folder with @HOME@
  mkdir -p "$(dirname "$2")"
  if grep -qI . "$1" 2>/dev/null; then
    sed -e "s|$HOME|@HOME@|g" "$1" >"$2"
  else
    cp -fL "$1" "$2"
  fi
  [ -x "$1" ] && chmod +x "$2"
  return 0
}
find_args=()
for e in "${EXCLUDE[@]}"; do find_args+=(! -name "$e"); done

n=0
for t in "${TOOLS[@]}"; do [ -e "$HOME/.local/bin/$t" ] && { tmpl "$HOME/.local/bin/$t" "$HERE/bin/$t"; n=$((n + 1)); }; done
echo "scripts: $n"

for d in "$HOME"/.config/quickshell/*/; do
  [ -d "$d" ] || continue
  q="$(basename "$d")"
  case " ${SKIP_QS[*]} " in *" $q "*) continue ;; esac
  rm -rf "${HERE:?}/quickshell/$q"
  c=0
  while IFS= read -r -d '' f; do
    tmpl "$f" "$HERE/quickshell/$q/${f#"$d"}"; c=$((c + 1))
  done < <(find -L "$d" -type f "${find_args[@]}" ! -path '*/.git/*' -print0)
  echo "quickshell/$q: $c files"
done

for d in "${CONFIG_DIRS[@]}"; do
  [ -d "$HOME/.config/$d" ] || continue
  rm -rf "${HERE:?}/config/$d"
  c=0
  while IFS= read -r -d '' f; do
    [ "$(stat -L -c %s "$f")" -gt 1048576 ] && { echo "skip (>1 MB): $f"; continue; }
    tmpl "$f" "$HERE/config/$d/${f#"$HOME/.config/$d"/}"; c=$((c + 1))
  done < <(find -L "$HOME/.config/$d" -type f "${find_args[@]}" ! -path '*/.git/*' -print0)
  echo "config/$d: $c files"
done

echo "--- checking for secrets"
hits="$(grep -rIniE '(ghp_[A-Za-z0-9]{20,}|api[_-]?key|secret|passw(or)?d|bearer |token)' \
        "$HERE/bin" "$HERE/config" "$HERE/quickshell" 2>/dev/null | head -20 || true)"
if [ -n "$hits" ]; then
  echo "WARNING: these lines look like secrets. Check them before you commit:"
  echo "$hits"
else
  echo "none found"
fi
echo "Done. Review with:  git status && git diff --stat"
