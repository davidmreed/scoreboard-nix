{
  # Heavily inspired by https://gist.github.com/FlakM/0535b8aa7efec56906c5ab5e32580adf
  description = "Flake for Derby Scoreboard";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { system = system; };
      in
      rec {
        formatter.${system} = pkgs.nixfmt-rfc-style;
        packages.default = pkgs.callPackage ./scoreboard.nix {};
        nixosConfigurations = {
          scoreboard = nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs.inputs = inputs;
            modules = [
            {
            users.groups.admin = { };
            users.groups.sbo = { };
            users.users = {
              admin = {
                isNormalUser = true;
                extraGroups = [ "wheel" ];
                password = "admin";
                group = "admin";
              };
              sbo = {
                isNormalUser = true;
                password = "";
                group = "sbo";
              };
            };
            virtualisation.vmVariant = {
              virtualisation = {
                memorySize = 2048;
                cores = 2;
                graphics = true;
              };
            };
            services.xserver = {
              enable = true;
              desktopManager = {
                xfce.enable = true;
              };
              displayManager = {
                    autoLogin.enable = true;
                    autoLogin.user = "sbo";
                  defaultSession = "xfce";
                  lightdm = {
                    enable = true;
                };
                };
            };
          }];
          };
        };
        apps = rec {
          default = scoreboard-vm;
          scoreboard-vm = {
            type = "app";
            program = "${nixosConfigurations.scoreboard.config.system.build.vm}/bin/run-nixos-vm";
          };
        };
      }
    );
}
