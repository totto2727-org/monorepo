# syntax=docker/dockerfile:1

FROM ghcr.io/totto2727-org/monorepo/sandbox-base:latest

USER sandbox
ENV HOME=/sandbox
WORKDIR /sandbox

RUN --mount=type=bind,source=mbt,target=/src,readonly <<'EOF'
set -eu
. /sandbox/.nix-profile/etc/profile.d/nix.sh
nix --option sandbox false --option filter-syscalls false \
  build path:/src#c-plugin --out-link /tmp/c-plugin-result
install -Dm755 /tmp/c-plugin-result/bin/c-plugin /sandbox/.local/bin/c-plugin
rm /tmp/c-plugin-result
EOF

COPY --chown=sandbox:sandbox --chmod=0755 sandbox/verify-c-plugin.sh /sandbox/verify-c-plugin.sh

ENTRYPOINT ["/sandbox/verify-c-plugin.sh"]
CMD ["all"]
