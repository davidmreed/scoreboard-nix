let
  pkgs = import <nixpkgs> { };
in
{
  scoreboard = pkgs.callPackage ./scoreboard-iso.nix { };
}
