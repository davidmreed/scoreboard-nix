{ lib, stdenv, fetchFromGitHub, unzip, jre, jdk, ant, git, makeWrapper, makeDesktopItem, copyDesktopItems }:

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
    description = "A graphical utility to visualize disk usage";
  };
}
