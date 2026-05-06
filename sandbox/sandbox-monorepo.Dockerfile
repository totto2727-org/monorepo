# syntax=docker/dockerfile:1

FROM ghcr.io/totto2727-org/monorepo/sandbox-dev:latest

SHELL ["zsh", "-c"]

COPY policy.yaml /etc/openshell/policy.yaml

RUN <<EOF
export GIT_CONFIG_GLOBAL=/dev/null
git clone https://github.com/totto2727-org/monorepo.git ~/monorepo
cd ~/monorepo

devbox install
eval "$(devbox shellenv)"
direnv allow

vp config
vp i
vp run workspace:setup
EOF

WORKDIR /sandbox/monorepo
