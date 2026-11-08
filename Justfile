default:
    @just --list

# Generate the adoption manifest from the same inventory used by the Pulumi program.
github-import-manifest:
    @jq '{resources: [.[] | {type: "github:index/repository:Repository", name: ("repository-" + .name), id: .name}]}' infra/github/repositories.json

docker-build-nix:
    docker build --progress=plain -t ghcr.io/totto2727-org/monorepo/nix:latest -f ./sandbox/nix.Dockerfile ./sandbox

docker-build-sandbox-base: docker-build-nix
    docker build --progress=plain -t ghcr.io/totto2727-org/monorepo/sandbox-base:latest -f ./sandbox/sandbox-base.Dockerfile .
