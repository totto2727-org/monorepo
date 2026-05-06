# syntax=docker/dockerfile:1

FROM ghcr.io/totto2727-org/monorepo/sandbox-dev:latest

SHELL ["zsh", "-c"]

COPY policy.yaml /etc/openshell/policy.yaml

RUN <<EOF
export GIT_CONFIG_GLOBAL=/dev/null
git clone https://github.com/totto2727-org/monorepo.git ~/monorepo
cd ~/monorepo
direnv allow
devbox install
devbox run vp i
devbox run vp run -r setup
EOF

WORKDIR /sandbox/monorepo
