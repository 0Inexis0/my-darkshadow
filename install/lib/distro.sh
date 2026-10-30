# shellcheck shell=bash
# shellcheck disable=SC2034,SC1112
# Distro detection + package lists.

DISTRO_ID=linux; DISTRO_NAME=Linux; DISTRO_LIKE=
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  DISTRO_ID="${ID:-linux}"; DISTRO_NAME="${NAME:-Linux}"; DISTRO_LIKE="${ID_LIKE:-}"
fi

FAMILY=other
case " $DISTRO_ID $DISTRO_LIKE " in
  *" nixos "*) FAMILY=nixos ;;
  *" arch "*|*" archlinux "*|*" cachyos "*|*" endeavouros "*|*" manjaro "*|*" garuda "*) FAMILY=arch ;;
esac

# Arch package names (repo or AUR; the installer checks which is which).
ARCH_PKGS=(
  hyprland hyprlock hypridle waybar swaync rofi cava curl jq python playerctl
  pipewire wireplumber xdg-desktop-portal-hyprland
  quickshell awww
  wf-recorder grim slurp wl-clipboard libnotify xdg-user-dirs
  ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols
)

# Commands the rice needs at runtime (used to report what is missing on any distro).
NEED_CMDS=(Hyprland waybar qs swaync-client cava rofi curl jq python3 awww hyprlock)
