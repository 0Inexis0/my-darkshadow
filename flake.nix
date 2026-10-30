{
  description = "Shadow's Shell: Hyprland + Quickshell rice";

  outputs = { self, ... }: {
    nixosModules.default = import ./nix/module.nix;
    nixosModules.shadows-shell = self.nixosModules.default;
  };
}
