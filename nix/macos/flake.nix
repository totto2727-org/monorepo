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
      hostname = "totto2727-macos";
      username = "totto2727";
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
                taps = import ../share/taps.nix;
                brews = (import ../share/brews.nix) ++ [
                  "mas"
                  "tailscale"
                  "incus"
                  "talosctl"
                ];
                casks = (import ../share/casks.nix) ++ [
                  # Browser
                  "zen"
                  # Coding
                  "zed"
                  "orbstack"
                  # Game
                  "heroic"
                  # Utility
                  "nordvpn"
                  "1password"
                  "Logi-options+"
                  "raycast"
                  "cleanmymac"
                  "discord"
                  "notion-calendar"
                  "balenaetcher"
                ];
                masApps = {
                  "Kindle" = 302584613;
                  "Mp3tag" = 1532597159;
                  "Prime Video" = 545519333;
                  "Slack for Desktop" = 803453959;
                  "Tailscale" = 1475387142;
                  "Steam Link" = 1246969117;
                };
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
                      gopls
                      air
                      dotnet-sdk
                      zig
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

                                      GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"

                                      if [[ -n "$CLAUDECODE" || ! -o interactive ]]; then
                                        return
                                      fi

                                      chpwd() {
                                        eza -a --group-directories-first
                                      }
                          	      '';
                        shellAliases = (import ../share/shell-aliases.nix) // (import ../share/shell-aliases-macos.nix);
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
