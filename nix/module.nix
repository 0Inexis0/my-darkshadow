# NixOS module: installs everything DarkShadow's Shell needs.
# Dotfiles and apps are still installed per user with ./install.sh (pick "Tools", "Apps", "Dotfiles").
# NOTE: written without access to a NixOS machine; if an attribute name changed in your nixpkgs, adjust it.
{ config, lib, pkgs, options, ... }:
lib.mkMerge [
{
  programs.hyprland.enable = lib.mkDefault true;

  environment.systemPackages = with pkgs; [
    waybar
    swaynotificationcenter
    hyprlock
    hypridle
    cava
    curl
    jq
    python3
    playerctl
    quickshell
    awww
    wf-recorder
    grim
    slurp
    wl-clipboard
    libnotify
    xdg-user-dirs
    pavucontrol
    gnome-calendar
    hyprsunset
    upower
    nautilus
    btop
    cmatrix
    peaclock
    fastfetch
    papirus-icon-theme
    bibata-cursors
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

  # battery and device charge for the Battery widget
  services.upower.enable = lib.mkDefault true;

  # power modes in the notification center (Power saver, Balanced, Performance).
  # Turned off automatically when you use TLP or auto-cpufreq, which do the same job.
  services.power-profiles-daemon.enable = lib.mkDefault (
    !(config.services.tlp.enable or false) && !(config.services.auto-cpufreq.enable or false));

  xdg.portal.enable = lib.mkDefault true;

  # the lock screen (the shell's own and hyprlock) checks your password with this PAM service
  security.pam.services.hyprlock = { };
}

# niri: the shell runs on it too (pick it on the login screen). programs.niri brings niri, its session, the GNOME
# portal (screen sharing) and polkit; xwayland-satellite runs X11 apps. Turn it off with:
#   programs.niri.enable = false;
(lib.optionalAttrs (options ? programs && options.programs ? niri) {
  programs.niri.enable = lib.mkDefault true;
})
{
  environment.systemPackages = lib.optionals (config.programs.niri.enable or false) (
    lib.optional (pkgs ? xwayland-satellite) pkgs.xwayland-satellite ++ lib.optional (pkgs ? gammastep) pkgs.gammastep);
}
]
