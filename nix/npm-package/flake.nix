{
  description = "Simple utility for integrating NPM packages into NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      npmUtilsFor = forAllSystems (
        system:
        import ./lib/npm-utils.nix {
          pkgs = nixpkgs.legacyPackages.${system};
        }
      );
    in
    {
      lib = forAllSystems (system: {
        npmPackage = npmUtilsFor.${system}.npmPackage;
      });
    };
}
