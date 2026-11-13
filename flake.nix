{
  description = "my-darkshadow: personal DarkShadow desktop, SDDM and NixOS installation ISO";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/d4f25a3e562008648d45bcf2d70bcc7422cad84e";
  outputs = { self, nixpkgs, ... }: let
    system = "x86_64-linux";
    mkIso = profile: nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [ ./nix/iso.nix { programs.my-darkshadow = {
        inherit profile;
        revision = self.rev or "unknown";
      }; } ];
    };
  in {
    nixosModules.default = import ./nix/module.nix;
    nixosModules.shadows-shell = self.nixosModules.default;
    nixosModules.personal = import ./nix/personal.nix;
    nixosConfigurations.live = mkIso "generic";
    nixosConfigurations.live-legion = mkIso "legion";
    packages.${system} = {
      iso = self.nixosConfigurations.live.config.system.build.isoImage;
      iso-legion = self.nixosConfigurations.live-legion.config.system.build.isoImage;
    };
  };
}
