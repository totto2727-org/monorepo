#!/usr/bin/env bash

set -euo pipefail

test_root=/tmp/c-plugin-v2-target-remove-e2e
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
printf '%s\n' '{"version":"2","targets":[".cursor/skills",".claude/skills"],"repositories":[{"type":"local","path":"marketplace","marketplaceKind":"claude","plugins":[{"name":"demo","path":"plugins/demo","enabledSkills":["alpha"]}]}]}' >"$project_lock"

cd "$project_root"
env HOME="$test_home" c-plugin skill sync >/dev/null
printf 'foreign\n' >"$project_root/.cursor/skills/neighbor"
project_lock_hash=$(cksum "$project_lock")
project_state_hash=$(cksum "$project_state")
unknown_output=$(env HOME="$test_home" c-plugin skill target remove --target .vscode/skills)
[[ $unknown_output == "No target changes for $project_lock" ]]
empty_output=$(env HOME="$test_home" c-plugin skill target remove)
[[ $empty_output == "No target changes for $project_lock" ]]
[[ $(cksum "$project_lock") == "$project_lock_hash" ]]
[[ $(cksum "$project_state") == "$project_state_hash" ]]

cursor_output=$(env HOME="$test_home" c-plugin skill target remove --target .cursor/./skills)
[[ $cursor_output == "Removed targets .cursor/skills from $project_lock: complete (0 notices, 0 unavailable repositories)" ]]
compact_project_lock=$(tr -d '[:space:]' <"$project_lock")
[[ $compact_project_lock == '{"version":"2","targets":[".claude/skills"],"repositories":[{"type":"local","path":"marketplace","marketplaceKind":"claude","plugins":[{"name":"demo","path":"plugins/demo","enabledSkills":["alpha"]}]}]}' ]]
[[ ! -e $project_root/.cursor/skills/alpha ]]
[[ $(<"$project_root/.cursor/skills/neighbor") == foreign ]]
for root in "$project_root/.agents/skills" "$project_root/.claude/skills"; do
  [[ -L $root/alpha ]]
  [[ $(realpath "$root/alpha") == "$project_plugin/skills/alpha" ]]
done
! grep -F "\"managedRoot\": \"$project_root/.cursor/skills\"" "$project_state" >/dev/null
grep -F "\"managedRoot\": \"$project_root/.claude/skills\"" "$project_state" >/dev/null

claude_output=$(env HOME="$test_home" c-plugin skill target remove --target .claude/skills)
[[ $claude_output == "Removed targets .claude/skills from $project_lock: complete (0 notices, 0 unavailable repositories)" ]]
compact_project_lock=$(tr -d '[:space:]' <"$project_lock")
[[ $compact_project_lock == '{"version":"2","targets":[],"repositories":[{"type":"local","path":"marketplace","marketplaceKind":"claude","plugins":[{"name":"demo","path":"plugins/demo","enabledSkills":["alpha"]}]}]}' ]]
[[ ! -e $project_root/.claude/skills/alpha ]]
[[ -L $project_root/.agents/skills/alpha ]]
[[ $(<"$project_root/.cursor/skills/neighbor") == foreign ]]
! grep -F "$project_root/.cursor/skills" "$project_state" >/dev/null
! grep -F "$project_root/.claude/skills" "$project_state" >/dev/null

global_repository=$test_home/global-marketplace
global_plugin=$global_repository/plugins/demo
global_lock=$test_home/c-plugin-lock.json
global_state=$test_home/.agents/c-plugin-state.json
mkdir -p "$global_repository/.claude-plugin" "$global_plugin/skills/beta" "$project_root/nested"
printf '%s\n' '{"name":"fixture","plugins":[{"name":"demo","source":"plugins/demo"}]}' >"$global_repository/.claude-plugin/marketplace.json"
printf '# beta\n' >"$global_plugin/skills/beta/SKILL.md"
printf '%s\n' '{"version":"2","targets":[".cursor/skills"],"repositories":[{"type":"local","path":"global-marketplace","marketplaceKind":"claude","plugins":[{"name":"demo","path":"plugins/demo","enabledSkills":["beta"]}]}]}' >"$global_lock"

cd "$project_root/nested"
env HOME="$test_home" c-plugin skill sync --global >/dev/null
global_output=$(env HOME="$test_home" c-plugin skill target remove --global --target .cursor/skills)
[[ $global_output == "Removed targets .cursor/skills from $global_lock: complete (0 notices, 0 unavailable repositories)" ]]
grep -F '"targets": []' "$global_lock" >/dev/null
[[ ! -e $test_home/.cursor/skills/beta ]]
[[ -L $test_home/.agents/skills/beta ]]
! grep -F "$test_home/.cursor/skills" "$global_state" >/dev/null

printf 'PASS: target remove cleanup, no-op, isolation, and global scope\n'
