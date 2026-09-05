#!/usr/bin/env bash

set -euo pipefail

test_root=/tmp/c-plugin-v2-sync-recursive-e2e
test_home=$test_root/home
project_root=$test_home/project
child_root=$project_root/child
ignored_root=$project_root/ignored
initial_stdout=$test_root/initial.stdout
initial_stderr=$test_root/initial.stderr
edited_stdout=$test_root/edited.stdout
edited_stderr=$test_root/edited.stderr

write_marketplace() {
  local root=$1
  local skill=$2
  local repository=$root/marketplace
  mkdir -p "$repository/.claude-plugin" "$repository/plugins/demo/skills/$skill"
  printf '%s\n' \
    '{"name":"fixture","plugins":[{"name":"demo","source":"plugins/demo"}]}' \
    >"$repository/.claude-plugin/marketplace.json"
  printf '# %s\n' "$skill" >"$repository/plugins/demo/skills/$skill/SKILL.md"
}

write_lock() {
  local root=$1
  local enabled_skill=$2
  printf '%s\n' \
    '{' \
    '  "version": "2",' \
    '  "targets": [],' \
    '  "repositories": [' \
    '    {' \
    '      "type": "local",' \
    '      "path": "marketplace",' \
    '      "marketplaceKind": "claude",' \
    '      "plugins": [' \
    '        {' \
    '          "name": "demo",' \
    '          "path": "plugins/demo",' \
    "          \"enabledSkills\": [$enabled_skill]" \
    '        }' \
    '      ]' \
    '    }' \
    '  ]' \
    '}' >"$root/c-plugin-lock.json"
}

mkdir -p "$project_root" "$child_root" "$ignored_root"
write_marketplace "$project_root" alpha
write_marketplace "$child_root" beta
write_lock "$project_root" '"alpha"'
write_lock "$child_root" '"beta"'
printf 'ignored/\n' >"$project_root/.gitignore"
printf '{invalid\n' >"$ignored_root/c-plugin-lock.json"
mkdir -p "$project_root/.agents/skills"
printf 'foreign\n' >"$project_root/.agents/skills/foreign"
cp "$project_root/c-plugin-lock.json" "$test_root/parent-initial.json"
cp "$child_root/c-plugin-lock.json" "$test_root/child-initial.json"
cd "$project_root"

env HOME="$test_home" c-plugin skill sync -r >"$initial_stdout" 2>"$initial_stderr"

[[ ! -s $initial_stderr ]]
[[ $(grep -c '^Synced ' "$initial_stdout") -eq 2 ]]
grep -F "Synced $project_root/c-plugin-lock.json:" "$initial_stdout" >/dev/null
grep -F "Synced $child_root/c-plugin-lock.json:" "$initial_stdout" >/dev/null
! grep -F "$ignored_root/c-plugin-lock.json" "$initial_stdout" >/dev/null
[[ $(realpath "$project_root/.agents/skills/alpha") == "$project_root/marketplace/plugins/demo/skills/alpha" ]]
[[ $(realpath "$child_root/.agents/skills/beta") == "$child_root/marketplace/plugins/demo/skills/beta" ]]
[[ -f $project_root/.agents/c-plugin-state.json ]]
[[ -f $child_root/.agents/c-plugin-state.json ]]
grep -Fx 'foreign' "$project_root/.agents/skills/foreign" >/dev/null
cmp -s "$test_root/parent-initial.json" "$project_root/c-plugin-lock.json"
cmp -s "$test_root/child-initial.json" "$child_root/c-plugin-lock.json"

write_lock "$project_root" ''
cp "$project_root/c-plugin-lock.json" "$test_root/parent-edited.json"
env HOME="$test_home" c-plugin skill sync --recursive >"$edited_stdout" 2>"$edited_stderr"

[[ ! -s $edited_stderr ]]
[[ $(grep -c '^Synced ' "$edited_stdout") -eq 2 ]]
[[ ! -e $project_root/.agents/skills/alpha ]]
[[ -L $child_root/.agents/skills/beta ]]
grep -F '"skill": "beta"' "$child_root/.agents/c-plugin-state.json" >/dev/null
grep -Fx 'foreign' "$project_root/.agents/skills/foreign" >/dev/null
cmp -s "$test_root/parent-edited.json" "$project_root/c-plugin-lock.json"
cmp -s "$test_root/child-initial.json" "$child_root/c-plugin-lock.json"

set +e
env HOME="$test_home" c-plugin skill sync -g -r >"$test_root/invalid.stdout" 2>"$test_root/invalid.stderr"
invalid_status=$?
set -e
[[ $invalid_status -ne 0 ]]
grep -F 'totto2727/c-plugin-v2.SyncError.Planning' "$test_root/invalid.stdout" >/dev/null

printf 'PASS: recursive sync isolates descendant lock ownership\n'
