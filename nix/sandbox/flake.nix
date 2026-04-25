{
  description = "A flake to provision my environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2511";
    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/*";
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
    }:
    let
      username = "sandbox";
      homedir = "/sandbox";
      stateVersion = "25.11";
      pkgs = import nixpkgs {
        system = "arm64-linux";
      };
      npm = npmpkgs.lib.${pkgs.system}.npmPackage;
    in
    {
      nixpkgs.config.allowUnfree = true;
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ({
            home.stateVersion = stateVersion;
            home.username = username;
            home.homeDirectory = homedir;

            home.packages = import ../share/packages.nix { inherit pkgs npm; };

            programs = (import ../share/programs.nix) // {
              home-manager.enable = true;
              zsh = (import ../share/zsh.nix { inherit pkgs; }) // {
                initContent = ''
                          eval "$(devbox global shellenv --init-hook)"
                          [ -f "$HOME/.vite-plus/env" ] && . "$HOME/.vite-plus/env"
                  	      '';

                shellAliases = (import ../share/shell-aliases.nix) // {
                  home-manager = "home-manager --flake ~/nix/sandbox#sandbox";
                };
              };
            };

            home.sessionVariables = import ../share/session-variables.nix;
            home.sessionPath = import ../share/session-path.nix;
          })
        ];
      };
    };
}
