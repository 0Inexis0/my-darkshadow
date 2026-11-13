{ config, lib, pkgs, ... }:
let
  cfg = config.programs.usa-vpn;
  action = "de.local.usa-vpn.connect";
  helper = pkgs.writeText "usa-vpn-root.py" (
    builtins.replaceStrings
      [ "@OPENVPN@" "@RESOLVCONF@" "@PYTHON@" "@CA@" ]
      [ "${pkgs.openvpn}/bin/openvpn"
        "${pkgs.openresolv}/bin/resolvconf"
        "${pkgs.python3}/bin/python3"
        (builtins.toJSON (builtins.readFile ./riseup-ca.crt))
      ]
      (builtins.readFile ./root.py)
  );
  rootCommand = pkgs.writeShellScript "usa-vpn-root" ''
    exec ${pkgs.python3}/bin/python3 -I ${helper}
  '';
  launcher = pkgs.writeText "usa-vpn-control.py" (
    builtins.replaceStrings
      [ "@ROOT_EXE@" "@PYTHON@" ]
      [ "${rootCommand}" "${pkgs.python3}/bin/python3" ]
      (builtins.readFile ./launcher.py)
  );
  package = pkgs.runCommand "usa-vpn-1.0" {} ''
    mkdir -p $out/bin $out/share/applications $out/share/polkit-1/actions
    cat > $out/bin/usa-vpn <<'EOF'
    #!${pkgs.runtimeShell}
    exec ${pkgs.python3}/bin/python3 -I ${launcher} "$@"
    EOF
    chmod +x $out/bin/usa-vpn
    cat > $out/share/applications/usa-vpn.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Version=1.0
    Name=USA VPN
    Comment=Riseup in den USA – kostenlos und ohne Konto
    Exec=$out/bin/usa-vpn
    Icon=network-vpn
    Terminal=false
    Categories=Network;Security;
    StartupNotify=true
    EOF
    cat > $out/share/polkit-1/actions/${action}.policy <<EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN" "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
    <policyconfig>
      <action id="${action}">
        <description>Riseup-US-VPN verbinden</description>
        <message>Für den US-VPN ist eine Systemautorisierung erforderlich.</message>
        <defaults>
          <allow_any>no</allow_any>
          <allow_inactive>no</allow_inactive>
          <allow_active>auth_admin_keep</allow_active>
        </defaults>
        <annotate key="org.freedesktop.policykit.exec.path">${rootCommand}</annotate>
      </action>
    </policyconfig>
    EOF
  '';
in {
  options.programs.usa-vpn = {
    enable = lib.mkEnableOption "den kostenlosen Riseup-Starter für US-Server";
    allowedUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Lokale aktive Benutzer, die diesen VPN ohne weitere Passwortabfrage öffnen dürfen.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = package;
      description = "Der deklarativ gebaute USA-VPN-Starter.";
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ package ];
    security.polkit.enable = true;
    security.polkit.enablePkexecWrapper = true;
    security.polkit.extraConfig = ''
      // Nur dieser feste VPN-Helfer, nur für aktive lokale Sitzungen.
      polkit.addRule(function(action, subject) {
        if (action.id === "${action}" && subject.local && subject.active &&
            ${builtins.toJSON cfg.allowedUsers}.indexOf(subject.user) !== -1) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
