#!/usr/bin/env bash
set -euo pipefail
profile=generic
dry_run=0
system=0
yes=0
while (( $# )); do
  case "$1" in
    --profile) profile="${2:?Provide generic or legion}"; shift ;;
    --system) system=1 ;;
    --dry-run) dry_run=1 ;;
    --yes) yes=1 ;;
    -h|--help)
      echo 'Usage: bootstrap.sh [--dry-run] [--profile generic|legion] [--system] [--yes]'
      echo 'NixOS: --system also stages the desktop, packages and SDDM for the next reboot.'
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done
case "$profile" in generic|legion) ;; *) echo 'Unknown hardware profile' >&2; exit 2 ;; esac
if (( EUID == 0 )); then echo 'Run bootstrap as your normal desktop user.' >&2; exit 1; fi
checkout=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if [[ ! -f "$checkout/personal/FORK_VERSION" ]]; then checkout="$HOME/my-darkshadow"; fi
echo "my-darkshadow: profile=$profile, checkout=$checkout"
if (( dry_run )); then
  echo 'Plan: obtain the fork, install its desktop configuration with backups and bundle its fonts.'
  if (( system )); then echo 'Plan: import the NixOS desktop and SDDM module; build the next boot generation.'; fi
  if [[ -f "$checkout/personal/apply.py" ]]; then
    python3 "$checkout/personal/apply.py" --profile "$profile" --dry-run
  fi
  exit 0
fi
if [[ ! -f "$checkout/personal/FORK_VERSION" ]]; then
  command -v git >/dev/null || { echo 'Install git first.' >&2; exit 1; }
  git clone https://github.com/0Inexis0/my-darkshadow.git "$checkout"
fi
if (( ! yes )); then
  read -r -p 'Install the desktop configuration? Existing files are backed up. [y/N] ' answer
  [[ "$answer" == y || "$answer" == Y ]] || exit 0
fi
if [[ -e /etc/NIXOS ]]; then
  if (( system )); then
    sudo python3 "$checkout/personal/configure-system.py" --source "$checkout" \
      --username "$(id -un)" --profile "$profile"
  else
    python3 "$checkout/personal/apply.py" --profile "$profile"
    echo 'Dotfiles installed. For packages and SDDM: rerun with --system, then reboot.'
  fi
else
  if (( system )); then echo '--system requires NixOS.' >&2; exit 2; fi
  "$checkout/install.sh" --yes
  python3 "$checkout/personal/apply.py" --profile "$profile"
fi
if command -v fc-cache >/dev/null; then fc-cache -f; fi
echo 'Finished. Log in to Hyprland; SUPER + U opens Settings.'
