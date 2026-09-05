{
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    vite-plus-overlay = {
      url = "github:ryoppippi/nix-vite-plus";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
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
              vite-plus-overlay.overlays.default
            ];
          };
        in
        {
          default = pkgs.mkShell {
            packages = [
              # JS
              pkgs.bun
              pkgs.deno
              pkgs.nodejs_24
              pkgs.vite-plus
              # Nix
              pkgs.nixfmt
              # SQL
              pkgs.sqld
              pkgs.turso-cli
              # Util
              pkgs.just
              pkgs.treefmt
            ];

            shellHook = ''
              ${pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
                export NIX_LDFLAGS="$NIX_LDFLAGS -no_compact_unwind"
              ''}

              # Enable vp env
              vp env setup
              . "$HOME/.vite-plus/env"
              # Enable Git Hook
              vp config
            '';
          };
        }
      );
    };
}
