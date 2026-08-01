#!/usr/bin/env bash

set -euo pipefail

moon() {
  if [[ "${1:-}" != "publish" || "${2:-}" != "--frozen" ]]; then
    echo "unexpected moon arguments: $*" >&2
    return 64
  fi

  case "${MOON_PUBLISH_TEST_SCENARIO:-}" in
    success)
      echo "Server status: 200 OK"
      return 0
      ;;
    duplicate)
      printf 'Server status: \033[1;31m409 Conflict\033[0m, detail: Version Error: The version you are attempting to upload (0.1.1) is duplicated with an existing version (0.1.1). Please select a different version to publish.\n'
      echo 'Error: `moon publish` failed'
      return 1
      ;;
    unauthorized)
      echo "Server status: 401 Unauthorized, detail: invalid credentials"
      return 1
      ;;
    other-conflict)
      echo "Server status: 409 Conflict, detail: Module ownership mismatch"
      return 1
      ;;
    *)
      echo "unknown test scenario" >&2
      return 64
      ;;
  esac
}

export -f moon

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
wrapper="$repo_root/mbt/scripts/moon-publish.sh"

run_case() {
  local scenario="$1"
  local expected_status="$2"
  local expected_output="$3"
  local output
  local status

  set +e
  output="$(MOON_PUBLISH_TEST_SCENARIO="$scenario" bash "$wrapper" --frozen 2>&1)"
  status=$?
  set -e

  if [[ "$status" -ne "$expected_status" ]]; then
    printf 'scenario %s: expected status %s, got %s\n%s\n' "$scenario" "$expected_status" "$status" "$output" >&2
    exit 1
  fi

  if ! grep -Fq "$expected_output" <<<"$output"; then
    printf 'scenario %s: missing output %s\n%s\n' "$scenario" "$expected_output" "$output" >&2
    exit 1
  fi
}

run_case success 0 "Server status: 200 OK"
run_case duplicate 0 "MoonBit module version is already published; continuing."
run_case unauthorized 1 "401 Unauthorized"
run_case other-conflict 1 "Module ownership mismatch"

echo "moon publish wrapper tests passed"
