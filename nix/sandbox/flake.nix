{
  description = "A flake to provision my environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2511";
    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    npmpkgs = {
      url = "path:../npm-package";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    moonbit-overlay = {
      url = "github:moonbit-community/moonbit-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vite-plus-overlay = {
      url = "github:ryoppippi/nix-vite-plus";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      npmpkgs,
      home-manager,
      moonbit-overlay,
      vite-plus-overlay,
    }:
    let
      username = "sandbox";
      homedir = "/sandbox";
      stateVersion = "25.11";
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      mkHomeConfiguration =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              moonbit-overlay.overlays.default
              vite-plus-overlay.overlays.default
            ];
          };
          npm = npmpkgs.lib.${system}.npmPackage;
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [
            ({
              home.stateVersion = stateVersion;
              home.username = username;
              home.homeDirectory = homedir;

              home.packages =
                (import ../share/packages.nix {
                  inherit pkgs npm;
                })
                ++ (import ../share/packages-scripts.nix { inherit pkgs npm; }).sandbox;

              programs = (import ../share/programs.nix) // {
                home-manager.enable = true;
                zsh = (import ../share/zsh.nix { inherit pkgs; }) // {
                  initContent = ''
                            eval "$(devbox global shellenv --init-hook)"
                    	      '';

                  shellAliases = (import ../share/shell-aliases.nix) // {
                    home-manager = "home-manager --flake ~/nix/sandbox#${username}-${system}";
                  };
                };
              };

              home.sessionVariables = import ../share/session-variables.nix;
              home.sessionPath = import ../share/session-path.nix;
            })
          ];
        };
    in
    {
      homeConfigurations = nixpkgs.lib.genAttrs (map (s: "${username}-${s}") systems) (
        name: mkHomeConfiguration (nixpkgs.lib.removePrefix "${username}-" name)
      );
    };
}
