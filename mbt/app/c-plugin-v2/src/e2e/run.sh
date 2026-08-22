#!/usr/bin/env bash

set -euo pipefail

e2e_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repository_root=$(CDPATH= cd -- "$e2e_dir/../../../../.." && pwd -P)

if [[ $(pwd -P) != "$repository_root" ]]; then
  printf 'Run %s from the repository root.\n' "$0" >&2
  exit 2
fi

image='c-plugin-v2-sync:local'
platform_args=()
if [[ -n ${C_PLUGIN_E2E_PLATFORM:-} ]]; then
  platform_args=(--platform "$C_PLUGIN_E2E_PLATFORM")
fi
build_context=$(mktemp -d "${TMPDIR:-/tmp}/c-plugin-v2-e0-context.XXXXXX")
before_state=$(mktemp "${TMPDIR:-/tmp}/c-plugin-v2-e0-before.XXXXXX")
after_state=$(mktemp "${TMPDIR:-/tmp}/c-plugin-v2-e0-after.XXXXXX")

cleanup() {
  rm -rf -- "$build_context"
  rm -f -- "$before_state" "$after_state"
}
trap cleanup EXIT INT TERM

git ls-files -z -- moon.work mbt | \
  tar --null -T - -cf - | \
  tar -xf - -C "$build_context"

snapshot_path() {
  local path=$1
  if [[ -L $path ]]; then
    printf 'link %s %s\n' "$path" "$(readlink "$path")"
  elif [[ -f $path ]]; then
    printf 'file %s ' "$path"
    cksum "$path"
  elif [[ -d $path ]]; then
    printf 'directory %s ' "$path"
    tar -cf - -C "$(dirname -- "$path")" "$(basename -- "$path")" | cksum
  else
    printf 'absent %s\n' "$path"
  fi
}

snapshot_host_state() {
  snapshot_path "$repository_root/c-plugin-lock.json"
  snapshot_path "$repository_root/.agents"
  snapshot_path "$HOME/c-plugin-lock.json"
  snapshot_path "$HOME/.agents"
  snapshot_path "$HOME/.cache/c-plugin"
}

snapshot_host_state >"$before_state"

docker build \
  "${platform_args[@]}" \
  --file "$e2e_dir/Dockerfile" \
  --tag "$image" \
  "$build_context"

docker run --rm "${platform_args[@]}" "$image" project
docker run --rm "${platform_args[@]}" "$image" global
docker run --rm "${platform_args[@]}" \
  --entrypoint /sandbox/e2e/sync.sh \
  "$image"

snapshot_host_state >"$after_state"
if ! cmp -s "$before_state" "$after_state"; then
  diff -u "$before_state" "$after_state" >&2 || true
  printf 'Host state changed during c-plugin-v2 E2E.\n' >&2
  exit 1
fi

printf 'PASS: c-plugin-v2 init and sync Docker E2E\n'
