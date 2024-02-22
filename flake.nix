{
  description = "Minimal NixOS installation media";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.scoreboard = with import nixpkgs { system = "x86_64-linux"; };
let
  desktopItem = makeDesktopItem {
    desktopName = "Derby Scoreboard";
    genericName = "Roller derby scoreboard";
    categories = [ "Utility" ];
    exec = "derby-scoreboard";
    name = "derby-scoreboard";
  };
in
stdenv.mkDerivation rec {
  pname = "derby-scoreboard";
  version = "2023.4";

  src = fetchFromGitHub {
    owner = "davidmreed";
    repo = "scoreboard";
    rev = "be68825a5af7800ae3c9f5c78ca6fb9dbd83e335";
    sha256 = "sha256-l1EdrOqP+nPh2Q6cVkB9lOC4iGDLDigBj08an/BBu9o=";
    # The Ant scripts for Scoreboard require a full Git checkout.
    leaveDotGit = true;
  };
  buildInputs = [ jre ];
  nativeBuildInputs = [ copyDesktopItems jdk ant git unzip makeWrapper ];
  buildPhase = ''
    runHook preBuild
    ant zip
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    unzip release/crg-scoreboard_*.zip
    mv crg-scoreboard_*/* $out
    makeWrapper ${jre}/bin/java $out/bin/derby-scoreboard \
      --chdir $out \
      --add-flags "-jar $out/lib/crg-scoreboard.jar" \
      --add-flags "-Done-jar.silent=true" \
      --add-flags "-Dorg.eclipse.jetty.server.LEVEL=WARN" \
      --add-flags "--config-path=$(echo ~/.config/derby-scoreboard)"

    runHook postInstall
  '';

  desktopItems = [ desktopItem ];

  meta = with lib; {
    homepage = "https://github.com/rollerderby/scoreboard";
    description = "Roller derby scoreboard";
  };
};
    nixosConfigurations = {
      exampleIso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
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
