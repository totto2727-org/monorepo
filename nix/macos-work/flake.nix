{
  description = "A flake to provision my environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";
    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    npmpkgs = {
      url = "https://flakehub.com/f/totto2727-dotfiles/npm-packages/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      npmpkgs,
      home-manager,
      nix-darwin,
    }:
    let
      hostname = "AMADH5CQH14H3";
      username = "hayato.tsuchida";
      homedir = "/Users/${username}";
      stateVersion = "25.11";
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
      };
      npm = npmpkgs.lib.${pkgs.system}.npmPackage;
    in
    {
      nixpkgs.config.allowUnfree = true;
      darwinConfigurations = {
        "${hostname}" = nix-darwin.lib.darwinSystem {
          inherit system pkgs;

          modules = [
            {
              nix.enable = false;
            }
            {
              system = import ../share/darwin-system.nix { inherit username; };
              homebrew = (import ../share/homebrew.nix) // {
                taps = (import ../share/taps.nix) ++ [
                  "slp/krun"
                ];
                brews = (import ../share/brews.nix) ++ [
                  "podman"
                  "krunkit"
                  "zlib"
                  "sqlite"
                  "gemini-cli"
                ];
                casks = (import ../share/casks.nix) ++ [
                  # Coding
                  "visual-studio-code"
                  "cursor"
                  "podman-desktop"
                  "figma"
                  "postman"
                  # Utility
                  "slack"
                  "karabiner-elements"
                ];
              };
            }
            home-manager.darwinModules.home-manager
            (
              (import ../share/home-manager.nix { inherit username homedir; })
              // {
                home-manager.users."${username}" = {
                  home.stateVersion = stateVersion;

                  home.packages =
                    (import ../share/packages.nix { inherit pkgs npm; })
                    ++ (import ../share/packages-macos.nix { inherit pkgs; })
                    ++ (with pkgs; [
                      docker
                    ]);

                  programs =
                    (import ../share/programs.nix)
                    // (import ../share/programs-macos.nix { inherit pkgs; }).programs
                    // {
                      zsh = (import ../share/zsh.nix { inherit pkgs; }) // {
                        initContent = ''
                                      eval "$(/opt/homebrew/bin/brew shellenv)"

                                      # Vite+
                                      [ -f "$HOME/.vite-plus/env" ] && . "$HOME/.vite-plus/env"

                                      GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)";

                                      if [[ -n "$CLAUDECODE" || ! -o interactive ]]; then
                                        return
                                      fi

                                      chpwd() {
                                        eza -a --group-directories-first
                                      }
                          	      '';
                        shellAliases =
                          (import ../share/shell-aliases.nix)
                          // (import ../share/shell-aliases-macos.nix)
                          // {
                            pacli = ''
                              /Applications/Prisma\ Access\ Agent.app/Contents/Helpers/pacli
                            '';
                          };
                      };
                    };

                  services = (import ../share/programs-macos.nix { inherit pkgs; }).services;

                  home.sessionVariables = import ../share/session-variables.nix;
                  home.sessionPath = import ../share/session-path.nix;
                };
              }
            )
          ];
        };
      };
    };
}
