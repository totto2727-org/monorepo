#!/usr/bin/env bash

set -euo pipefail

test_root=/tmp/c-plugin-v2-target-add-e2e
rm -rf -- "$test_root"
trap 'rm -rf -- "$test_root"' EXIT INT TERM
test_home=$test_root/home
project_root=$test_home/project
project_repository=$project_root/marketplace
project_plugin=$project_repository/plugins/demo
project_lock=$project_root/c-plugin-lock.json
project_state=$project_root/.agents/c-plugin-state.json

mkdir -p "$project_repository/.claude-plugin" "$project_plugin/skills/alpha"
printf '%s\n' '{"name":"fixture","plugins":[{"name":"demo","source":"plugins/demo"}]}' >"$project_repository/.claude-plugin/marketplace.json"
printf '# alpha\n' >"$project_plugin/skills/alpha/SKILL.md"
printf '%s\n' '{"version":"2","targets":[],"repositories":[{"type":"local","path":"marketplace","marketplaceKind":"claude","plugins":[{"name":"demo","path":"plugins/demo","enabledSkills":["alpha"]}]}]}' >"$project_lock"

cd "$project_root"
project_output=$(env HOME="$test_home" c-plugin skill target add .cursor/skills)
[[ $project_output == "Added target .cursor/skills to $project_lock: partial (1 notices, 0 unavailable repositories)" ]]
compact_project_lock=$(tr -d '[:space:]' <"$project_lock")
[[ $compact_project_lock == '{"version":"2","targets":[".cursor/skills"],"repositories":[{"type":"local","path":"marketplace","marketplaceKind":"claude","plugins":[{"name":"demo","path":"plugins/demo","enabledSkills":["alpha"]}]}]}' ]]
for root in "$project_root/.agents/skills" "$project_root/.cursor/skills"; do
  [[ -L $root/alpha ]]
  [[ $(realpath "$root/alpha") == "$project_plugin/skills/alpha" ]]
done
grep -F "\"managedRoot\": \"$project_root/.agents/skills\"" "$project_state" >/dev/null
grep -F "\"managedRoot\": \"$project_root/.cursor/skills\"" "$project_state" >/dev/null

project_lock_hash=$(cksum "$project_lock")
project_state_hash=$(cksum "$project_state")
repeat_output=$(env HOME="$test_home" c-plugin skill target add .cursor/./skills)
[[ $repeat_output == "Target .cursor/skills already registered in $project_lock" ]]
[[ $(cksum "$project_lock") == "$project_lock_hash" ]]
[[ $(cksum "$project_state") == "$project_state_hash" ]]

global_repository=$test_home/global-marketplace
global_plugin=$global_repository/plugins/demo
global_lock=$test_home/c-plugin-lock.json
global_state=$test_home/.agents/c-plugin-state.json
mkdir -p "$global_repository/.claude-plugin" "$global_plugin/skills/beta" "$project_root/nested"
printf '%s\n' '{"name":"fixture","plugins":[{"name":"demo","source":"plugins/demo"}]}' >"$global_repository/.claude-plugin/marketplace.json"
printf '# beta\n' >"$global_plugin/skills/beta/SKILL.md"
printf '%s\n' '{"version":"2","targets":[],"repositories":[{"type":"local","path":"global-marketplace","marketplaceKind":"claude","plugins":[{"name":"demo","path":"plugins/demo","enabledSkills":["beta"]}]}]}' >"$global_lock"

cd "$project_root/nested"
global_output=$(env HOME="$test_home" c-plugin skill target add .claude/skills --global)
[[ $global_output == "Added target .claude/skills to $global_lock: partial (1 notices, 0 unavailable repositories)" ]]
for root in "$test_home/.agents/skills" "$test_home/.claude/skills"; do
  [[ -L $root/beta ]]
  [[ $(realpath "$root/beta") == "$global_plugin/skills/beta" ]]
done
grep -F '"targets": [' "$global_lock" >/dev/null
grep -F '".claude/skills"' "$global_lock" >/dev/null
grep -F "\"managedRoot\": \"$test_home/.claude/skills\"" "$global_state" >/dev/null

printf 'PASS: target add project/global and repeat no-op\n'
