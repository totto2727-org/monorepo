{
  description = "A flake to provision my environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    home-manager.url = "https://flakehub.com/f/nix-community/home-manager/0.1";
    local-packages.url = "path:../share/packages";
  };

  outputs =
    {
      self,
      nixpkgs,
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
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [
            ({
              home.stateVersion = stateVersion;
              home.username = username;
              home.homeDirectory = homedir;

              home.packages =
                (with pkgs; [
                  git
                  ripgrep
                  sd
                  fd
                  nixfmt
                  just
                ])
                ++ (import ../share/packages-scripts.nix { inherit pkgs; }).sandbox;

              programs = {
                direnv = import ../share/direnv.nix;
                git = import ../share/git.nix;
                gh = (import ../share/gh.nix { inherit pkgs; }) // {
                  extensions = [ ];
                };
                home-manager.enable = true;
                zsh = {
                  enable = true;
                  shellAliases = {
                    home-manager = "home-manager --flake ~/nix/sandbox#${username}-${system}";
                  };
                };
              };

              home.sessionVariables.TERM = "xterm-256color";
              home.sessionPath = [ "$HOME/.local/bin" ];
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
