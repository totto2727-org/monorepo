# syntax=docker/dockerfile:1

FROM ghcr.io/totto2727-org/monorepo/sandbox-base:latest

RUN <<EOF
nix run nixpkgs#git clone https://github.com/totto2727-dotfiles/nix.git
nix run nixpkgs#git clone https://github.com/totto2727-dotfiles/chezmoi.git
home-manager switch --flake ~/nix/sandbox#sandbox
EOF

SHELL ["zsh", "-c"]

RUN <<EOF
rustup default stable
curl -fsSL https://raw.githubusercontent.com/moonbitlang/moonbit-compiler/refs/heads/main/install.ts | node
moon update
curl -fsSL https://vite.plus | bash
curl -fsSL https://claude.ai/install.sh | bash

chezmoi apply --source ~/chezmoi
EOF

ENTRYPOINT [ "zsh" ]
