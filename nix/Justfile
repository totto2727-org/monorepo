default:
    @just --list

[working-directory: 'macos']
rebuild-macos:
    sudo nix flake update --option access-tokens "github.com=$(gh auth token)"
    sudo nix run nix-darwin -- switch --flake .

[working-directory: 'macos-work']
rebuild-macos-work:
    sudo nix flake update --option access-tokens "github.com=$(gh auth token)"
    sudo nix run nix-darwin -- switch --flake .

[working-directory: 'nixos']
rebuild-nixos:
    sudo nix flake update --option access-tokens "github.com=$(gh auth token)"
    sudo nixos-rebuild switch --flake .#nixos
    mkdir -p $HOME/.local/share/fonts && cp -f -L /run/current-system/sw/share/X11/fonts/* $HOME/.local/share/fonts/
    flatpak --user override --filesystem=$HOME/.local/share/fonts:ro
    flatpak --user override --filesystem=$HOME/.icons:ro
    flatpak update -y

[working-directory: 'nixos-server']
rebuild-nixos-server:
    sudo nix flake update --option access-tokens "github.com=$(gh auth token)"
    sudo nixos-rebuild switch --flake .#nixos
