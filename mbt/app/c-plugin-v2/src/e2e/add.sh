#!/usr/bin/env bash
set -euo pipefail
test_root=/tmp/c-plugin-v2-add-e2e
home=$test_root/home
project=$home/project
repository=$project/marketplace
plugin=$repository/plugins/demo
lock=$project/c-plugin-lock.json
state=$project/.agents/c-plugin-state.json
stdout=$test_root/add.stdout
repeat_stdout=$test_root/repeat.stdout
force_stdout=$test_root/force.stdout
foreign=$project/.agents/skills/alpha

mkdir -p "$repository/.claude-plugin" "$plugin/skills/alpha" "$plugin/skills/beta"
printf '%s\n' '{"name":"fixture","plugins":[{"name":"demo","source":"plugins/demo"}]}' >"$repository/.claude-plugin/marketplace.json"
printf '# alpha\n' >"$plugin/skills/alpha/SKILL.md"
printf '# beta\n' >"$plugin/skills/beta/SKILL.md"
cd "$project"
env HOME="$home" c-plugin init >/dev/null
mkdir -p "$(dirname -- "$foreign")"
printf 'foreign\n' >"$foreign"
mkdir nested
cd nested
env HOME="$home" c-plugin skill add \
  --local ./marketplace \
  --kind claude \
  --skill demo/alpha \
  --skill demo/beta >"$stdout"
grep -Fx "Added $repository to $lock: partial (2 notices, 0 unavailable repositories)" "$stdout" >/dev/null
compact_lock=$(tr -d '[:space:]' <"$lock")
[[ $compact_lock == '{"version":"2","targets":[],"repositories":[{"type":"local","path":"marketplace","marketplaceKind":"claude","plugins":[{"name":"demo","path":"plugins/demo","enabledSkills":["alpha","beta"]}]}]}' ]]
link=$project/.agents/skills/beta
[[ -L $link ]]
[[ $(realpath "$link") == "$plugin/skills/beta" ]]
[[ -f $foreign && ! -L $foreign ]]
grep -Fx 'foreign' "$foreign" >/dev/null
grep -F '"skill": "beta"' "$state" >/dev/null
! grep -F '"skill": "alpha"' "$state" >/dev/null
cp "$lock" "$test_root/before-repeat.json"
set +e
env HOME="$home" c-plugin skill add \
  --local ./marketplace \
  --kind claude \
  --skill demo/alpha \
  --skill demo/beta >"$repeat_stdout" 2>/dev/null
repeat_status=$?
set -e
[[ $repeat_status -ne 0 ]]
grep -F 'totto2727/c-plugin-v2.AddLocalError.InvalidInput' "$repeat_stdout" >/dev/null
cmp -s "$test_root/before-repeat.json" "$lock"
[[ -L $link ]]
grep -F '"skill": "beta"' "$state" >/dev/null

env HOME="$home" c-plugin skill remove \
  --skill marketplace/demo/alpha \
  --skill marketplace/demo/beta >/dev/null
[[ -f $foreign && ! -L $foreign ]]
[[ ! -e $link ]]
mkdir "$link"
printf 'directory-content\n' >"$link/keep"
neighbor=$project/.agents/skills/neighbor
printf 'neighbor\n' >"$neighbor"
env HOME="$home" c-plugin skill add \
  --local ./marketplace \
  --kind claude \
  --skill demo/alpha \
  --skill demo/beta \
  --force >"$force_stdout"
grep -Fx "Added $repository to $lock: partial (1 notices, 0 unavailable repositories)" "$force_stdout" >/dev/null
[[ -L $foreign ]]
[[ $(realpath "$foreign") == "$plugin/skills/alpha" ]]
[[ -d $link && ! -L $link ]]
grep -Fx 'directory-content' "$link/keep" >/dev/null
grep -Fx 'neighbor' "$neighbor" >/dev/null
grep -F '"skill": "alpha"' "$state" >/dev/null
! grep -F '"skill": "beta"' "$state" >/dev/null

printf 'PASS: add local marketplace, repeat protection, and forced collision replacement\n'
