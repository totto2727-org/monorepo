#!/usr/bin/env bash
set -uo pipefail

MODE="${1:-all}"
ROOT=/tmp/c-plugin-validation
export C_PLUGIN_CACHE_ROOT="$ROOT/cache"
FAILURES=0
RED_FAILURES=0
LAST_RC=0
LAST_OUT=

log_command() { printf '+ '; printf '%q ' "$@"; printf '\n'; }
run() {
  log_command "$@"
  set +e
  LAST_OUT=$("$@" 2>&1)
  LAST_RC=$?
  set -e
  [[ -z "$LAST_OUT" ]] || printf '%s\n' "$LAST_OUT"
  printf '[exit %d]\n' "$LAST_RC"
}
pass() { printf 'PASS: %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; FAILURES=$((FAILURES + 1)); }
red_fail() { printf 'EXPECTED-CURRENT-RED: %s\n' "$*" >&2; RED_FAILURES=$((RED_FAILURES + 1)); }
expect_success() { run "$@"; (( LAST_RC == 0 )) && pass "$*" || fail "$* (exit $LAST_RC)"; }
expect_failure() { run "$@"; (( LAST_RC != 0 )) && pass "rejected safely: $*" || fail "unexpected success: $*"; }
assert_file() { [[ -f "$1" ]] && pass "file exists: $1" || fail "missing file: $1"; }
assert_symlink() { [[ -L "$1" ]] && pass "symlink exists: $1" || fail "missing symlink: $1"; }
assert_absent() { [[ ! -e "$1" && ! -L "$1" ]] && pass "absent: $1" || fail "still exists: $1"; }
assert_same_bytes() { cmp -s "$1" "$2" && pass "bytes preserved: $1" || fail "bytes changed: $1"; }

reset_root() {
  cd /sandbox
  rm -rf "$ROOT" /sandbox/.agents /sandbox/c-plugin-lock.json /sandbox/marketplace
  mkdir -p "$ROOT/remotes/acme" "$ROOT/seed/plugins/demo/skills/alpha" \
    "$ROOT/local/plugins/local/skills/local-skill"
  printf '%s\n' '# Alpha' >"$ROOT/seed/plugins/demo/skills/alpha/SKILL.md"
  printf '%s\n' '# Local' >"$ROOT/local/plugins/local/skills/local-skill/SKILL.md"
  mkdir -p "$ROOT/seed/.claude-plugin" "$ROOT/local/.claude-plugin"
  printf '%s\n' '{"name":"remote-fixture","plugins":[{"name":"demo","description":"fixture","source":"./plugins/demo"}]}' >"$ROOT/seed/.claude-plugin/marketplace.json"
  printf '%s\n' '{"name":"local-fixture","plugins":[{"name":"local","description":"fixture","source":"./plugins/local"}]}' >"$ROOT/local/.claude-plugin/marketplace.json"
  git -C "$ROOT/seed" init -q
  git -C "$ROOT/seed" config user.email fixture@example.invalid
  git -C "$ROOT/seed" config user.name Fixture
  git -C "$ROOT/seed" add .
  git -C "$ROOT/seed" commit -qm initial
  git -C "$ROOT/seed" branch -M main
  git clone -q --bare "$ROOT/seed" "$ROOT/remotes/acme/market.git"
  git config --global url."file://$ROOT/remotes/".insteadOf https://github.com/
}

prepare_local_project() {
  local name=$1
  mkdir -p "$ROOT/$name"
  cp -R "$ROOT/local" "$ROOT/$name/marketplace"
  cd "$ROOT/$name"
  expect_success c-plugin init
}

help_mode() {
  [[ "$(id -u)" != 0 ]] && pass 'running as non-root' || fail 'container runs as root'
  [[ "$HOME" == /sandbox ]] && pass 'HOME=/sandbox' || fail "unexpected HOME=$HOME"
  expect_success c-plugin --help
  expect_success c-plugin --version
  [[ "$(c-plugin --version)" == "0.2.0" ]] && pass 'version is 0.2.0' || fail 'unexpected version output'
  expect_success c-plugin init --help
  expect_success c-plugin skill --help
  expect_success c-plugin skill add --help
  expect_success c-plugin skill sync --help
  expect_success c-plugin skill update --help
  expect_success c-plugin skill remove --help
  expect_success c-plugin skill target --help
  expect_success c-plugin skill target add --help
  expect_success c-plugin skill target remove --help
  expect_success c-plugin dev --help
  expect_success c-plugin dev marketplace --help
  expect_success c-plugin dev marketplace sync --help
  expect_success c-plugin help
}

init_mode() {
  reset_root
  mkdir -p "$ROOT/init/.agents"
  printf 'preserve\n' >"$ROOT/init/.agents/sentinel"
  cd "$ROOT/init"
  expect_success c-plugin init
  assert_file "$ROOT/init/c-plugin-lock.json"
  assert_file "$ROOT/init/.agents/sentinel"
  cp c-plugin-lock.json "$ROOT/original-lock.json"
  expect_failure c-plugin init
  cmp -s c-plugin-lock.json "$ROOT/original-lock.json" && pass 'repeat init preserved lock' || fail 'repeat init clobbered lock'
  expect_success c-plugin init -g
  assert_file /sandbox/c-plugin-lock.json
  cp /sandbox/c-plugin-lock.json "$ROOT/original-global-lock.json"
  expect_failure c-plugin init --global
  cmp -s /sandbox/c-plugin-lock.json "$ROOT/original-global-lock.json" && pass 'repeat global init preserved lock' || fail 'repeat global init clobbered lock'
}

lifecycle_mode() {
  reset_root
  mkdir -p "$ROOT/project/nested/project"
  cp -R "$ROOT/local" "$ROOT/project/marketplace"
  cd "$ROOT/project"
  expect_success c-plugin init
  expect_success c-plugin skill add --local ./marketplace
  assert_symlink .agents/skills/local-skill
  expect_success c-plugin skill sync
  expect_success c-plugin skill add --local ./marketplace
  expect_success c-plugin skill add acme/market
  assert_symlink .agents/skills/alpha
  assert_file "$ROOT/cache/mbt/acme/market/.git/HEAD"
  local pinned_commit
  pinned_commit=$(git -C "$ROOT/cache/mbt/acme/market" rev-parse HEAD)

  git clone -q "$ROOT/remotes/acme/market.git" "$ROOT/publisher"
  git -C "$ROOT/publisher" config user.email fixture@example.invalid
  git -C "$ROOT/publisher" config user.name Fixture
  mkdir -p "$ROOT/publisher/plugins/demo/skills/beta"
  printf '%s\n' '# Beta' >"$ROOT/publisher/plugins/demo/skills/beta/SKILL.md"
  git -C "$ROOT/publisher" add .
  git -C "$ROOT/publisher" commit -qm update
  git -C "$ROOT/publisher" push -q origin main
  rm -rf "$ROOT/cache/mbt/acme/market"
  expect_success c-plugin skill sync
  [[ "$(git -C "$ROOT/cache/mbt/acme/market" rev-parse HEAD)" == "$pinned_commit" ]] && pass 'sync restored lock-pinned commit after cache deletion' || fail 'sync did not restore lock-pinned commit'
  assert_absent .agents/skills/beta
  run c-plugin skill update
  if (( LAST_RC == 0 )); then
    pass 'c-plugin skill update'
    assert_symlink .agents/skills/alpha
    expect_success c-plugin skill add acme/market
    assert_symlink .agents/skills/beta
  else
    red_fail 'skill update could not fast-forward the shallow cache'
  fi

  cd "$ROOT/project/nested/project"
  cp -R "$ROOT/local" ./marketplace
  expect_success c-plugin init
  expect_success c-plugin skill add --local ./marketplace
  cd "$ROOT/project"
  expect_success c-plugin skill sync -r
  run c-plugin skill update --recursive
  (( LAST_RC == 0 )) && pass 'c-plugin skill update --recursive' || red_fail 'recursive skill update could not fast-forward the shallow cache'

  mkdir -p "$ROOT/target"
  expect_success c-plugin skill target add "$ROOT/target"
  expect_success c-plugin skill target add "$ROOT/target"
  assert_symlink "$ROOT/target/alpha"
  expect_success c-plugin skill target remove "$ROOT/target"
  expect_success c-plugin skill target remove "$ROOT/target"
  if [[ ! -e "$ROOT/target/alpha" && ! -L "$ROOT/target/alpha" ]]; then
    pass 'target remove deleted managed links'
  else
    red_fail 'target remove left managed links in removed target'
  fi

  expect_success c-plugin skill remove acme/market
  expect_success c-plugin skill remove acme/market
  assert_absent .agents/skills/alpha
  assert_absent .agents/skills/beta
  expect_success c-plugin skill remove ./marketplace
  expect_success c-plugin skill remove ./marketplace
  assert_absent .agents/skills/local-skill
}

relative_target_mode() {
  reset_root
  prepare_local_project relative-target-project
  expect_success c-plugin skill add --local ./marketplace
  mkdir -p relative-target "$ROOT/unrelated"
  ln -s "$ROOT/unrelated" relative-target/unrelated-link
  expect_success c-plugin skill target add relative-target
  assert_symlink relative-target/local-skill
  mkdir -p nested/deeper; cd nested/deeper
  expect_success c-plugin skill sync
  assert_symlink "$ROOT/relative-target-project/relative-target/local-skill"
  assert_symlink "$ROOT/relative-target-project/relative-target/unrelated-link"
  expect_success c-plugin skill target remove relative-target
  assert_absent "$ROOT/relative-target-project/relative-target/local-skill"
  assert_symlink "$ROOT/relative-target-project/relative-target/unrelated-link"
}

unavailable_source_mode() {
  reset_root
  mkdir -p "$ROOT/remove-project/market-a" "$ROOT/remove-project/market-b/plugins/b/skills/b-skill" \
    "$ROOT/remove-project/market-b/.claude-plugin"
  cp -R "$ROOT/local/." "$ROOT/remove-project/market-a/"
  printf '%s\n' '# B' >"$ROOT/remove-project/market-b/plugins/b/skills/b-skill/SKILL.md"
  printf '%s\n' '{"name":"b-fixture","plugins":[{"name":"b","description":"fixture","source":"./plugins/b"}]}' >"$ROOT/remove-project/market-b/.claude-plugin/marketplace.json"
  cd "$ROOT/remove-project"
  expect_success c-plugin init
  expect_success c-plugin skill add --local ./market-a
  expect_success c-plugin skill add --local ./market-b
  assert_symlink .agents/skills/local-skill
  assert_symlink .agents/skills/b-skill
  mv market-b "$ROOT/unavailable-market-b"
  expect_success c-plugin skill remove ./market-a
  assert_absent .agents/skills/local-skill
  assert_symlink .agents/skills/b-skill
}

malformed_lock_case() {
  local name=$1 content=$2
  mkdir -p "$ROOT/$name"; cd "$ROOT/$name"
  printf '%s\n' "$content" >c-plugin-lock.json
  cp c-plugin-lock.json lock-before.json
  expect_failure c-plugin skill sync
  assert_same_bytes c-plugin-lock.json lock-before.json
}

cache_safety_mode() {
  reset_root
  mkdir -p "$ROOT/cache-origin"; cd "$ROOT/cache-origin"
  expect_success c-plugin init
  expect_success c-plugin skill add acme/market
  printf 'sentinel\n' >"$ROOT/cache/mbt/acme/market/sentinel"
  git -C "$ROOT/cache/mbt/acme/market" remote set-url origin file:///unexpected
  expect_success c-plugin skill sync
  [[ "$LAST_OUT" == *'Skipped acme/market:'* && "$LAST_OUT" == *'Repository cache origin mismatch:'* ]] && pass 'origin mismatch reported as skipped' || fail 'origin mismatch skip was not reported'
  assert_symlink .agents/skills/alpha
  assert_file "$ROOT/cache/mbt/acme/market/sentinel"

  rm -rf "$ROOT/cache"
  mkdir -p "$ROOT/cache-victim"
  printf 'victim\n' >"$ROOT/cache-victim/sentinel"
  ln -s "$ROOT/cache-victim" "$ROOT/cache"
  expect_success c-plugin skill sync
  [[ "$LAST_OUT" == *'Skipped acme/market:'* && "$LAST_OUT" == *'Refusing symlinked repository cache path:'* ]] && pass 'symlinked cache reported as skipped' || fail 'symlinked cache skip was not reported'
  assert_symlink .agents/skills/alpha
  [[ "$(cat "$ROOT/cache-victim/sentinel")" == victim ]] && pass 'symlinked cache parent victim preserved' || fail 'symlinked cache parent victim changed'
}

global_mode() {
  reset_root
  prepare_local_project global-project
  expect_success c-plugin skill add --local ./marketplace
  expect_success c-plugin init --global
  expect_success c-plugin skill add -g acme/market
  assert_symlink .agents/skills/local-skill
  assert_absent .agents/skills/alpha
  assert_symlink /sandbox/.agents/skills/alpha
  assert_absent /sandbox/.agents/skills/local-skill
  cp -R "$ROOT/local" /sandbox/marketplace
  expect_success c-plugin skill add --global --local ./marketplace
  assert_symlink /sandbox/.agents/skills/local-skill
  mkdir -p "$ROOT/global-other"; cd "$ROOT/global-other"
  expect_success c-plugin skill sync --global
  expect_success c-plugin skill update -g
  mkdir -p "$ROOT/global-target"
  expect_success c-plugin skill target add --global "$ROOT/global-target"
  assert_symlink "$ROOT/global-target/alpha"
  expect_success c-plugin skill target remove -g "$ROOT/global-target"
  if [[ ! -e "$ROOT/global-target/alpha" && ! -L "$ROOT/global-target/alpha" ]]; then
    pass 'global target remove deleted managed links'
  else
    red_fail 'global target remove left managed links in removed target'
  fi
  expect_success c-plugin skill remove --global acme/market
  assert_absent /sandbox/.agents/skills/alpha
  expect_success c-plugin skill remove -g ./marketplace
  assert_absent /sandbox/.agents/skills/local-skill
}

make_dev_fixture() {
  local kind=$1 dir="$ROOT/dev-$1" config marketplace
  case "$kind" in
    claude) config=.claude-plugin; marketplace=.claude-plugin/marketplace.json ;;
    cursor) config=.cursor-plugin; marketplace=.cursor-plugin/marketplace.json ;;
    codex) config=.codex-plugin; marketplace=.agents/plugins/marketplace.json ;;
  esac
  mkdir -p "$dir/$config" "$dir/plugins/demo/$config" "$dir/plugins/demo/skills/alpha" "$(dirname "$dir/$marketplace")"
  printf '%s\n' '{"name":"demo","description":"fixture","version":"1.0.0"}' >"$dir/plugins/demo/$config/plugin.json"
  printf '%s\n' '# Alpha' >"$dir/plugins/demo/skills/alpha/SKILL.md"
  if [[ "$kind" == codex ]]; then
    printf '%s\n' '{"name":"dev-fixture","plugins":[{"name":"demo","category":"Productivity","source":{"source":"local","path":"./plugins/demo"},"policy":{"authentication":"ON_INSTALL","installation":"INSTALLED_BY_DEFAULT"}}]}' >"$dir/$marketplace"
  else
    printf '%s\n' '{"name":"dev-fixture","plugins":[{"name":"demo","description":"fixture","source":"./plugins/demo"}]}' >"$dir/$marketplace"
  fi
}

