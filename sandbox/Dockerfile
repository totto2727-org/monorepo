# syntax=docker/dockerfile:1

FROM ghcr.io/totto2727-org/monorepo/sandbox-base:latest

SHELL ["zsh", "-c"]

COPY policy.yaml /etc/openshell/policy.yaml

RUN <<EOF
git clone https://github.com/totto2727-org/monorepo.git
cd monorepo
direnv allow
vp i
vp run -r prebuild
EOF

WORKDIR /sandbox/monorepo
