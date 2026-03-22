# syntax=docker/dockerfile:1

# Base
# https://github.com/jetify-com/devbox/blob/3ec20383af8deeb46c94972996d275b1593e63e2/internal/devbox/generate/tmpl/DevboxImageDockerfile
# https://github.com/NVIDIA/OpenShell-Community/blob/6daeacdf199afdd49753ddd149a9c259921ab1a8/sandboxes/base/Dockerfile

FROM ubuntu:26.04 AS base

# Setup Nix
## Install dependencies
RUN <<EOF
apt-get update
apt-get upgrade -y

# For share
apt-get install -y --no-install-recommends curl

# For sandbox
apt-get install -y --no-install-recommends \
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
apt-get install -y --no-install-recommends xz-utils git
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

## Install Nix
RUN <<EOF
curl -fsSL https://nixos.org/nix/install | sh -s -- --no-daemon
. ~/.nix-profile/etc/profile.d/nix.sh
EOF

ENV PATH="/sandbox/.nix-profile/bin:$PATH"

ENTRYPOINT [ "/bin/bash" ]

FROM base

RUN <<EOF
nix run home-manager/release-25.11 -- init --switch
nix run nixpkgs#git clone https://github.com/totto2727-dotfiles/nix.git
nix run nixpkgs#git clone https://github.com/totto2727-dotfiles/chezmoi.git
home-manager switch --flake ~/nix/sandbox#sandbox

# additional tools
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
curl -fsSL https://vite.plus | bash
curl -fsSL https://claude.ai/install.sh | bash

chezmoi apply --source ~/chezmoi
EOF

ENTRYPOINT [ "zsh" ]
