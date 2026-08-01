#!/usr/bin/env bash

set -euo pipefail

publish_log="$(mktemp)"
trap 'rm -f "$publish_log"' EXIT

set +e
moon publish "$@" 2>&1 | tee "$publish_log"
pipeline_status=("${PIPESTATUS[@]}")
set -e

moon_status="${pipeline_status[0]}"
tee_status="${pipeline_status[1]}"

if [[ "$tee_status" -ne 0 ]]; then
  exit "$tee_status"
fi

if [[ "$moon_status" -eq 0 ]]; then
  exit 0
fi

if grep -Fq "409 Conflict" "$publish_log" &&
  grep -Fq "Version Error:" "$publish_log" &&
  grep -Fq "is duplicated with an existing version" "$publish_log"; then
  echo "MoonBit module version is already published; continuing."
  exit 0
fi

exit "$moon_status"
