default:
    @just --list

test-setup-typescript:
    #!/usr/bin/env bash
    set -euo pipefail
    action=.github/actions/setup-typescript/action.yaml
    default_frozen=$(awk '/^  frozen:/ { input=1 } input && /default:/ { gsub(/[ '\''"]/, "", $0); sub(/^default:/, "", $0); print; exit }' "$action")
    [[ "$default_frozen" == true ]]
    run=$(awk '/^      run: \|/ { body=1; next } body { sub(/^        /, ""); print }' "$action")
    stub=$'nix() { :; }\nvp() { printf "%s\\n" "$@"; }\n'
    check() {
      local name=$1 frozen=$2 args=$3 expected=$4 output
      output=$(GITHUB_WORKSPACE=/workspace VP_FROZEN="$frozen" VP_INSTALL_ARGS="$args" bash -e -c "$stub$run")
      [[ "$output" == "$expected" ]] || { printf 'FAIL: %s\n%s\n' "$name" "$output"; exit 1; }
      printf 'PASS: %s\n' "$name"
    }
    check default "$default_frozen" '' $'install\n--frozen-lockfile'
    check true true '' $'install\n--frozen-lockfile'
    check false false '' $'install\n--no-frozen-lockfile'
    check default-with-filter "$default_frozen" '--filter @example/app...' $'install\n--frozen-lockfile\n--filter\n@example/app...'
    check false-with-filter false '--filter @example/app...' $'install\n--no-frozen-lockfile\n--filter\n@example/app...'
    check legacy-caller "$default_frozen" '--frozen-lockfile' $'install\n--frozen-lockfile\n--frozen-lockfile'
    if output=$(GITHUB_WORKSPACE=/workspace VP_FROZEN=invalid VP_INSTALL_ARGS='' bash -e -c "$stub$run"); then
      echo 'FAIL: invalid input was accepted'; exit 1
    fi
    [[ "$output" == "::error::The frozen input must be 'true' or 'false'." ]]
    echo 'PASS: invalid input stops before installation'

docker-build-sandbox-base:
    docker build --progress=plain -t ghcr.io/totto2727-org/monorepo/sandbox-base:latest -f ./sandbox/sandbox-base.Dockerfile ./sandbox

docker-build-sandbox-dev: docker-build-sandbox-base
    docker build --progress=plain -t ghcr.io/totto2727-org/monorepo/sandbox-dev:latest -f ./sandbox/sandbox-dev.Dockerfile ./sandbox

docker-build-sandbox-monorepo: docker-build-sandbox-dev
    docker build --progress=plain -t ghcr.io/totto2727-org/monorepo/sandbox-monorepo:latest -f ./sandbox/sandbox-monorepo.Dockerfile ./sandbox
