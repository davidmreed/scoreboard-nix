{
  description = "Minimal NixOS installation media";
  inputs.nixos.url = "nixpkgs/23.11";
  outputs = { self, nixos }: {
    nixosConfigurations = {
      exampleIso = nixos.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixos}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ({ pkgs, ... }: {
            environment.systemPackages = [  ];
              # EFI booting
          isoImage.makeEfiBootable = true;

          # USB booting
          isoImage.makeUsbBootable = true;

          isoImage.storeContents = [ ];
          services.xserver.desktopManager.xfce = {
            enable = true;
            enableScreensaver = false;
          };

          services.xserver.displayManager = {
            gdm = {
              enable = true;
              # autoSuspend makes the machine automatically suspend after inactivity.
              # It's possible someone could/try to ssh'd into the machine and obviously
              # have issues because it's inactive.
              # See:
              # * https://github.com/NixOS/nixpkgs/pull/63790
              # * https://gitlab.gnome.org/GNOME/gnome-control-center/issues/22
              autoSuspend = false;
            };
            autoLogin = {
              enable = true;
              user = "nixos";
            };
          };
          })
        ];
      };
    };
  };
}
