{
  description = "Go packages in the monorepo";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forEachSystem = nixpkgs.lib.genAttrs supportedSystems;
      mkPkgs = system: import nixpkgs { inherit system; };
    in
    {
      devShells = forEachSystem (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.go
              pkgs.golangci-lint
            ];
          };
        }
      );

      packages = forEachSystem (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          atlas-to-kysely = pkgs.callPackage ./app/atlas-to-kysely/package.nix { };
        }
      );

      overlays.default = _final: prev: {
        atlas-to-kysely = self.packages.${prev.stdenv.hostPlatform.system}.atlas-to-kysely;
      };
    };
}
