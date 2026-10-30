# shellcheck shell=bash
# shellcheck disable=SC2034,SC1112
# Tiny terminal UI toolkit: colors, banner, spinner, arrow-key menus. No dependencies.

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C0=$'\e[0m'; CB=$'\e[1m'; CD=$'\e[2m'
  CR=$'\e[38;5;203m'; CG=$'\e[38;5;114m'; CY=$'\e[38;5;221m'; CBL=$'\e[38;5;111m'; CM=$'\e[38;5;183m'
else
  C0=; CB=; CD=; CR=; CG=; CY=; CBL=; CM=
fi

IS_TTY=0; [ -t 0 ] && [ -t 1 ] && IS_TTY=1

hide_cursor() { [ "$IS_TTY" = 1 ] && printf '\e[?25l'; return 0; }
show_cursor() { [ "$IS_TTY" = 1 ] && printf '\e[?25h'; return 0; }
trap 'show_cursor' EXIT

banner() {
  printf '\n  %s╭──────────────────────────────────────────────────────╮%s\n' "$CM" "$C0"
  printf '  %s│%s%s   ◢◤  S H A D O W ’ S   S H E L L                    %s%s│%s\n' "$CM" "$C0" "$CB" "$C0" "$CM" "$C0"
  printf '  %s│%s%s   Hyprland · Quickshell · Waybar · desktop widgets   %s%s│%s\n' "$CM" "$C0" "$CD" "$C0" "$CM" "$C0"
  printf '  %s╰──────────────────────────────────────────────────────╯%s\n\n' "$CM" "$C0"
}

info() { printf '  %s•%s %s\n' "$CBL" "$C0" "$*"; }
ok()   { printf '  %s✔%s %s\n' "$CG" "$C0" "$*"; }
warn() { printf '  %s!%s %s\n' "$CY" "$C0" "$*"; }
fail() { printf '  %s✘%s %s\n' "$CR" "$C0" "$*" >&2; }
title() { printf '\n  %s%s%s\n' "$CB" "$*" "$C0"; }

# task "message" cmd args...  -> runs with a spinner, output goes to $LOG
task() {
  local msg="$1"; shift
  if [ "${DRY_RUN:-0}" = 1 ]; then info "$msg ${CD}(dry run)${C0}"; return 0; fi
  if [ "$IS_TTY" != 1 ]; then
    if "$@" >>"$LOG" 2>&1; then ok "$msg"; return 0; else fail "$msg (see $LOG)"; return 1; fi
  fi
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏') i=0 pid rc
  "$@" >>"$LOG" 2>&1 &
  pid=$!
  hide_cursor
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r  %s%s%s %s' "$CBL" "${frames[i % 10]}" "$C0" "$msg"
    i=$((i + 1)); sleep 0.08
  done
  wait "$pid"; rc=$?
  show_cursor
  printf '\r\e[K'
  if [ "$rc" = 0 ]; then ok "$msg"; else fail "$msg (see $LOG)"; fi
  return "$rc"
}

# read one key: prints up/down/enter/space/quit/other
read_key() {
  local k rest
  IFS= read -rsn1 k || { echo quit; return; }
  case "$k" in
    $'\e') IFS= read -rsn2 -t 0.05 rest || true
           case "$rest" in '[A') echo up ;; '[B') echo down ;; *) echo quit ;; esac ;;
    '') echo enter ;;
    ' ') echo space ;;
    k) echo up ;;
    j) echo down ;;
    q) echo quit ;;
    *) echo other ;;
  esac
}

# menu_select "Title" opt1 opt2 ...  -> sets MENU_CHOICE (0-based). Non-tty: first option.
menu_select() {
  local ttl="$1"; shift
  local opts=("$@") n=$# cur=0 key i
  MENU_CHOICE=0
  title "$ttl"
  if [ "$IS_TTY" != 1 ] || [ "${ASSUME_YES:-0}" = 1 ]; then info "${opts[0]}"; return 0; fi
  hide_cursor
  while :; do
    for i in "${!opts[@]}"; do
      if [ "$i" = "$cur" ]; then printf '  %s❯ %s%s\e[K\n' "$CG" "${opts[i]}" "$C0"
      else printf '    %s%s%s\e[K\n' "$CD" "${opts[i]}" "$C0"; fi
    done
    printf '  %s↑/↓ move · enter select%s\e[K' "$CD" "$C0"
    key="$(read_key)"
    case "$key" in
      up) cur=$(( (cur - 1 + n) % n )) ;;
      down) cur=$(( (cur + 1) % n )) ;;
      enter) break ;;
      quit) show_cursor; printf '\n'; fail "Aborted."; exit 130 ;;
    esac
    printf '\r\e[%dA' "$n"
  done
  printf '\r\e[K\n'
  show_cursor
  MENU_CHOICE=$cur
}

# menu_multi "Title" "label|1" "label|0" ... -> sets MENU_SEL array of 0/1. Non-tty: defaults.
menu_multi() {
  local ttl="$1"; shift
  local labels=() sel=() n=$# cur=0 key i item
  for item in "$@"; do labels+=("${item%|*}"); sel+=("${item##*|}"); done
  title "$ttl"
  if [ "$IS_TTY" = 1 ] && [ "${ASSUME_YES:-0}" != 1 ]; then
    hide_cursor
    while :; do
      for i in "${!labels[@]}"; do
        local box="[ ]"; [ "${sel[i]}" = 1 ] && box="[${CG}x${C0}]"
        if [ "$i" = "$cur" ]; then printf '  %s❯%s %s %s\e[K\n' "$CG" "$C0" "$box" "${labels[i]}"
        else printf '    %s %s%s%s\e[K\n' "$box" "$CD" "${labels[i]}" "$C0"; fi
      done
      printf '  %s↑/↓ move · space toggle · enter confirm%s\e[K' "$CD" "$C0"
      key="$(read_key)"
      case "$key" in
        up) cur=$(( (cur - 1 + n) % n )) ;;
        down) cur=$(( (cur + 1) % n )) ;;
        space) if [ "${sel[cur]}" = 1 ]; then sel[cur]=0; else sel[cur]=1; fi ;;
        enter) break ;;
        quit) show_cursor; printf '\n'; fail "Aborted."; exit 130 ;;
      esac
      printf '\r\e[%dA' "$n"
    done
    printf '\r\e[K\n'
    show_cursor
  else
    for i in "${!labels[@]}"; do [ "${sel[i]}" = 1 ] && info "${labels[i]}"; done
  fi
  MENU_SEL=("${sel[@]}")
}

# confirm "Question" -> 0 yes / 1 no (default yes). --yes always yes.
confirm() {
  local a
  if [ "${ASSUME_YES:-0}" = 1 ] || [ "$IS_TTY" != 1 ]; then return 0; fi
  printf '\n  %s%s%s [Y/n] ' "$CB" "$1" "$C0"
  IFS= read -r a || return 1
  case "${a:-y}" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}
