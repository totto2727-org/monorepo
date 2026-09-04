{
  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jcode-overlay = {
      url = "github:hypervideo/jcode-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      determinate,
      nixpkgs,
      home-manager,
      jcode-overlay,
    }:
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            determinate.nixosModules.default
            {
              nixpkgs.overlays = [ jcode-overlay.overlays.default ];
            }
            ./configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.totto2727 = { pkgs, ... }: {
                home.stateVersion = "25.11";

                home.shell.enableZshIntegration = true;

                home.packages = with pkgs; [
                  # GUI
                  xdg-user-dirs
                  mission-center
                  firefox
                  # CLI
                  git
                  just
                  unzip
                  fakeroot
                  sqlite
                  chezmoi
                  # Lang toolchain
                  gcc
                  nixfmt
                  tree-sitter
                  # TUI
                  neovim
                  lazygit
                  yazi
                  witr
                  bottom
                  jcode
                  # game
                  heroic
                  protonup-ng
                  waydroid-helper
                ];

                programs = {
                  starship.enable = true;
                  zoxide.enable = true;
                  git = import ../share/git.nix;
                  gh = import ../share/gh.nix { inherit pkgs; };
                  zsh = {
                    enable = true;
                    enableCompletion = true;
                  };
                };
                home.sessionVariables = {
                  EDITOR = "nvim";
                  STEAM_EXTRA_COMPAT_TOOLS_PATHS = ''
                    ''${HOME}/.steam/root/compatibilitytools.d;
                  '';
                };
              };
            }
          ];
        };
      };
    };
}
