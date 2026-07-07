#!/usr/bin/env bash
# このファイルは元のApache 2.0ライセンスのコードから新規に追加されています
# 変更日: 2026-07-07
# 変更者: totto2727
# 変更内容: upstream OpenAI Symphony とローカル Symphony の変更ファイル Markdown レポート script を追加

set -euo pipefail

upstream="${SYMPHONY_UPSTREAM_REPO:-https://github.com/openai/symphony.git}"
local_repo="$(pwd)"
ref="main"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --upstream)
      upstream="$2"
      shift 2
      ;;
    --local-repo)
      local_repo="$2"
      shift 2
      ;;
    --ref)
      ref="$2"
      shift 2
      ;;
    --help | -h)
      cat <<'USAGE'
Usage: changed-files-report.sh [--upstream PATH_OR_URL] [--local-repo PATH] [--ref REF]

Print a Markdown report comparing upstream OpenAI Symphony's elixir/ tree with
this repository's elixir/symphony tree. Generated directories such as _build,
deps, and node_modules are ignored.
USAGE
      exit 0
      ;;
    *)
      printf 'unknown option: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

temp_root="$(mktemp -d "${TMPDIR:-/tmp}/symphony-changed-files.XXXXXXXXXX")"
trap 'rm -rf "$temp_root"' EXIT

if [[ "$upstream" =~ ^(https?://|git@) ]]; then
  upstream_repo="$temp_root/upstream-repo"
  git clone --depth 1 --branch "$ref" "$upstream" "$upstream_repo" >/dev/null 2>&1
else
  upstream_repo="$upstream"
fi

if [[ -d "$upstream_repo/elixir" ]]; then
  upstream_elixir="$upstream_repo/elixir"
elif [[ -d "$upstream_repo" ]]; then
  upstream_elixir="$upstream_repo"
else
  printf 'could not find upstream directory: %s\n' "$upstream_repo" >&2
  exit 1
fi

if [[ -d "$local_repo/elixir/symphony" ]]; then
  local_symphony="$local_repo/elixir/symphony"
elif [[ -d "$local_repo" ]]; then
  local_symphony="$local_repo"
else
  printf 'could not find local Symphony directory: %s\n' "$local_repo" >&2
  exit 1
fi

snapshot_root="$temp_root/snapshots"
upstream_snapshot="$snapshot_root/upstream-elixir"
local_snapshot="$snapshot_root/local-symphony"
mkdir -p "$snapshot_root"
rsync -a --exclude .git --exclude _build --exclude deps --exclude node_modules "$upstream_elixir/" "$upstream_snapshot/"
rsync -a --exclude .git --exclude _build --exclude deps --exclude node_modules "$local_symphony/" "$local_snapshot/"

name_status="$(git diff --no-index --find-renames --find-copies --name-status "$upstream_snapshot" "$local_snapshot" || true)"
diff_output="$(git diff --no-index --find-renames --find-copies "$upstream_snapshot" "$local_snapshot" || true)"

normalize_paths() {
  perl \
    -pe "s|\Q$upstream_snapshot\E|upstream/elixir|g; s|\Q$local_snapshot\E|elixir/symphony|g; s|aupstream/|a/upstream/|g; s|aelixir/|a/elixir/|g; s|belixir/|b/elixir/|g"
}

printf '# Symphony Changed Files Report\n\n'
printf 'Upstream: `%s`\n' "$upstream"
printf 'Upstream ref: `%s`\n' "$ref"
printf 'Local repository: `%s`\n\n' "$local_repo"
printf 'Compared paths:\n'
printf -- '- Upstream: `elixir/`\n'
printf -- '- Local: `elixir/symphony/`\n\n'
printf 'Ignored directories: `_build`, `deps`, `node_modules`, `.git`\n\n'
printf '## Changed Files\n\n'

if [[ -z "$name_status" ]]; then
  printf 'No Symphony files changed.\n'
else
  printf '| Status | Path | New Path |\n| --- | --- | --- |\n'
  printf '%s\n' "$name_status" | normalize_paths | while IFS=$'\t' read -r status path new_path; do
    printf '| `%s` | `%s` | `%s` |\n' "$status" "$path" "${new_path:-}"
  done
fi

cat <<'MARKDOWN'

## Diff

MARKDOWN

if [[ -z "$diff_output" ]]; then
  printf 'No diff.\n'
else
  printf '```diff\n'
  printf '%s\n' "$diff_output" | normalize_paths
  printf '```\n'
fi
