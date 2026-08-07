#!/usr/bin/env bash

set -euo pipefail

scenario=${1:-}
case "$scenario" in
  project | global) ;;
  *)
    printf 'Usage: %s project|global\n' "$0" >&2
    exit 2
    ;;
esac

test_root=/tmp/c-plugin-v2-e2e
test_home=$test_root/home
project_root=$test_root/totto2727-org/monorepo
expected_lock=$test_root/expected-lock.json
expected_stdout=$test_root/expected-stdout.txt
initial_stdout=$test_root/initial.stdout
initial_stderr=$test_root/initial.stderr
repeat_stdout=$test_root/repeat.stdout
repeat_stderr=$test_root/repeat.stderr
original_lock=$test_root/original-lock.json

mkdir -p "$test_home" "$project_root"
cd "$project_root"

printf '%s\n' \
  '{' \
  '  "version": "2",' \
  '  "targets": [],' \
  '  "repositories": []' \
  '}' >"$expected_lock"

if [[ $scenario == project ]]; then
  lock_path=$project_root/c-plugin-lock.json
  opposite_lock=$test_home/c-plugin-lock.json
  initial_command=(env HOME="$test_home" c-plugin init)
  repeat_command=(env HOME="$test_home" c-plugin init)
else
  lock_path=$test_home/c-plugin-lock.json
  opposite_lock=$project_root/c-plugin-lock.json
  initial_command=(env HOME="$test_home" c-plugin init -g)
  repeat_command=(env HOME="$test_home" c-plugin init --global)
fi

set +e
"${initial_command[@]}" >"$initial_stdout" 2>"$initial_stderr"
initial_status=$?
set -e

printf '%s initial status=%s\n' "$scenario" "$initial_status"
[[ $initial_status -eq 0 ]]
printf 'Created %s\n' "$lock_path" >"$expected_stdout"
cmp -s "$expected_stdout" "$initial_stdout"
[[ ! -s $initial_stderr ]]
cmp -s "$expected_lock" "$lock_path"
[[ ! -e $opposite_lock ]]

cp "$lock_path" "$original_lock"
set +e
"${repeat_command[@]}" >"$repeat_stdout" 2>"$repeat_stderr"
repeat_status=$?
set -e

printf '%s repeat status=%s\n' "$scenario" "$repeat_status"
[[ $repeat_status -ne 0 ]]
grep -Fx 'totto2727/c-plugin-v2.StateStoreError.AlreadyExists' "$repeat_stdout" >/dev/null
[[ ! -s $repeat_stderr ]]
cmp -s "$original_lock" "$lock_path"
[[ ! -e $opposite_lock ]]
[[ ! -e $project_root/.agents ]]
[[ ! -e $test_home/.agents ]]
[[ ! -e $test_home/.cache/c-plugin ]]

printf 'PASS: init %s\n' "$scenario"
