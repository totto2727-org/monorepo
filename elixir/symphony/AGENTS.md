<!--
このファイルは元のApache 2.0ライセンスのコードから変更されています
変更日: 2026-06-28
変更者: totto2727
変更内容: monorepo 配置に合わせて移設した docs 配下の資料へのリンクと OpenCode バックエンド前提の説明に修正
-->

# Symphony

This directory contains the Elixir agent orchestration service that polls Linear, creates per-issue workspaces, and runs OpenCode through the in-repo `opencode_client`.

## Environment

- Elixir: `1.19.x` (OTP 28) via `mise`.
- Install deps: `mix setup`.
- Main quality gate: `make all` (format check, lint, coverage, dialyzer).

## Codebase-Specific Conventions

- Runtime config is loaded from the repository root `WORKFLOW.md` front matter via `Symphony.Workflow` and `Symphony.Config`.
- Keep the implementation aligned with [`docs/SPEC.md`](docs/SPEC.md) where practical.
  - The implementation may be a superset of the spec.
  - The implementation must not conflict with the spec.
  - If implementation changes meaningfully alter the intended behavior, update the spec in the same
    change where practical so the spec stays current.
- Prefer adding config access through `Symphony.Config` instead of ad-hoc env reads.
- Workspace safety is critical:
  - Never run agent turns in the source repo.
  - Workspaces must stay under configured workspace root.
- Orchestrator behavior is stateful and concurrency-sensitive; preserve retry, reconciliation, and cleanup semantics.
- Follow `docs/logging.md` for logging conventions and required issue/session context fields.

## Tests and Validation

Run targeted tests while iterating, then run full gates before handoff.

```bash
make all
```

## Required Rules

- Public functions (`def`) in `lib/` must have an adjacent `@spec`.
- `defp` specs are optional.
- `@impl` callback implementations are exempt from local `@spec` requirement.
- Keep changes narrowly scoped; avoid unrelated refactors.
- Follow existing module/style patterns in `lib/symphony/*`.

Validation command:

```bash
mix specs.check
```

## PR Requirements

- PR body must follow `docs/pull_request_template.md` exactly.
- Validate PR body locally when needed:

```bash
mix pr_body.check --file /path/to/pr_body.md
```

## Docs Update Policy

If behavior/config changes, update docs in the same PR:

- `docs/original-README.md` for original project concept and goals.
- `README.md` for Elixir implementation and run instructions.
- `../../WORKFLOW.md` for workflow/config contract changes.