dev_mode() {
  reset_root
  for kind in claude cursor codex; do
    make_dev_fixture "$kind"; cd "$ROOT/dev-$kind"
    expect_success c-plugin dev marketplace sync "$kind"
    assert_file .claude-plugin/marketplace.json
    assert_file .cursor-plugin/marketplace.json
    assert_file .agents/plugins/marketplace.json
    assert_file plugins/demo/.claude-plugin/plugin.json
    assert_file plugins/demo/.cursor-plugin/plugin.json
    assert_file plugins/demo/.codex-plugin/plugin.json
  done
}

collision_case() {
  local kind=$1 project="edge-collision-$1" target
  prepare_local_project "$project"
  target="$ROOT/$project/target"
  mkdir -p "$target"
  expect_success c-plugin skill target add "$target"
  cp c-plugin-lock.json lock-before.json
  case "$kind" in
    file) printf 'preserve-file\n' >"$target/local-skill" ;;
    dir) mkdir "$target/local-skill"; printf 'preserve-dir\n' >"$target/local-skill/sentinel" ;;
    symlink) ln -s "$ROOT/$project/stale-target" "$target/local-skill" ;;
  esac
  run c-plugin skill add --local ./marketplace
  if [[ "$kind" == symlink ]]; then
    (( LAST_RC == 0 )) && pass 'existing symlink refreshed' || fail 'existing symlink was not refreshed'
    assert_symlink "$target/local-skill"
  else
    (( LAST_RC != 0 )) && pass "existing $kind collision rejected" || fail "existing $kind collision unexpectedly succeeded"
    assert_same_bytes c-plugin-lock.json lock-before.json
    if [[ "$kind" == file ]]; then
      [[ "$(cat "$target/local-skill")" == preserve-file ]] && pass 'existing file preserved' || fail 'existing file changed'
    else
      [[ "$(cat "$target/local-skill/sentinel")" == preserve-dir ]] && pass 'existing directory preserved' || fail 'existing directory changed'
    fi
  fi
}

