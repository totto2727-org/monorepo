# syntax=docker/dockerfile:1

# Base
# https://github.com/jetify-com/devbox/blob/3ec20383af8deeb46c94972996d275b1593e63e2/internal/devbox/generate/tmpl/DevboxImageDockerfile
# https://github.com/NVIDIA/OpenShell-Community/blob/6daeacdf199afdd49753ddd149a9c259921ab1a8/sandboxes/base/Dockerfile

FROM ubuntu:26.04

# Setup Nix
## Install dependencies
RUN <<EOF
apt-get update
apt-get upgrade -y

# For share
apt-get install -y curl gcc make

# For sandbox
apt-get install -y \
ca-certificates \
dnsutils \
iproute2 \
iptables \
iputils-ping \
net-tools \
netcat-openbsd \
openssh-sftp-server \
procps \
traceroute

# For nix
apt-get install -y xz-utils git
rm -rf /var/lib/apt/lists/*
EOF

ARG TARGETPLATFORM
RUN <<EOF
# For sandbox
groupadd -r supervisor
useradd -r -g supervisor -s /usr/sbin/nologin supervisor

groupadd -r sandbox
useradd -r -g sandbox -d /sandbox -s /bin/bash sandbox

# For nix
mkdir -p /etc/nix/

if [ "$TARGETPLATFORM" = "linux/arm64" ] || [ "$TARGETPLATFORM" = "linux/arm64/v8" ]; then
    echo "filter-syscalls = false" >> /etc/nix/nix.conf;
fi

echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

mkdir /nix
chown sandbox:sandbox /nix
EOF

USER sandbox
WORKDIR /sandbox
ENV USER=sandbox
ENV PATH="/sandbox/.nix-profile/bin:/sandbox/.moon/bin:/sandbox/.vite-plus/bin:/sandbox/.local/bin:$PATH"

## Install the sandbox-user toolchain (nix + home-manager + moonbit + vp + claude).
## MoonBit's installer needs a node runtime and a rustup-managed Rust toolchain,
## but `moon` itself is a self-bootstrapping native binary. We activate rustup
## and nodejs ephemerally via `nix shell`, run the installer, then drop every
## transient on-disk artifact (rustup/cargo/npm/XDG cache/tmp) and reclaim the
## temporary nix-store paths via `nix-collect-garbage -d`. The trailing
## `moon update` doubles as a smoke test that moon works without rust/node.
## (`moon upgrade` is excluded — it's marked highly experimental and aborts
## with "not a terminal" inside non-interactive Docker builds.)
RUN <<EOF
curl -fsSL https://nixos.org/nix/install | sh -s -- --no-daemon
. ~/.nix-profile/etc/profile.d/nix.sh

nix run home-manager/release-25.11 -- init --switch

nix shell nixpkgs#rustup nixpkgs#nodejs --command bash -c '
rustup default stable
curl -fsSL https://raw.githubusercontent.com/moonbitlang/moonbit-compiler/refs/heads/main/install.ts | node
'

curl -fsSL https://vite.plus | bash
curl -fsSL https://claude.ai/install.sh | bash

rm -rf ~/.rustup ~/.cargo ~/.npm ~/.cache /tmp/*
nix-collect-garbage -d

moon update
EOF

ENTRYPOINT [ "/bin/bash" ]
