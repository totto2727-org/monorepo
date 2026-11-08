# Custom
# nix-shell -p git
# git clone https://github.com/totto2727-dotfiles/nix.git
# cd nix/nixos
# cp /etc/nixos/hardware-configuration.nix .
# sudo nixos-rebuild switch -I ./configuration.nix
# just init
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
  nix.settings.auto-optimise-store = true;
  programs.nix-ld.enable = true;
  # Shared libraries for prebuilt binaries installed outside Nix
  # (e.g. the cmux browser under ~/.local/opt/cmux-browser-nightly).
  programs.nix-ld.libraries = with pkgs; [
    # Linked at startup.
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    glib
    gtk3
    libdrm
    libgbm
    libglvnd
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libXtst
    libxcb
    libxkbcommon
    mesa
    nspr
    nss
    pango
    systemd

    # Loaded on demand (audio, VA-API, screen capture, GTK dialogs, Kerberos).
    gdk-pixbuf
    gtk4
    libkrb5
    libpulseaudio
    libva
    libxcursor
    pipewire
  ];

  # GSettings schemas are data, not libraries, so nix-ld cannot provide them.
  environment.sessionVariables.GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";

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
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      pkgs.fcitx5-mozc
      pkgs.fcitx5-gtk
    ];
  };
  fonts = {
    packages = with pkgs; [
      ibm-plex
      plemoljp
      plemoljp-hs
      plemoljp-nf
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
    ];
    fontDir.enable = true;
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "IBM Plex Sans JP" ];
        sansSerif = [ "IBM Plex Sans JP" ];
        monospace = [ "PlemolJP Console NF" ];
      };
    };
  };

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
  environment.sessionVariables.COSMIC_DATE_CONTROL_ENABLED = "1";

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
      "gamemode"
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
  programs.gamemode = {
    enable = true;
    settings.gpu = {
      apply_gpu_optimisations = "accept-responsibility";
      gpu_device = 1;
      amd_performance_level = "high";
    };
  };
}
