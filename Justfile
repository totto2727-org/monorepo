default:
    @just --list

docker-build-sandbox-base:
    docker build --progress=plain -t ghcr.io/totto2727-org/monorepo/sandbox-base:latest -f ./sandbox/sandbox-base.Dockerfile ./sandbox

docker-build-sandbox-dev: docker-build-sandbox-base
    docker build --progress=plain -t ghcr.io/totto2727-org/monorepo/sandbox-dev:latest -f ./sandbox/sandbox-dev.Dockerfile ./sandbox

docker-build-sandbox-monorepo: docker-build-sandbox-dev
    docker build --progress=plain -t ghcr.io/totto2727-org/monorepo/sandbox-monorepo:latest -f ./sandbox/sandbox-monorepo.Dockerfile ./sandbox

sandbox-create:
    uvx openshell sandbox create --from ghcr.io/totto2727-org/monorepo/sandbox-monorepo:latest --policy sandbox/policy.yaml
