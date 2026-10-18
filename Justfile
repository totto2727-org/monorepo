default:
    @just --list

docker-build-nix:
    docker build --progress=plain -t ghcr.io/totto2727-org/monorepo/nix:latest -f ./sandbox/nix.Dockerfile ./sandbox

docker-build-sandbox-base: docker-build-nix
    docker build --progress=plain -t ghcr.io/totto2727-org/monorepo/sandbox-base:latest -f ./sandbox/sandbox-base.Dockerfile .
