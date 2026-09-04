{
  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    npmpkgs = {
      url = "path:../npm-package";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jcode-overlay = {
      url = "github:hypervideo/jcode-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    warp = {
      url = "github:warpdotdev/warp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      determinate,
      nixpkgs,
      home-manager,
      npmpkgs,
      jcode-overlay,
      warp,
    }:
    let
      username = "totto2727";
      homedir = "/home/${username}";
      stateVersion = "25.11";
      system = "x86_64-linux";
      npm = npmpkgs.lib.${system}.npmPackage;
    in
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            determinate.nixosModules.default
            {
              nixpkgs.overlays = [
                jcode-overlay.overlays.default
                (_: _: {
                  inherit (warp.packages.${system}) warp-terminal-experimental;
                })
              ];
            }
            ./configuration.nix
            home-manager.nixosModules.home-manager
            (import ../share/home-manager.nix { inherit username homedir; })
            ({ pkgs, ... }: {
              home-manager.users.${username} = {
                home.stateVersion = stateVersion;

                home.shell.enableZshIntegration = true;

                home.packages =
                  (import ../share/packages.nix {
                    inherit pkgs npm;
                  })
                  ++ (with pkgs; [
                    # GUI
                    xdg-user-dirs
                    mission-center
                    firefox
                    warp-terminal-experimental
                    # TODO: Warpへの移行完了後にghosttyを削除する。
                    ghostty
                    # CLI
                    unzip
                    fakeroot
                    sqlite
                    # Lang toolchain
                    gcc
                    tree-sitter
                    # Game
                    heroic
                    protonup-ng
                    waydroid-helper
                  ]);

                programs = (import ../share/programs.nix { inherit pkgs; }) // {
                  starship.enable = true;
                  zsh = (import ../share/zsh.nix { inherit pkgs; }) // {
                    shellAliases = import ../share/shell-aliases.nix;
                  };
                };

                home.sessionVariables = (import ../share/session-variables.nix) // {
                  STEAM_EXTRA_COMPAT_TOOLS_PATHS = ''
                    ''${HOME}/.steam/root/compatibilitytools.d;
                  '';
                };

                home.sessionPath = import ../share/session-path.nix;
              };
            })
          ];
        };
      };
    };
}
