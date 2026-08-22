{
  description = "Simple utility for integrating NPM packages into NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    moonbit-overlay = {
      url = "github:totto2727-org/moonbit-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      moonbit-overlay,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      npmUtilsFor = forAllSystems (
        system:
        import ./lib/npm-utils.nix {
          pkgs = nixpkgs.legacyPackages.${system};
          moonbit = moonbit-overlay.packages.${system}.moonbit_latest;
        }
      );
    in
    {
      lib = forAllSystems (system: {
        npmPackage = npmUtilsFor.${system}.npmPackage;
      });
    };
}
