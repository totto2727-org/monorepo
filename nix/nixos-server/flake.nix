{
  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
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
      determinate,
      nixpkgs,
      home-manager,
      npmpkgs,
    }:
    let
      username = "totto2727";
      homedir = "/home/${username}";
      stateVersion = "25.11";
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
      npm = npmpkgs.lib.${pkgs.system}.npmPackage;
    in
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            determinate.nixosModules.default
            {
              imports = [
                ./hardware-configuration.nix
              ];

              nixpkgs.config.allowUnfree = true;
              # 後で引数から渡せる様にする
              system.stateVersion = stateVersion;

              boot.loader.systemd-boot.enable = true;
              boot.loader.efi.canTouchEfiVariables = true;

              networking.hostName = "nixos";
              networking.networkmanager.enable = true;

              time.timeZone = "Asia/Tokyo";

              i18n.defaultLocale = "en_US.UTF-8";

              i18n.extraLocaleSettings = {
                LC_ADDRESS = "ja_JP.UTF-8";
                LC_IDENTIFICATION = "ja_JP.UTF-8";
                LC_MEASUREMENT = "ja_JP.UTF-8";
                LC_MONETARY = "ja_JP.UTF-8";
                LC_NAME = "ja_JP.UTF-8";
                LC_NUMERIC = "ja_JP.UTF-8";
                LC_PAPER = "ja_JP.UTF-8";
                LC_TELEPHONE = "ja_JP.UTF-8";
                LC_TIME = "ja_JP.UTF-8";
              };

              services.xserver.enable = true;

              services.displayManager.sddm.enable = true;
              services.desktopManager.plasma6.enable = true;

              services.xserver.xkb = {
                layout = "us";
                variant = "";
              };

              # pulseaudio消しても問題ないか後で確認する
              services.pulseaudio.enable = false;
              security.rtkit.enable = true;
              services.pipewire = {
                enable = true;
                alsa.enable = true;
                alsa.support32Bit = true;
                pulse.enable = true;
              };

              environment.systemPackages = with pkgs; [
                tailscale
              ];
              services.tailscale.enable = true;

              users.users.totto2727 = {
                isNormalUser = true;
                description = "totto2727";
                extraGroups = [
                  "networkmanager"
                  "wheel"
                ];
                packages = with pkgs; [
                  kdePackages.kate
                ];
              };

              users.defaultUserShell = pkgs.zsh;

              programs.zsh.enable = true;
              programs.firefox.enable = true;
              programs.ssh.enableAskPassword = false;
            }
            home-manager.nixosModules.home-manager
            (
              (import ../share/home-manager.nix { inherit username homedir; })
              // {
                home-manager.users.totto2727 = {
                  home.stateVersion = stateVersion;

                  home.shell.enableZshIntegration = true;

                  home.packages = import ../share/packages.nix { inherit pkgs npm; };

                  programs = (import ../share/programs.nix) // {
                    home-manager.enable = true;
                    zsh = (import ../share/zsh.nix { inherit pkgs; }) // {
                      initContent = ''
                                eval "$(devbox global shellenv --init-hook)"
                        	      '';

                      shellAliases = (import ../share/shell-aliases.nix);
                    };
                  };

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
