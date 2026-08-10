#!/usr/bin/env bash

set -euo pipefail

test_root=/tmp/c-plugin-v2-sync-e2e
mkdir -p "$test_root"
test_root=$(CDPATH= cd -- "$test_root" && pwd -P)
test_home=$test_root/home
project_root=$test_home/project
repository_root=$project_root/marketplace
plugin_root=$repository_root/plugins/demo
lock_path=$project_root/c-plugin-lock.json
state_path=$project_root/.agents/c-plugin-state.json
initial_lock=$test_root/initial-lock.json
edited_lock=$test_root/edited-lock.json
initial_stdout=$test_root/initial.stdout
initial_stderr=$test_root/initial.stderr
edited_stdout=$test_root/edited.stdout
edited_stderr=$test_root/edited.stderr

mkdir -p \
  "$test_home" \
  "$repository_root/.claude-plugin" \
  "$plugin_root/skills/alpha" \
  "$plugin_root/skills/beta"
cd "$project_root"

printf '%s\n' \
  '{"name":"fixture","plugins":[{"name":"demo","source":"plugins/demo"}]}' \
  >"$repository_root/.claude-plugin/marketplace.json"
printf '# alpha\n' >"$plugin_root/skills/alpha/SKILL.md"
printf '# beta\n' >"$plugin_root/skills/beta/SKILL.md"
printf '%s\n' \
  '{' \
  '  "version": "2",' \
  '  "targets": [' \
  '    ".cursor/skills"' \
  '  ],' \
  '  "repositories": [' \
  '    {' \
  '      "type": "local",' \
  '      "path": "marketplace",' \
  '      "marketplaceKind": "claude",' \
  '      "plugins": [' \
  '        {' \
  '          "name": "demo",' \
  '          "path": "plugins/demo",' \
  '          "enabledSkills": [' \
  '            "alpha",' \
  '            "beta"' \
  '          ]' \
  '        }' \
  '      ]' \
  '    }' \
  '  ]' \
  '}' >"$lock_path"
cp "$lock_path" "$initial_lock"

set +e
env HOME="$test_home" c-plugin skill sync >"$initial_stdout" 2>"$initial_stderr"
initial_status=$?
set -e

printf 'sync initial status=%s\n' "$initial_status"
[[ $initial_status -eq 0 ]]
grep -F "Synced $lock_path: partial (1 notices, 0 unavailable repositories)" "$initial_stdout" >/dev/null
[[ ! -s $initial_stderr ]]
cmp -s "$initial_lock" "$lock_path"
for target_root in "$project_root/.agents/skills" "$project_root/.cursor/skills"; do
  for skill in alpha beta; do
    link=$target_root/$skill
    [[ -L $link ]]
    [[ $(realpath "$link") == "$plugin_root/skills/$skill" ]]
  done
done
[[ -f $state_path ]]
grep -F '"skill": "alpha"' "$state_path" >/dev/null
grep -F '"skill": "beta"' "$state_path" >/dev/null

primary_root=$project_root/.agents/skills
rm "$primary_root/beta"
printf 'foreign\n' >"$primary_root/beta"
printf 'neighbor\n' >"$primary_root/neighbor"
printf '%s\n' \
  '{' \
  '  "version": "2",' \
  '  "targets": [' \
  '    ".cursor/skills"' \
  '  ],' \
  '  "repositories": [' \
  '    {' \
  '      "type": "local",' \
  '      "path": "marketplace",' \
  '      "marketplaceKind": "claude",' \
  '      "plugins": [' \
  '        {' \
  '          "name": "demo",' \
  '          "path": "plugins/demo",' \
  '          "enabledSkills": []' \
  '        }' \
  '      ]' \
  '    }' \
  '  ]' \
  '}' >"$lock_path"
cp "$lock_path" "$edited_lock"

set +e
env HOME="$test_home" c-plugin skill sync >"$edited_stdout" 2>"$edited_stderr"
edited_status=$?
set -e

printf 'sync edited status=%s\n' "$edited_status"
[[ $edited_status -eq 0 ]]
grep -F "Synced $lock_path: partial (1 notices, 0 unavailable repositories)" "$edited_stdout" >/dev/null
[[ ! -s $edited_stderr ]]
cmp -s "$edited_lock" "$lock_path"
[[ ! -e $primary_root/alpha ]]
[[ ! -e $project_root/.cursor/skills/alpha ]]
[[ ! -e $project_root/.cursor/skills/beta ]]
[[ -f $primary_root/beta ]]
[[ ! -L $primary_root/beta ]]
grep -Fx 'foreign' "$primary_root/beta" >/dev/null
grep -Fx 'neighbor' "$primary_root/neighbor" >/dev/null
compact_state=$(tr -d '[:space:]' <"$state_path")
[[ $compact_state == '{"version":"1","entries":[]}' ]]

printf 'PASS: sync local marketplace reconciliation\n'
