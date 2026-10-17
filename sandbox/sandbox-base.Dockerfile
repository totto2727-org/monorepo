# syntax=docker/dockerfile:1

# Shared non-root runtime for local containers and Cloudflare-derived images.
FROM ubuntu:26.04

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN <<EOF
apt-get update
apt-get install -y --no-install-recommends \
  bash ca-certificates curl gcc make libstdc++6 \
  dnsutils iproute2 iptables iputils-ping net-tools netcat-openbsd \
  openssh-sftp-server procps traceroute \
  xz-utils git
rm -rf /var/lib/apt/lists/*

groupadd -r supervisor
useradd -r -g supervisor -s /usr/sbin/nologin supervisor
groupadd -r sandbox
useradd -r -m -g sandbox -d /sandbox -s /bin/bash sandbox

mkdir -p /etc/nix /nix
printf 'experimental-features = nix-command flakes\n' > /etc/nix/nix.conf
chown sandbox:sandbox /nix
EOF

USER sandbox
WORKDIR /sandbox
ENV HOME=/sandbox USER=sandbox
ENV PATH="/sandbox/.local/bin:/sandbox/.nix-profile/bin:$PATH"

# An explicit release tag can be supplied for reproducible Jcode releases.
ARG JCODE_VERSION
RUN <<EOF
curl -fsSL https://nixos.org/nix/install -o /tmp/install-nix.sh
sh /tmp/install-nix.sh --no-daemon --yes --no-channel-add
curl -fsSL https://jcode.sh/install -o /tmp/install-jcode.sh
JCODE_SKIP_SERVER_RELOAD=1 JCODE_NO_TELEMETRY=1 bash /tmp/install-jcode.sh
jcode --version
nix --version
rm -f /tmp/install-nix.sh /tmp/install-jcode.sh
rm -rf /sandbox/.cache
EOF

ENTRYPOINT ["/bin/bash"]
