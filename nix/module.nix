# NixOS module: installs everything Shadow's Shell needs.
# Dotfiles and apps are still installed per user with ./install.sh (pick "Tools", "Apps", "Dotfiles").
# NOTE: written without access to a NixOS machine; if an attribute name changed in your nixpkgs, adjust it.
{ lib, pkgs, ... }:
{
  programs.hyprland.enable = lib.mkDefault true;

  environment.systemPackages = with pkgs; [
    waybar
    swaynotificationcenter
    hyprlock
    hypridle
    rofi
    cava
    curl
    jq
    python3
    playerctl
    quickshell
    awww
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    inter
    rubik
  ];

  services.pipewire = {
    enable = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
  };

  xdg.portal.enable = lib.mkDefault true;
}
