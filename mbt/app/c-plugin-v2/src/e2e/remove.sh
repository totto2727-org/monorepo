#!/usr/bin/env bash

set -euo pipefail

test_root=/tmp/c-plugin-v2-remove-e2e
rm -rf -- "$test_root"
trap 'rm -rf -- "$test_root"' EXIT INT TERM
test_home=$test_root/home
project_root=$test_home/project
project_repository=$project_root/marketplace
project_plugin=$project_repository/plugins/demo
project_lock=$project_root/c-plugin-lock.json
project_state=$project_root/.agents/c-plugin-state.json
project_skills=$project_root/.agents/skills

mkdir -p "$project_repository/.claude-plugin" "$project_plugin/skills/alpha" "$project_plugin/skills/beta"
printf '%s\n' '{"name":"fixture","plugins":[{"name":"demo","source":"plugins/demo"}]}' >"$project_repository/.claude-plugin/marketplace.json"
printf '# alpha\n' >"$project_plugin/skills/alpha/SKILL.md"
printf '# beta\n' >"$project_plugin/skills/beta/SKILL.md"
printf '%s\n' '{"version":"2","targets":[],"repositories":[{"type":"local","path":"marketplace","marketplaceKind":"claude","plugins":[{"name":"demo","path":"plugins/demo","enabledSkills":["alpha","beta"]}]}]}' >"$project_lock"

cd "$project_root"
env HOME="$test_home" c-plugin skill sync >/dev/null
rm -- "$project_skills/alpha"
printf 'replacement\n' >"$project_skills/alpha"
printf 'foreign\n' >"$project_skills/neighbor"
project_lock_hash=$(cksum "$project_lock")
project_state_hash=$(cksum "$project_state")
empty_output=$(env HOME="$test_home" c-plugin skill remove)
[[ $empty_output == "No skill changes for $project_lock" ]]
unknown_output=$(env HOME="$test_home" c-plugin skill remove --skill marketplace/demo/unknown)
[[ $unknown_output == "No skill changes for $project_lock" ]]
[[ $(cksum "$project_lock") == "$project_lock_hash" ]]
[[ $(cksum "$project_state") == "$project_state_hash" ]]

alpha_output=$(env HOME="$test_home" c-plugin skill remove --skill marketplace/./demo/alpha)
[[ $alpha_output == "Removed skills marketplace/demo/alpha from $project_lock: partial (1 notices, 0 unavailable repositories)" ]]
compact_project_lock=$(tr -d '[:space:]' <"$project_lock")
[[ $compact_project_lock == '{"version":"2","targets":[],"repositories":[{"type":"local","path":"marketplace","marketplaceKind":"claude","plugins":[{"name":"demo","path":"plugins/demo","enabledSkills":["beta"]}]}]}' ]]
[[ $(<"$project_skills/alpha") == replacement ]]
[[ $(<"$project_skills/neighbor") == foreign ]]
[[ -L $project_skills/beta ]]
! grep -F '"skill": "alpha"' "$project_state" >/dev/null
grep -F '"skill": "beta"' "$project_state" >/dev/null

project_lock_hash=$(cksum "$project_lock")
project_state_hash=$(cksum "$project_state")
repeat_output=$(env HOME="$test_home" c-plugin skill remove --skill marketplace/demo/alpha)
[[ $repeat_output == "No skill changes for $project_lock" ]]
[[ $(cksum "$project_lock") == "$project_lock_hash" ]]
[[ $(cksum "$project_state") == "$project_state_hash" ]]

beta_output=$(env HOME="$test_home" c-plugin skill remove --skill marketplace/demo/beta)
[[ $beta_output == "Removed skills marketplace/demo/beta from $project_lock: complete (0 notices, 0 unavailable repositories)" ]]
compact_project_lock=$(tr -d '[:space:]' <"$project_lock")
[[ $compact_project_lock == '{"version":"2","targets":[],"repositories":[]}' ]]
[[ ! -e $project_skills/beta ]]
[[ $(<"$project_skills/alpha") == replacement ]]
[[ $(<"$project_skills/neighbor") == foreign ]]

global_repository=$test_home/global-marketplace
global_plugin=$global_repository/plugins/demo
global_lock=$test_home/c-plugin-lock.json
global_state=$test_home/.agents/c-plugin-state.json
mkdir -p "$global_repository/.claude-plugin" "$global_plugin/skills/gamma" "$project_root/nested"
printf '%s\n' '{"name":"fixture","plugins":[{"name":"demo","source":"plugins/demo"}]}' >"$global_repository/.claude-plugin/marketplace.json"
printf '# gamma\n' >"$global_plugin/skills/gamma/SKILL.md"
printf '%s\n' '{"version":"2","targets":[],"repositories":[{"type":"local","path":"global-marketplace","marketplaceKind":"claude","plugins":[{"name":"demo","path":"plugins/demo","enabledSkills":["gamma"]}]}]}' >"$global_lock"

cd "$project_root/nested"
env HOME="$test_home" c-plugin skill sync --global >/dev/null
global_output=$(env HOME="$test_home" c-plugin skill remove --global --skill global-marketplace/demo/gamma)
[[ $global_output == "Removed skills global-marketplace/demo/gamma from $global_lock: complete (0 notices, 0 unavailable repositories)" ]]
grep -F '"repositories": []' "$global_lock" >/dev/null
[[ ! -e $test_home/.agents/skills/gamma ]]
! grep -F '"skill": "gamma"' "$global_state" >/dev/null

printf 'PASS: skill remove cleanup, pruning, no-op, and global scope\n'
