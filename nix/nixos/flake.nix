{
  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    home-manager.url = "https://flakehub.com/f/nix-community/home-manager/0.1";
    npmpkgs.url = "path:../npm-package";
    vite-plus-overlay.url = "github:ryoppippi/nix-vite-plus";
  };

  outputs =
    {
      self,
      determinate,
      nixpkgs,
      home-manager,
      npmpkgs,
      vite-plus-overlay,
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
                # TODO:対応次第nixpkgsのvite-plusに差し替え
                vite-plus-overlay.overlays.default
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
                    herdr-desktop
                    # CLI
                    unzip
                    fakeroot
                    sqlite
                    herdr
                    pi-coding-agent
                    # Lang toolchain
                    gcc
                    tree-sitter
                    nodejs
                    bun
                    pnpm
                    vite-plus
                    go
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
