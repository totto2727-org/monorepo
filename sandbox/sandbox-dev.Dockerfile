# syntax=docker/dockerfile:1

ARG SANDBOX_BASE_IMAGE=ghcr.io/totto2727-org/monorepo/sandbox-base:latest
FROM ${SANDBOX_BASE_IMAGE}

# Keep every local flake input in the same source snapshot.
COPY --chown=sandbox:sandbox nix/share /sandbox/nix/share
COPY --chown=sandbox:sandbox nix/npm-package /sandbox/nix/npm-package
COPY --chown=sandbox:sandbox nix/sandbox /sandbox/nix/sandbox

ARG TARGETARCH
RUN <<EOF
case "$TARGETARCH" in
  amd64) NIX_SYSTEM=x86_64-linux ;;
  arm64) NIX_SYSTEM=aarch64-linux ;;
  *) echo "unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;;
esac

# A Git flake preserves sibling path inputs within the source snapshot.
git -C /sandbox/nix init
git -C /sandbox/nix add .
nix build ~/nix/sandbox#homeConfigurations.sandbox-${NIX_SYSTEM}.activationPackage --out-link /sandbox/home-manager-result
/sandbox/home-manager-result/activate
home-manager --version
jcode --version

chezmoi init https://github.com/totto2727-dotfiles/chezmoi.git
chezmoi apply
nix-collect-garbage -d
rm -rf /sandbox/.cache
EOF

SHELL ["/sandbox/.nix-profile/bin/zsh", "-e", "-c"]

ENTRYPOINT ["/sandbox/.nix-profile/bin/zsh"]