edge_mode() {
  reset_root
  mkdir -p "$ROOT/edge/no-lock"
  cd "$ROOT/edge/no-lock"
  expect_failure c-plugin skill sync
  mkdir -p "$ROOT/edge/outside" "$ROOT/edge/project"
  cp -R "$ROOT/local" "$ROOT/edge/project/marketplace"
  cp -R "$ROOT/local" "$ROOT/edge/outside/marketplace"
  cd "$ROOT/edge/project"; expect_success c-plugin init

  run c-plugin skill add --local ./../outside/marketplace
  (( LAST_RC != 0 )) && pass 'parent traversal rejected' || red_fail '--local parent traversal accepted'
  run c-plugin skill add acme/market --local ./marketplace
  (( LAST_RC != 0 )) && pass 'repo plus --local rejected' || red_fail 'repo and --local accepted together'
  expect_failure c-plugin skill add invalid
  expect_failure c-plugin skill add missing/repo
  expect_failure c-plugin skill add --local .
  expect_failure c-plugin skill add --local /tmp
  expect_failure c-plugin skill add --local ./missing
  expect_failure c-plugin skill add
  expect_failure c-plugin skill remove
  expect_failure c-plugin skill target add
  expect_failure c-plugin skill target remove
  expect_failure c-plugin dev marketplace sync invalid

  collision_case file
  collision_case dir
  collision_case symlink

  prepare_local_project edge-corrupt
  printf '%s\n' '{not-json' >c-plugin-lock.json
  cp c-plugin-lock.json corrupt-before.json
  run c-plugin skill sync
  if (( LAST_RC != 0 )) && cmp -s c-plugin-lock.json corrupt-before.json; then
    pass 'corrupt lock rejected and preserved'
  else
    red_fail 'corrupt lock was accepted or changed'
  fi

  malformed_lock_case edge-malformed-skill-dirs '{"version":1,"skillDirs":["target",1],"repositories":[]}'
  malformed_lock_case edge-malformed-repositories '{"version":1,"skillDirs":[],"repositories":[42]}'
  malformed_lock_case edge-malformed-enabled-skills '{"version":1,"skillDirs":[],"repositories":[{"source":"./repo","plugins":[{"name":"plugin-a","enabledSkills":["skill-a",1]}]}]}'
  malformed_lock_case edge-unsafe-enabled-skill '{"version":1,"skillDirs":[],"repositories":[{"source":"./repo","plugins":[{"name":"plugin-a","enabledSkills":["../../victim"]}]}]}'
  relative_target_mode
  unavailable_source_mode
  cache_safety_mode
}

set -e
case "$MODE" in
  help) help_mode ;;
  init) init_mode ;;
  lifecycle) lifecycle_mode ;;
  global) global_mode ;;
  dev) dev_mode ;;
  edge) edge_mode ;;
  all) help_mode; init_mode; lifecycle_mode; global_mode; dev_mode; edge_mode ;;
  *) printf 'usage: %s {help|init|lifecycle|global|dev|edge|all}\n' "$0" >&2; exit 64 ;;
esac
printf 'SUMMARY: mode=%s failures=%d expected-current-red=%d\n' "$MODE" "$FAILURES" "$RED_FAILURES"
(( FAILURES == 0 && RED_FAILURES == 0 ))
