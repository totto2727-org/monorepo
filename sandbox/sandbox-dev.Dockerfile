# syntax=docker/dockerfile:1

FROM ghcr.io/totto2727-org/monorepo/sandbox-base:latest

# Sparse-checkout `nix/share` + `nix/sandbox` from the monorepo (blobless partial
# clone), then symlink ~/.local/share/sandbox-flake/nix to ~/nix so the flake alias
# `~/nix/sandbox#sandbox` resolves.
RUN <<EOF
git clone --filter=tree:0 --no-checkout https://github.com/totto2727-org/monorepo.git ~/.local/share/sandbox-flake
cd ~/.local/share/sandbox-flake
git sparse-checkout init --cone
git sparse-checkout set nix/share nix/sandbox
git checkout
ln -s ~/.local/share/sandbox-flake/nix ~/nix
home-manager switch --flake ~/nix/sandbox#sandbox
EOF

RUN <<EOF
git clone https://github.com/totto2727-dotfiles/chezmoi.git ~/chezmoi
chezmoi apply --source ~/chezmoi
EOF

SHELL ["zsh", "-c"]

ENTRYPOINT [ "zsh" ]
