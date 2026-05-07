{ pkgs }:
let
  mcp = import ./packages-scripts.nix { inherit pkgs; };
in
[
  pkgs.pinentry_mac
  pkgs.kanata-with-cmd
]
++ mcp.full
