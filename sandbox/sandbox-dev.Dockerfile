# syntax=docker/dockerfile:1

ARG SANDBOX_BASE_IMAGE=ghcr.io/totto2727-org/monorepo/sandbox-base:latest
FROM ${SANDBOX_BASE_IMAGE}

# Keep every local flake input in the same source snapshot.
COPY --chown=sandbox:sandbox nix/share /home/sandbox/nix/share
COPY --chown=sandbox:sandbox nix/npm-package /home/sandbox/nix/npm-package
COPY --chown=sandbox:sandbox nix/sandbox /home/sandbox/nix/sandbox

ARG TARGETARCH
RUN <<EOF
case "$TARGETARCH" in
  amd64) NIX_SYSTEM=x86_64-linux ;;
  arm64) NIX_SYSTEM=aarch64-linux ;;
  *) echo "unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;;
esac

# A Git flake preserves sibling path inputs within the source snapshot.
git -C /home/sandbox/nix init
git -C /home/sandbox/nix add .
nix build ~/nix/sandbox#homeConfigurations.sandbox-${NIX_SYSTEM}.activationPackage --out-link /home/sandbox/home-manager-result
/home/sandbox/home-manager-result/activate
home-manager --version

chezmoi init https://github.com/totto2727-dotfiles/chezmoi.git
chezmoi apply
nix-collect-garbage -d
rm -rf /home/sandbox/.cache
EOF

SHELL ["/home/sandbox/.nix-profile/bin/zsh", "-e", "-c"]

ENTRYPOINT ["/home/sandbox/.nix-profile/bin/zsh"]
