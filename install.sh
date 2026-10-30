#!/usr/bin/env bash
# Shadow's Shell installer: works for any user (everything uses $HOME / $USER).
# Supports Arch-based distros (installs packages) and NixOS (prints/uses the module).
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install/lib/ui.sh
. "$ROOT/install/lib/ui.sh"
# shellcheck source=install/lib/distro.sh
. "$ROOT/install/lib/distro.sh"

ASSUME_YES=0; DRY_RUN=0; MODE=install
usage() {
  cat <<U
Shadow's Shell installer

Usage: ./install.sh [options]
  -y, --yes        accept defaults, no questions
  -n, --dry-run    show what would happen, change nothing
      --restore    restore the newest backup made by this installer
  -h, --help       this help
U
}
for a in "$@"; do
  case "$a" in
    -y|--yes) ASSUME_YES=1 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    --restore) MODE=restore ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown option: $a"; usage; exit 2 ;;
  esac
done

[ "$(id -u)" != 0 ] || [ -n "${SHADOWS_ALLOW_ROOT:-}" ] || { fail "Do not run this as root. It installs into your home directory."; exit 1; }

STAMP="$(date +%Y%m%d-%H%M%S)"
BK="$HOME/.config/shadows-shell-backup-$STAMP"
LOG="${TMPDIR:-/tmp}/shadows-shell-install-$STAMP.log"
: >"$LOG"

# ---------- helpers ----------
# put SRC DST : copy one file, replace @HOME@/@USER@, back up what it overwrites.
put() {
  local src="$1" dst="$2" rel
  [ "$DRY_RUN" = 1 ] && return 0
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    rel="${dst#"$HOME"/}"
    mkdir -p "$BK/$(dirname "$rel")"
    cp -a "$dst" "$BK/$rel"
  fi
  mkdir -p "$(dirname "$dst")"
  if grep -qI . "$src" 2>/dev/null; then
    sed -e "s|@HOME@|$HOME|g" -e "s|@USER@|$USER|g" "$src" >"$dst"
  else
    cp -f "$src" "$dst"
  fi
  [ -x "$src" ] && chmod +x "$dst"
  return 0
}

copy_tree() { # copy_tree SRC_DIR DST_DIR
  local src="$1" dst="$2" f
  [ -d "$src" ] || return 0
  while IFS= read -r -d '' f; do put "$f" "$dst/${f#"$src"/}"; done \
    < <(find "$src" -type f ! -name '*.bak*' ! -name '.gitkeep' -print0)
}

missing_cmds() {
  local c out=()
  for c in "${NEED_CMDS[@]}"; do command -v "$c" >/dev/null 2>&1 || out+=("$c"); done
  printf '%s\n' "${out[@]:-}"
}

# ---------- steps ----------
step_deps() {
  case "$FAMILY" in
    arch)
      local repo=() aur=() p helper=
      for p in "${ARCH_PKGS[@]}"; do
        if pacman -Si "$p" >/dev/null 2>&1; then repo+=("$p"); else aur+=("$p"); fi
      done
      info "Installing ${#repo[@]} packages with pacman (sudo password may be asked)"
      if [ "$DRY_RUN" = 1 ]; then info "pacman -S --needed ${repo[*]}"; else sudo pacman -S --needed --noconfirm "${repo[@]}"; fi
      if [ "${#aur[@]}" -gt 0 ]; then
        command -v paru >/dev/null && helper=paru
        [ -z "$helper" ] && command -v yay >/dev/null && helper=yay
        if [ -n "$helper" ]; then
          info "Installing AUR packages with $helper: ${aur[*]}"
          [ "$DRY_RUN" = 1 ] || "$helper" -S --needed "${aur[@]}"
        else
          warn "No AUR helper (paru/yay) found. Install these from the AUR yourself: ${aur[*]}"
        fi
      fi
      ;;
    nixos)
      title "NixOS: packages are declared, not installed imperatively"
      info "Add this repo's module to your configuration (see nix/README in docs/NIXOS.md):"
      printf '\n    %simports = [ %s/nix/module.nix ];%s\n\n' "$CD" "$ROOT" "$C0"
      info "or, with flakes: inputs.shadows-shell.url = \"github:shadowww-dev/shadows-shell\";"
      info "then run: sudo nixos-rebuild switch"
      ;;
    *)
      warn "Unsupported distro ($DISTRO_NAME): install these yourself, then re-run:"
      printf '    %s\n' "${NEED_CMDS[*]}"
      ;;
  esac
}

