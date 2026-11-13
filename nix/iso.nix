{ config, lib, pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix")
    ./personal.nix
  ];
  programs.my-darkshadow = {
    enable = true;
    user = "nixos";
  };
  networking.hostName = "my-darkshadow-live";
  services.displayManager.autoLogin = { enable = true; user = "nixos"; };
  services.openssh.enable = lib.mkForce false;
  image.baseName = lib.mkForce "my-darkshadow-1.0.0-${config.programs.my-darkshadow.profile}-x86_64";
  isoImage.volumeID = "MY_DARKSHADOW";
  # Fast compression for a locally built installation image.
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";
  environment.systemPackages = with pkgs; [
    parted dosfstools e2fsprogs util-linux nixos-install-tools
    (writeShellScriptBin "darkshadow-install" ''
      exec ${python3}/bin/python3 /etc/my-darkshadow-source/personal/install-to-disk.py "$@"
    '')
  ];
  # Keep the installer beside its module and assets, so it can deploy fully offline files.
  environment.etc."my-darkshadow-source".source = lib.cleanSource ../.;
  environment.etc."xdg/my-darkshadow-install.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Install my-darkshadow
    Name[de]=my-darkshadow installieren
    Comment=Guided NixOS installation
    Exec=kitty -e sudo /run/current-system/sw/bin/python3 /etc/my-darkshadow-source/personal/install-to-disk.py
    Icon=system-software-install
    Terminal=false
    Categories=System;
  '';
  system.activationScripts.darkshadow-live-launcher = {
    deps = [ "users" ];
    text = ''
      mkdir -p /home/nixos/.local/share/applications /home/nixos/Schreibtisch
      cp /etc/xdg/my-darkshadow-install.desktop /home/nixos/.local/share/applications/darkshadow-install.desktop
      cp /etc/xdg/my-darkshadow-install.desktop /home/nixos/Schreibtisch/darkshadow-install.desktop
      chown -R nixos:users /home/nixos/.local/share/applications /home/nixos/Schreibtisch
    '';
  };
}
