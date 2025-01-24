{ lib, stdenv, fetchFromGitHub, unzip, jre, jdk, ant, git, bash, fuse-overlayfs, xdg-utils, makeWrapper, makeDesktopItem, copyDesktopItems, ... }:

stdenv.mkDerivation  {
  pname = "derby-scoreboard";
  version = "2025.5";

  src = fetchFromGitHub {
    owner = "rollerderby";
    repo = "scoreboard";
    rev = "v2025.5";
    sha256 = "sha256-C+oeGKiqfOTWMefOfarn7bsGhXWnpuAG2ukpoA5akxE=";
    # The Ant scripts for Scoreboard require a full Git checkout.
    leaveDotGit = true;
  };
  buildInputs = [ jre fuse-overlayfs bash xdg-utils ];
  nativeBuildInputs = [ copyDesktopItems jdk ant git unzip makeWrapper ];
  buildPhase = ''
    runHook preBuild
    ant zip
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/dist

    unzip release/crg-scoreboard_*.zip
    mv crg-scoreboard_*/* $out/dist

    cat > $out/bin/derby-scoreboard <<EOF
    #!${bash}/bin/bash
    set -euo pipefail

    # Set up directories we need
    ROOT_DIR=\$(mktemp -d)
    CONFIG_DIR=\$(realpath ~/.config/)/derby-scoreboard
    CACHE_DIR=\$(realpath ~/.cache/)/derby-scoreboard
    if [ ! -d "\$CONFIG_DIR" ]; then
        mkdir -p "\$CONFIG_DIR"
    fi
    if [ ! -d "\$CACHE_DIR" ]; then
        mkdir -p "\$CACHE_DIR"
    fi
    WORK_DIR=\$(mktemp -d "\$CACHE_DIR/workXXXXXXX")

    # Clean up if a signal is thrown/error occurs
    cleanup()
    {
        if [[ -v SCOREBOARD_PID ]]; then
            kill \$SCOREBOARD_PID || true
        fi
        if [[ -v FUSE_PID ]]; then
            kill \$FUSE_PID || true
        fi
        if [ -d \$WORK_DIR ]; then
            rm -rf \$WORK_DIR || true
        fi
        if [ -d \$ROOT_DIR ]; then
            rm -rf \$ROOT_DIR || true
        fi
    }

    trap cleanup 1 2 3 6 15 EXIT

    # Start the FUSE overlay filesystem
    ${fuse-overlayfs}/bin/fuse-overlayfs \
      -o lowerdir=$out/dist \
      -o upperdir=\$CONFIG_DIR \
      -o workdir=\$WORK_DIR \
      -o squash_to_uid=\$(id -u) \
      -f true \
      \$ROOT_DIR &
    FUSE_PID=\$!

    # Wait for the FUSE filesystem to be ready
    timeout 30 bash -c "until stat \$ROOT_DIR/lib/crg-scoreboard.jar; do sleep 0.5; done"

    # Start the scoreboard. Working directory MUST be the root dir.
    cd \$ROOT_DIR
    ${jre}/bin/java -jar lib/crg-scoreboard.jar \
      -Done-jar.silent=true \
      -Dorg.eclipse.jetty.server.LEVEL=WARN &
    SCOREBOARD_PID=\$!

    # Wait for the scoreboard to be ready
    timeout 30 bash -c 'until echo > /dev/tcp/localhost/8000; do sleep 0.5; done'

    xdg-open "http://localhost:8000"

    # Wait until (1) the user terminates us or
    # (2) either the scoreboard or FUSE stops.
    wait -n \$SCOREBOARD_PID \$FUSE_PID

    # Tear down any remaining processes and delete temp dirs.
    cleanup
    EOF

    chmod +x $out/bin/derby-scoreboard
    runHook postInstall
  '';

  desktopItems = let item = makeDesktopItem {
    desktopName = "CRG Derby Scoreboard";
    genericName = "Roller derby scoreboard";
    categories = [ "Utility" ];
    exec = "derby-scoreboard";
    name = "derby-scoreboard";
  }; in [ item ];

  meta = with lib; {
    homepage = "https://github.com/rollerderby/scoreboard";
    description = "Roller derby scoreboard";
    license = [licenses.gpl3Plus licenses.asl20];
  };
}
