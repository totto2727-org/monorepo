{
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    moonbit-overlay = {
      url = "github:totto2727/moonbit-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vite-plus-overlay = {
      url = "github:ryoppippi/nix-vite-plus";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      moonbit-overlay,
      vite-plus-overlay,
      ...
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forEachSystem = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      devShells = forEachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              moonbit-overlay.overlays.default
              vite-plus-overlay.overlays.default
            ];
          };
        in
        {
          default = pkgs.mkShell {
            env = pkgs.lib.optionalAttrs (system == "x86_64-linux") {
              MOONBIT_NEW_NATIVE = "1";
            };

            packages = [
              # JS
              pkgs.bun
              pkgs.deno
              pkgs.nodejs_24
              pkgs.vite-plus
              # Go
              pkgs.go
              # Nix
              pkgs.nixfmt
              # SQL
              pkgs.sqld
              pkgs.turso-cli
              # MoonBit
              pkgs.moonbit-bin.moonbit.latest
              # Elixir
              pkgs.beam29Packages.elixir_1_20
              pkgs.beam29Packages.erlang
              # Util
              pkgs.just
            ];

            shellHook = ''
              # Enable Git Hook
              vp config
            '';
          };
        }
      );
    };
}
