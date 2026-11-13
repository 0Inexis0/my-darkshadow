{ config, lib, pkgs, ... }:
let
  cfg = config.programs.my-darkshadow;
  source = lib.cleanSourceWith {
    src = ../.;
    filter = path: type:
      let name = baseNameOf path; in
      !(lib.elem name [ ".git" "__pycache__" "result" "dist" ])
      && !(lib.hasPrefix "result-" name) && !(lib.hasSuffix ".pyc" name);
  };
  home = config.users.users.${cfg.user}.home;
  theme = pkgs.runCommand "my-darkshadow-sddm-1.0.0" { } ''
    mkdir -p "$out/share/sddm/themes/darkshadow"
    cp -r ${../personal/login/theme}/. "$out/share/sddm/themes/darkshadow/"
  '';
  bundledFonts = pkgs.runCommand "my-darkshadow-fonts" { } ''
    mkdir -p "$out/share/fonts/truetype" "$out/share/doc/my-darkshadow-fonts"
    cp ${../personal/login/theme/fonts}/*.ttf "$out/share/fonts/truetype/"
    cp ${../personal/login/theme/fonts}/*.txt "$out/share/doc/my-darkshadow-fonts/"
  '';
  syncScale = ''
    ${pkgs.python3}/bin/python3 ${../personal/login/sync-scale.py} \
      --settings ${lib.escapeShellArg "${home}/.config/rice/hypr.json"} \
      --theme ${theme}/share/sddm/themes/darkshadow \
      --output /run/darkshadow-login/themes/darkshadow
  '';
in {
  imports = [ ./module.nix ];
  options.programs.my-darkshadow = {
    enable = lib.mkEnableOption "the personal DarkShadow desktop";
    user = lib.mkOption { type = lib.types.str; default = "user"; };
    profile = lib.mkOption { type = lib.types.enum [ "generic" "legion" ]; default = "generic"; };
    login.enable = lib.mkOption { type = lib.types.bool; default = true; };
  };
  config = lib.mkIf cfg.enable (lib.mkMerge [ {
    programs.shadows-shell.user = cfg.user;
    programs.shadows-shell.niri = false;
    programs.niri.enable = lib.mkDefault false;
    programs.hyprland.withUWSM = true;
    programs.fish.enable = true;
    programs.dconf.enable = true;
    environment.localBinInPath = true;
    networking.networkmanager.enable = true;
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
    security.rtkit.enable = true;
    security.polkit.enable = true;
    systemd.user.services.hyprpolkitagent = {
      description = "Hyprland authentication agent";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
        Restart = "on-failure";
      };
    };
    # The shell owns notifications; keep the fallback daemon from claiming D-Bus first.
    systemd.user.services.swaync.enable = false;
    services.pipewire.alsa.enable = true;
    services.pipewire.wireplumber.enable = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    hardware.graphics = { enable = true; enable32Bit = true; };
    nixpkgs.config.allowUnfree = true;
    environment.systemPackages = with pkgs; [
      git foot cliphist wtype ffmpeg mpvpaper pulseaudio glib socat
      networkmanager bluez xsettingsd xrdb firefox brave discord steam
      adw-gtk3 unzip wget file pciutils usbutils mesa-demos
      kdePackages.qt5compat kdePackages.qtsvg kdePackages.qtimageformats
      kdePackages.qtmultimedia kdePackages.syntax-highlighting
    ] ++ lib.optional (pkgs ? codex) pkgs.codex
      ++ lib.optional (pkgs ? chatgpt) pkgs.chatgpt;
    fonts.packages = [ bundledFonts pkgs.noto-fonts pkgs.noto-fonts-color-emoji ];
    time.timeZone = lib.mkDefault "Europe/Berlin";
    i18n.defaultLocale = lib.mkDefault "de_DE.UTF-8";
    console.keyMap = lib.mkDefault "de";
    services.xserver.xkb.layout = lib.mkDefault "de";
    users.users.${cfg.user}.extraGroups = [ "video" "render" "input" "networkmanager" ];
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    # Keep the exact Nixpkgs source available for rebuilding the installed system.
    nix.nixPath = [ "nixpkgs=${pkgs.path}" "nixos-config=/etc/nixos/configuration.nix" ];
    system.activationScripts.my-darkshadow = {
      deps = [ "users" ];
      text = ''
        if id ${lib.escapeShellArg cfg.user} >/dev/null 2>&1; then
          ${pkgs.python3}/bin/python3 ${source}/personal/apply.py \
            --source ${source} --home ${lib.escapeShellArg home} \
            --user ${lib.escapeShellArg cfg.user} --owner ${lib.escapeShellArg cfg.user} \
            --profile ${cfg.profile} --managed-nixos
        fi
      '';
    };
  }
  (lib.mkIf cfg.login.enable {
    services.xserver.enable = true;
    services.displayManager.defaultSession = "hyprland-uwsm";
    services.displayManager.sddm = {
      enable = true;
      theme = "darkshadow";
      extraPackages = [ pkgs.kdePackages.qtdeclarative ];
      settings.Theme.ThemeDir = "/run/darkshadow-login/themes";
    };
    systemd.services.display-manager.preStart = lib.mkBefore syncScale;
    systemd.paths.darkshadow-login-scale = {
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathChanged = "${home}/.config/rice/hypr.json";
    };
    systemd.services.darkshadow-login-scale = {
      description = "Sync DarkShadow monitor scaling to SDDM";
      serviceConfig.Type = "oneshot";
      script = syncScale;
    };
    environment.systemPackages = [ theme ];
  })
  (lib.mkIf (cfg.profile == "legion") {
    hardware.cpu.intel.updateMicrocode = true;
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      open = true;
      modesetting.enable = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    services.fstrim.enable = true;
    zramSwap.enable = true;
  }) ]);
}
