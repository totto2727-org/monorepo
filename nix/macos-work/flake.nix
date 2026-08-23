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
      url = "path:../npm-package";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.moonbit-overlay.follows = "moonbit-overlay";
    };
    local-packages = {
      url = "path:../share/packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      self,
      nixpkgs,
      npmpkgs,
      local-packages,
      home-manager,
      nix-darwin,
      moonbit-overlay,
      vite-plus-overlay,
    }:
    let
      hostname = "AMADH5CQH14H3";
      username = "hayato.tsuchida";
      homedir = "/Users/${username}";
      stateVersion = "25.11";
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          local-packages.overlays.default
          moonbit-overlay.overlays.default
          vite-plus-overlay.overlays.default
        ];
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
                brews = (import ../share/brews.nix) ++ [
                  "podman"
                  "zlib"
                  "sqlite"
                ];
                casks = (import ../share/casks.nix) ++ [
                  # Coding
                  "visual-studio-code"
                  "claude"
                  "claude-code@latest"
                  "podman-desktop"
                  # Utility
                  "karabiner-elements"
                  "fuwasegu/tap/airlingua"
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
                    (import ../share/packages.nix {
                      inherit pkgs npm;
                    })
                    ++ (import ../share/packages-dev.nix { inherit pkgs; })
                    ++ (import ../share/packages-macos.nix { inherit pkgs; })
                    ++ (import ../share/packages-scripts.nix { inherit pkgs npm; }).macos-work
                    ++ (with pkgs; [
                      docker
                      kanata-with-cmd
                    ]);

                  programs =
                    (import ../share/programs.nix { inherit pkgs; })
                    // (import ../share/programs-macos.nix { inherit pkgs; }).programs
                    // {
                      zsh = (import ../share/zsh.nix { inherit pkgs; }) // {
                        initContent = ''
                                      eval "$(/opt/homebrew/bin/brew shellenv)"

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
