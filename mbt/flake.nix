{
  description = "MoonBit CLI packages in the monorepo";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    moonbit-overlay = {
      url = "github:totto2727/moonbit-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    moon-registry = {
      url = "git+https://mooncakes.io/git/index";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      moonbit-overlay,
      moon-registry,
      ...
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      forEachSystem = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ moonbit-overlay.overlays.default ];
          };
        in
        {
          bw = pkgs.callPackage ./app/bw/package.nix {
            moonRegistryIndex = moon-registry;
          };
          c-plugin = pkgs.callPackage ./app/c-plugin/package.nix {
            moonRegistryIndex = moon-registry;
          };
          wt = pkgs.callPackage ./app/wt/package.nix {
            moonRegistryIndex = moon-registry;
          };
        }
      );

      overlays.default = _final: prev: {
        bw = self.packages.${prev.stdenv.hostPlatform.system}.bw;
        c-plugin = self.packages.${prev.stdenv.hostPlatform.system}.c-plugin;
        wt = self.packages.${prev.stdenv.hostPlatform.system}.wt;
      };
    };
}
