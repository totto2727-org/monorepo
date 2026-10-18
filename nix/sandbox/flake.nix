{
  description = "A flake to provision my environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    home-manager.url = "https://flakehub.com/f/nix-community/home-manager/0.1";
    npmpkgs.url = "path:../npm-package";
    local-packages.url = "path:../share/packages";
  };

  outputs =
    {
      self,
      nixpkgs,
      npmpkgs,
      local-packages,
      home-manager,
    }:
    let
      username = "sandbox";
      homedir = "/home/${username}";
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
            overlays = [ local-packages.overlays.default ];
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

              programs = (import ../share/programs.nix { inherit pkgs; }) // {
                home-manager.enable = true;
                zsh = (import ../share/zsh.nix { inherit pkgs; }) // {
                  shellAliases = (import ../share/shell-aliases.nix) // {
                    home-manager = "home-manager --flake ~/nix/sandbox#${username}-${system}";
                  };
                };
                starship = import ../share/starship.nix;
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
