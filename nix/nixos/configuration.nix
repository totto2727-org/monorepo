# Custom
# nix-shell -p git
# git clone https://github.com/totto2727-dotfiles/nix.git
# cd nix/nixos
# cp /etc/nixos/hardware-configuration.nix .
# sudo nixos-rebuild switch -I ./configuration.nix
# task init
# sudo tailscale up --ssh
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ 9 ];
  };

  networking = {
    interfaces = {
      eno1 = {
        wakeOnLan.enable = true;
      };
    };
  };

  services.tailscale.enable = true;

  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "ja_JP.UTF-8";
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
  fonts.packages = with pkgs; [
    ibm-plex
    plemoljp
    plemoljp-hs
    plemoljp-nf
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
  ];

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.displayManager = {
    autoLogin.user = "totto2727";
    cosmic-greeter.enable = true;
  };
  services.desktopManager.cosmic.enable = true;
  services.system76-scheduler.enable = true;

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
  services.xserver.videoDrivers = [ "amdgpu" ];

  virtualisation.waydroid.enable = true;

  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [
    neovim
    git
    mangohud
    cosmic-store
  ];

  users.users.totto2727 = {
    isNormalUser = true;
    description = "totto2727";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;
}