step_tools() {
  local f
  for f in "$ROOT"/bin/*; do [ -f "$f" ] && put "$f" "$HOME/.local/bin/$(basename "$f")"; done
  if ! printf '%s' ":$PATH:" | grep -q ":$HOME/.local/bin:"; then
    warn "\$HOME/.local/bin is not in your PATH; add it in your shell config."
  fi
}

step_apps() {
  copy_tree "$ROOT/quickshell/rice-settings" "$HOME/.config/quickshell/rice-settings"
  copy_tree "$ROOT/quickshell/rice-desktop" "$HOME/.config/quickshell/rice-desktop"
  copy_tree "$ROOT/quickshell/rice-welcome" "$HOME/.config/quickshell/rice-welcome"
  [ "$DRY_RUN" = 1 ] || rm -f "$HOME/.config/quickshell/rice-desktop/VisualizerWidget.qml"
}

step_lua() {
  local f
  for f in "$ROOT"/lua/*.lua; do [ -f "$f" ] && put "$f" "$HOME/.config/hypr/$(basename "$f")"; done
  return 0
}

step_dots() {
  local d
  if ! ls -d "$ROOT"/config/*/ >/dev/null 2>&1; then
    warn "config/ is empty in this checkout (run ./sync.sh on the source machine first)."
    return 0
  fi
  for d in "$ROOT"/config/*/; do copy_tree "${d%/}" "$HOME/.config/$(basename "$d")"; done
}

step_wire() {
  [ "$DRY_RUN" = 1 ] && return 0
  mkdir -p "$HOME/.config/rice" "$HOME/.cache/rice"
  [ -f "$HOME/.config/rice/.first-backup" ] || echo "$BK" >"$HOME/.config/rice/.first-backup"
  local lua="$HOME/.config/hypr/hyprland.lua" m
  if [ -f "$lua" ]; then
    for m in rice-settings rice-desktop rice-keys; do
      if [ -f "$HOME/.config/hypr/$m.lua" ] && ! grep -q "require(\"$m\")" "$lua"; then
        cp -n "$lua" "$BK/hyprland.lua.orig" 2>/dev/null || true
        printf '\nrequire("%s")\n' "$m" >>"$lua"
      fi
    done
  fi
  # color schemes: teach hyprquickpaper (if present) about the named schemes
  if [ -f "$HOME/.config/quickshell/hyprquickpaper/commands.sh" ]; then
    cp -n "$HOME/.config/quickshell/hyprquickpaper/commands.sh" "$HOME/.config/quickshell/hyprquickpaper/commands.sh.bak-schemes" 2>/dev/null || true
    python3 "$ROOT/install/patches/colors-commands.py" "$HOME/.config/quickshell/hyprquickpaper/commands.sh" || true
  fi
  # notifications (Settings > Notifications) and idle/lock screen (Settings > Idle & Lockscreen)
  if command -v swaync-client >/dev/null 2>&1 && [ -x "$HOME/.local/bin/rice-notify" ]; then
    "$HOME/.local/bin/rice-notify" apply || true
  fi
  if command -v hyprlock >/dev/null 2>&1 && [ -x "$HOME/.local/bin/rice-lock" ]; then
    "$HOME/.local/bin/rice-lock" apply || true
  fi
  # rofi theme + blur rule (Settings > Rofi)
  if command -v rofi >/dev/null 2>&1 && [ -x "$HOME/.local/bin/rice-rofi" ]; then
    "$HOME/.local/bin/rice-rofi" apply || true
  fi
  # distro logo on Waybar (Arch logo on Arch, NixOS logo on NixOS, ...)
  if [ -f "$HOME/.config/waybar/config.jsonc" ] && [ -x "$HOME/.local/bin/waybar-set" ]; then
    "$HOME/.local/bin/waybar-set" distro-icon on || true
  fi
  [ -x "$HOME/.local/bin/desktop-set" ] && { "$HOME/.local/bin/desktop-set" state >/dev/null 2>&1 || true; "$HOME/.local/bin/desktop-set" lock-regen >/dev/null 2>&1 || true; }
  command -v hyprctl >/dev/null 2>&1 && { hyprctl reload >/dev/null 2>&1 || true; }
  [ -x "$HOME/.local/bin/waybar-reload" ] && { "$HOME/.local/bin/waybar-reload" >/dev/null 2>&1 || true; }
  [ -x "$HOME/.local/bin/rice-desktop" ] && { "$HOME/.local/bin/rice-desktop" restart >/dev/null 2>&1 || true; }
  return 0
}

do_restore() {
  local last
  last="$(find "$HOME/.config" -maxdepth 1 -type d -name 'shadows-shell-backup-*' 2>/dev/null | sort | tail -n1 || true)"
  [ -n "$last" ] || { fail "No backup found."; exit 1; }
  info "Newest backup: $last"
  confirm "Restore it over your current files?" || { warn "Cancelled."; exit 0; }
  [ "$DRY_RUN" = 1 ] || cp -a "$last"/. "$HOME"/
  ok "Restored. Files that did not exist before the install were left in place."
  exit 0
}

# ---------- main ----------
banner
info "User:    ${CB}$USER${C0}   Home: $HOME"
info "System:  ${CB}$DISTRO_NAME${C0} ($FAMILY)"
[ "$DRY_RUN" = 1 ] && warn "Dry run: nothing will be changed."
[ "$MODE" = restore ] && do_restore

menu_select "What do you want to do?" \
  "Install everything (recommended)" \
  "Choose components" \
  "Restore the previous backup" \
  "Quit"
case "$MENU_CHOICE" in
  2) do_restore ;;
  3) exit 0 ;;
esac

WANT=(1 1 1 1)
if [ "$MENU_CHOICE" = 1 ]; then
  menu_multi "Components" \
    "Dependencies (packages)|1" \
    "Tools → ~/.local/bin|1" \
    "Settings & desktop apps (Quickshell)|1" \
    "Dotfiles → ~/.config (Hyprland, Waybar, ...)|1"
  WANT=("${MENU_SEL[@]}")
fi

title "Summary"
[ "${WANT[0]}" = 1 ] && info "Install dependencies for $DISTRO_NAME"
[ "${WANT[1]}" = 1 ] && info "Install tools to ~/.local/bin"
[ "${WANT[2]}" = 1 ] && info "Install Settings and desktop apps"
[ "${WANT[3]}" = 1 ] && info "Install dotfiles to ~/.config"
info "Existing files are backed up to ${CD}$BK${C0}"
confirm "Continue?" || { warn "Cancelled."; exit 0; }

printf '\n'
[ "${WANT[0]}" = 1 ] && step_deps
[ "${WANT[1]}" = 1 ] && task "Installing tools" step_tools
[ "${WANT[2]}" = 1 ] && task "Installing Settings & desktop apps" step_apps
[ "${WANT[3]}" = 1 ] && task "Installing dotfiles" step_dots
task "Installing Hyprland keybinds" step_lua
task "Wiring Hyprland, Waybar and the distro logo" step_wire

miss="$(missing_cmds | tr '\n' ' ')"
printf '\n'
if [ -n "${miss// /}" ]; then warn "Still missing on PATH: $miss"; else ok "All required programs found."; fi
ok "Done. Log: $LOG"
[ -d "$BK" ] && info "Undo anytime with: ./install.sh --restore"
info "Open Settings with SUPER+U, or log out and back in."
